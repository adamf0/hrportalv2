package main

import (
	"bytes"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"hrportal_backend/modules/notification/domain"
)

const (
	FcmProjectId = "hrportal-71e0a"
)

// Circuit Breaker State definitions
type CircuitState string

const (
	StateClosed   CircuitState = "CLOSED"
	StateOpen     CircuitState = "OPEN"
	StateHalfOpen CircuitState = "HALF_OPEN"
)

type FcmCircuitBreaker struct {
	mu              sync.RWMutex
	state           CircuitState
	failureCount    int
	threshold       int
	resetTimeout    time.Duration
	lastStateChange time.Time
}

func NewFcmCircuitBreaker() *FcmCircuitBreaker {
	return &FcmCircuitBreaker{
		state:           StateClosed,
		threshold:       5,
		resetTimeout:    30 * time.Second,
		lastStateChange: time.Now(),
	}
}

func (cb *FcmCircuitBreaker) AllowExecution() bool {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	now := time.Now()
	if cb.state == StateOpen {
		if now.Sub(cb.lastStateChange) >= cb.resetTimeout {
			cb.state = StateHalfOpen
			cb.lastStateChange = now
			log.Printf("[FCM Circuit Breaker] Transitioning to HALF_OPEN state for trial recovery...")
			return true
		}
		return false
	}
	return true
}

func (cb *FcmCircuitBreaker) RecordResult(err error) {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	now := time.Now()
	if err == nil {
		if cb.state == StateHalfOpen || cb.failureCount > 0 {
			log.Printf("[FCM Circuit Breaker] Push Succeeded! Resetting state to CLOSED.")
		}
		cb.failureCount = 0
		cb.state = StateClosed
	} else {
		cb.failureCount++
		log.Printf("[FCM Circuit Breaker] Push Failure Recorded (%d/%d): %v", cb.failureCount, cb.threshold, err)
		if cb.failureCount >= cb.threshold && cb.state != StateOpen {
			cb.state = StateOpen
			cb.lastStateChange = now
			log.Printf("[FCM Circuit Breaker] TRIP! Threshold exceeded (%d consecutive failures). Circuit Breaker is now OPEN.", cb.failureCount)
		}
	}
}

type ServiceAccount struct {
	Type                    string `json:"type"`
	ProjectId               string `json:"project_id"`
	PrivateKeyId            string `json:"private_key_id"`
	PrivateKey              string `json:"private_key"`
	ClientEmail             string `json:"client_email"`
	ClientId                string `json:"client_id"`
	AuthUri                 string `json:"auth_uri"`
	TokenUri                string `json:"token_uri"`
	AuthProviderX509CertUrl string `json:"auth_provider_x509_cert_url"`
	ClientX509CertUrl       string `json:"client_x509_cert_url"`
}

type NotificationWorker struct {
	db             *gorm.DB
	circuitBreaker *FcmCircuitBreaker
	serviceAccount *ServiceAccount
	cachedToken    string
	tokenExpiry    time.Time
	tokenCache     map[string]string
	mu             sync.RWMutex
}

func NewNotificationWorker(db *gorm.DB) *NotificationWorker {
	worker := &NotificationWorker{
		db:             db,
		circuitBreaker: NewFcmCircuitBreaker(),
		tokenCache:     make(map[string]string),
	}
	_ = worker.LoadServiceAccount("./firebase-service-account.json")
	return worker
}

func (w *NotificationWorker) LoadServiceAccount(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		log.Printf("[FCM Worker] Service Account JSON not found at %s: %v", filePath, err)
		return err
	}
	var sa ServiceAccount
	if err := json.Unmarshal(data, &sa); err != nil {
		log.Printf("[FCM Worker] Failed to parse Service Account JSON: %v", err)
		return err
	}
	w.serviceAccount = &sa
	log.Printf("[FCM Worker] Successfully loaded Firebase Service Account: %s (%s)", sa.ClientEmail, sa.ProjectId)
	return nil
}

func (w *NotificationWorker) GetFcmToken(nip string) string {
	nip = strings.TrimSpace(nip)
	if nip == "" {
		return ""
	}

	w.mu.RLock()
	token, ok := w.tokenCache[nip]
	w.mu.RUnlock()

	if ok && token != "" {
		return token
	}

	if w.db != nil {
		var tokenModel domain.FcmTokenModel
		if err := w.db.Where("nip = ? OR nidn = ?", nip, nip).Order("updated_at desc").First(&tokenModel).Error; err == nil && tokenModel.FcmToken != "" {
			w.mu.Lock()
			w.tokenCache[nip] = tokenModel.FcmToken
			w.mu.Unlock()
			return tokenModel.FcmToken
		}
	}
	return ""
}

func (w *NotificationWorker) ProcessPendingNotifications() {
	if w.db == nil {
		return
	}

	var pendingNotifs []domain.NotificationModel
	err := w.db.Where("status = ? OR (status = ? AND retry_count < ?)", "pending", "failed", 3).
		Order("created_at asc").
		Limit(50).
		Find(&pendingNotifs).Error

	if err != nil || len(pendingNotifs) == 0 {
		return
	}

	log.Printf("[FCM Worker] Found %d pending/retry notification(s) in DB...", len(pendingNotifs))

	for _, notif := range pendingNotifs {
		if !w.circuitBreaker.AllowExecution() {
			log.Printf("[FCM Worker Warning] Circuit Breaker is OPEN. Skipping FCM push for Notification ID %d (NIP: %s).", notif.ID, notif.TargetNip)
			w.db.Model(&notif).Updates(map[string]interface{}{
				"status":        "circuit_broken",
				"error_message": "FCM Circuit Breaker is OPEN",
				"updated_at":    time.Now(),
			})
			continue
		}

		target := notif.TargetNip
		if target == "" {
			target = notif.TargetNidn
		}

		token := w.GetFcmToken(target)
		if token == "" {
			log.Printf("[FCM Worker Warning] Target NIP/NIDN '%s' has no active FCM token in DB. Notification ID %d marked as 'no_token'.", target, notif.ID)
			w.db.Model(&notif).Updates(map[string]interface{}{
				"status":        "no_token",
				"error_message": fmt.Sprintf("Target NIP/NIDN '%s' has no registered FCM token in user_fcm_tokens table", target),
				"updated_at":    time.Now(),
			})
			continue
		}

		var payload map[string]string
		if notif.PayloadJSON != "" {
			_ = json.Unmarshal([]byte(notif.PayloadJSON), &payload)
		}

		pushErr := w.sendFcmHttpV1Push(token, notif.Title, notif.Body, payload)

		isClientTokenError := pushErr != nil && (strings.Contains(pushErr.Error(), "INVALID_ARGUMENT") ||
			strings.Contains(pushErr.Error(), "not a valid FCM registration token") ||
			strings.Contains(pushErr.Error(), "UNREGISTERED") ||
			strings.Contains(pushErr.Error(), "NOT_FOUND") ||
			strings.Contains(pushErr.Error(), "400"))

		if !isClientTokenError {
			w.circuitBreaker.RecordResult(pushErr)
		}

		if pushErr == nil {
			w.db.Model(&notif).Updates(map[string]interface{}{
				"status":     "done",
				"updated_at": time.Now(),
			})
			log.Printf("[FCM Worker] Notification ID %d pushed successfully to NIP/NIDN %s! Status set to 'done'.", notif.ID, target)
		} else if isClientTokenError {
			// Clear bad mock/stale token from database so it won't be retried repeatedly
			w.db.Where("fcm_token = ?", token).Delete(&domain.FcmTokenModel{})
			w.mu.Lock()
			delete(w.tokenCache, target)
			w.mu.Unlock()

			tokenSnippet := token
			if len(tokenSnippet) > 15 {
				tokenSnippet = tokenSnippet[:15]
			}

			w.db.Model(&notif).Updates(map[string]interface{}{
				"status":        "invalid_token",
				"error_message": fmt.Sprintf("Invalid FCM Registration Token '%s...': Google FCM API rejected token", tokenSnippet),
				"retry_count":   3,
				"updated_at":    time.Now(),
			})
			log.Printf("[FCM Worker Warning] Notification ID %d has invalid FCM token '%s...'. Cleared token from DB and marked status as 'invalid_token'.", notif.ID, tokenSnippet)
		} else {
			w.db.Model(&notif).Updates(map[string]interface{}{
				"status":        "failed",
				"error_message": pushErr.Error(),
				"retry_count":   gorm.Expr("retry_count + 1"),
				"updated_at":    time.Now(),
			})
			log.Printf("[FCM Worker Error] Push failed for Notification ID %d: %v. Retry count incremented.", notif.ID, pushErr)
		}
	}
}

func (w *NotificationWorker) getGoogleAccessToken() (string, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.cachedToken != "" && time.Now().Before(w.tokenExpiry) {
		return w.cachedToken, nil
	}

	if w.serviceAccount == nil {
		return "", errors.New("service account credentials not loaded")
	}

	block, _ := pem.Decode([]byte(w.serviceAccount.PrivateKey))
	if block == nil {
		return "", errors.New("failed to decode PEM block containing private key")
	}

	privKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return "", fmt.Errorf("failed to parse PKCS8 private key: %v", err)
	}

	rsaKey, ok := privKey.(*rsa.PrivateKey)
	if !ok {
		return "", errors.New("private key is not RSA")
	}

	now := time.Now()
	claims := jwt.MapClaims{
		"iss":   w.serviceAccount.ClientEmail,
		"sub":   w.serviceAccount.ClientEmail,
		"aud":   w.serviceAccount.TokenUri,
		"iat":   now.Unix(),
		"exp":   now.Add(1 * time.Hour).Unix(),
		"scope": "https://www.googleapis.com/auth/firebase.messaging",
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	signedToken, err := token.SignedString(rsaKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign JWT assertion token: %v", err)
	}

	resp, err := http.PostForm(w.serviceAccount.TokenUri, map[string][]string{
		"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"},
		"assertion":  {signedToken},
	})
	if err != nil {
		return "", fmt.Errorf("failed to request OAuth2 token: %v", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("OAuth2 token request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	var tokenResp struct {
		AccessToken string `json:"access_token"`
		TokenType   string `json:"token_type"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err := json.Unmarshal(respBody, &tokenResp); err != nil {
		return "", fmt.Errorf("failed to parse OAuth2 token response: %v", err)
	}

	if tokenResp.AccessToken == "" {
		return "", fmt.Errorf("empty access token in response: %s", string(respBody))
	}

	w.cachedToken = tokenResp.AccessToken
	w.tokenExpiry = now.Add(time.Duration(tokenResp.ExpiresIn-60) * time.Second)
	log.Printf("[FCM Worker] Generated new Google OAuth2 Access Token")
	return w.cachedToken, nil
}

func (w *NotificationWorker) sendFcmHttpV1Push(fcmToken string, title string, body string, payload map[string]string) error {
	accessToken, err := w.getGoogleAccessToken()
	if err != nil {
		return fmt.Errorf("could not get OAuth2 token: %v", err)
	}

	fcmUrl := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", FcmProjectId)

	fcmReqBody := map[string]interface{}{
		"message": map[string]interface{}{
			"token": fcmToken,
			"notification": map[string]string{
				"title": title,
				"body":  body,
			},
			"data": payload,
			"android": map[string]interface{}{
				"priority": "HIGH",
				"notification": map[string]string{
					"sound": "default",
				},
			},
			"apns": map[string]interface{}{
				"headers": map[string]string{
					"apns-priority": "10",
				},
				"payload": map[string]interface{}{
					"aps": map[string]interface{}{
						"alert": map[string]string{
							"title": title,
							"body":  body,
						},
						"sound":             "default",
						"badge":             1,
						"content-available": 1,
					},
				},
			},
		},
	}

	jsonBytes, err := json.Marshal(fcmReqBody)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", fcmUrl, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+accessToken)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("FCM HTTP v1 Push network error: %v", err)
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return fmt.Errorf("FCM API status %d: %s", resp.StatusCode, string(respBytes))
	}
	log.Printf("[FCM Worker Push] SUCCESS for token (%s...) | Status: 200", fcmToken[:min(len(fcmToken), 10)])
	return nil
}

func main() {
	log.Println("[FCM Notification Worker] Starting standalone background worker daemon (NO HTTP API listener)...")

	dsn := os.Getenv("DB_HRPORTAL")
	if dsn == "" {
		dsn = "root:@tcp(127.0.0.1:3306)/unpak_hrportal?charset=utf8mb4&parseTime=True&loc=Local"
	}

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("[FCM Notification Worker] Failed to connect to HRPortal database: %v", err)
	}

	sqlDB, _ := db.DB()
	sqlDB.SetMaxOpenConns(20)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(10 * time.Minute)

	_ = db.AutoMigrate(&domain.NotificationModel{}, &domain.FcmTokenModel{})
	log.Println("[FCM Notification Worker] AutoMigrated `notifications` and `user_fcm_tokens` tables.")

	worker := NewNotificationWorker(db)

	ticker := time.NewTicker(3 * time.Second)
	stopWorker := make(chan bool)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Println("[FCM Notification Worker] Background polling loop active (3s ticker with Circuit Breaker protection)...")
		for {
			select {
			case <-ticker.C:
				worker.ProcessPendingNotifications()
			case <-stopWorker:
				ticker.Stop()
				log.Println("[FCM Notification Worker] Worker loop stopped.")
				return
			}
		}
	}()

	sig := <-sigChan
	log.Printf("[FCM Notification Worker] Shutdown signal received (%v). Exiting gracefully...", sig)
	stopWorker <- true
	log.Println("[FCM Notification Worker] Daemon stopped cleanly.")
}
