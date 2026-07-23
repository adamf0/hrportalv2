package helper

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
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

const (
	FcmProjectId = "hrportal-71e0a"
	VapidKey     = "BFaK6w-3VQxC6gJsmW9i782akeR5tAuAIM068_-P0Ha6Luu5zKJd5DND3xpjegvYvdDJaaygsBlj4FEdXo2IFdk"
)

// NotificationModel represents DB table `notifications` for auditing and controlled push status
type NotificationModel struct {
	ID             uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	NotificationID string    `gorm:"column:notification_id;uniqueIndex" json:"notification_id"`
	TargetNip      string    `gorm:"column:target_nip;index" json:"target_nip"`
	Title          string    `gorm:"column:title" json:"title"`
	Body           string    `gorm:"column:body" json:"body"`
	Type           string    `gorm:"column:type" json:"type"`
	Status         string    `gorm:"column:status;index" json:"status"` // "pending", "sent", "failed", "circuit_broken"
	RetryCount     int       `gorm:"column:retry_count;default:0" json:"retry_count"`
	ErrorMessage   string    `gorm:"column:error_message" json:"error_message"`
	PayloadJSON    string    `gorm:"column:payload_json;type:text" json:"payload_json"`
	CreatedAt      time.Time `gorm:"column:created_at;index" json:"created_at"`
	UpdatedAt      time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (NotificationModel) TableName() string {
	return "notifications"
}

// NotificationItem represents in-memory stored notification entry for client API
type NotificationItem struct {
	ID        string            `json:"id"`
	TargetNip string            `json:"target_nip"`
	Title     string            `json:"title"`
	Body      string            `json:"body"`
	Type      string            `json:"type"` // "cuti", "izin", "sppd", "attendance"
	Status    string            `json:"status"`
	CreatedAt string            `json:"created_at"`
	Payload   map[string]string `json:"payload,omitempty"`
}

// Circuit Breaker State definitions
type CircuitState string

const (
	StateClosed   CircuitState = "CLOSED"    // Normal operation
	StateOpen     CircuitState = "OPEN"      // Failing, trip breaker to protect server
	StateHalfOpen CircuitState = "HALF_OPEN" // Trial recovery mode
)

// FcmCircuitBreaker implements stateful circuit breaker for FCM push notifications
type FcmCircuitBreaker struct {
	mu              sync.RWMutex
	state           CircuitState
	failureCount    int
	threshold       int           // Max failures before trip (5)
	resetTimeout    time.Duration // Time before transitioning to HALF_OPEN (30s)
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

func (cb *FcmCircuitBreaker) GetState() CircuitState {
	cb.mu.RLock()
	defer cb.mu.RUnlock()
	return cb.state
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

type FcmManager struct {
	mu             sync.RWMutex
	db             *gorm.DB
	tokens         map[string]string
	sdmNips        map[string]bool
	notifications  map[string][]NotificationItem
	circuitBreaker *FcmCircuitBreaker
	serviceAccount *ServiceAccount
	cachedToken    string
	tokenExpiry    time.Time
}

var GlobalFcmManager = &FcmManager{
	tokens:         make(map[string]string),
	sdmNips:        make(map[string]bool),
	notifications:  make(map[string][]NotificationItem),
	circuitBreaker: NewFcmCircuitBreaker(),
}

func init() {
	_ = GlobalFcmManager.LoadServiceAccount("./firebase-service-account.json")
}

func (m *FcmManager) SetDB(db *gorm.DB) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.db = db
	if db != nil {
		_ = db.AutoMigrate(&NotificationModel{})
		log.Println("[FCM Manager] Database attached & AutoMigrated `notifications` table.")
	}
}

func (m *FcmManager) LoadServiceAccount(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		log.Printf("[FCM Manager] Service Account JSON not found at %s: %v", filePath, err)
		return err
	}
	var sa ServiceAccount
	if err := json.Unmarshal(data, &sa); err != nil {
		log.Printf("[FCM Manager] Failed to parse Service Account JSON: %v", err)
		return err
	}
	m.serviceAccount = &sa
	log.Printf("[FCM Manager] Successfully loaded Firebase Service Account: %s (%s)", sa.ClientEmail, sa.ProjectId)
	return nil
}

func (m *FcmManager) RegisterToken(nip string, token string) {
	nip = strings.TrimSpace(nip)
	if nip == "" {
		return
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	m.tokens[nip] = token
	log.Printf("[FCM Manager] Token registered for NIP: %s (Token: %s...)", nip, token[:min(len(token), 15)])
}

func (m *FcmManager) RegisterSdmNip(nip string) {
	nip = strings.TrimSpace(nip)
	if nip == "" {
		return
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	m.sdmNips[nip] = true
	log.Printf("[FCM Manager] Dynamic SDM NIP registered: %s", nip)
}

func (m *FcmManager) GetSdmNips() []string {
	m.mu.RLock()
	defer m.mu.RUnlock()
	nips := make([]string, 0, len(m.sdmNips))
	for nip := range m.sdmNips {
		nips = append(nips, nip)
	}
	return nips
}

func (m *FcmManager) GetToken(nip string) string {
	nip = strings.TrimSpace(nip)
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.tokens[nip]
}

func (m *FcmManager) AddNotification(item NotificationItem) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if item.CreatedAt == "" {
		item.CreatedAt = time.Now().Format(time.RFC3339)
	}
	if item.ID == "" {
		item.ID = time.Now().Format("20060102150405.000")
	}

	m.notifications[item.TargetNip] = append([]NotificationItem{item}, m.notifications[item.TargetNip]...)
}

func (m *FcmManager) GetNotificationsWithSdmCheck(nip string, isSdm bool) []NotificationItem {
	nip = strings.TrimSpace(nip)

	targets := []string{}
	if nip != "" {
		targets = append(targets, nip)
	}
	if isSdm {
		targets = append(targets, "SDM_BROADCAST")
	}

	if len(targets) == 0 {
		return []NotificationItem{}
	}

	m.mu.RLock()
	db := m.db
	var memoryItems []NotificationItem
	for _, t := range targets {
		if items, ok := m.notifications[t]; ok {
			memoryItems = append(memoryItems, items...)
		}
	}
	m.mu.RUnlock()

	var dbItems []NotificationModel
	if db != nil {
		_ = db.Where("target_nip IN ?", targets).Order("created_at desc").Limit(50).Find(&dbItems)
	}

	seen := make(map[string]bool)
	var result []NotificationItem

	for _, item := range memoryItems {
		if !seen[item.ID] {
			seen[item.ID] = true
			result = append(result, item)
		}
	}

	for _, model := range dbItems {
		if !seen[model.NotificationID] {
			seen[model.NotificationID] = true
			var payload map[string]string
			if model.PayloadJSON != "" {
				_ = json.Unmarshal([]byte(model.PayloadJSON), &payload)
			}
			result = append(result, NotificationItem{
				ID:        model.NotificationID,
				TargetNip: model.TargetNip,
				Title:     model.Title,
				Body:      model.Body,
				Type:      model.Type,
				Status:    model.Status,
				CreatedAt: model.CreatedAt.Format(time.RFC3339),
				Payload:   payload,
			})
		}
	}

	return result
}

func (m *FcmManager) GetNotifications(nip string) []NotificationItem {
	return m.GetNotificationsWithSdmCheck(nip, false)
}

// DispatchNotification FIRST persists notification to DB ("pending"), checks Circuit Breaker, then attempts FCM push
func (m *FcmManager) DispatchNotification(targetNips []string, title string, body string, reqType string, payload map[string]string) {
	payloadBytes, _ := json.Marshal(payload)
	payloadJSON := string(payloadBytes)

	for _, nip := range targetNips {
		nip = strings.TrimSpace(nip)
		if nip == "" {
			continue
		}

		notifID := fmt.Sprintf("%s-%s-%d", reqType, nip, time.Now().UnixNano())
		now := time.Now()

		// 1. FIRST PERSIST TO DATABASE (Status: "pending")
		dbModel := NotificationModel{
			NotificationID: notifID,
			TargetNip:      nip,
			Title:          title,
			Body:           body,
			Type:           reqType,
			Status:         "pending",
			RetryCount:     0,
			PayloadJSON:    payloadJSON,
			CreatedAt:      now,
			UpdatedAt:      now,
		}

		m.mu.RLock()
		db := m.db
		m.mu.RUnlock()

		if db != nil {
			if err := db.Create(&dbModel).Error; err != nil {
				log.Printf("[FCM Control Error] Failed to persist notification %s to DB: %v", notifID, err)
			} else {
				log.Printf("[FCM Control] Persisted Notification to DB | ID: %d (%s) | NIP: %s | Status: PENDING", dbModel.ID, notifID, nip)
			}
		}

		// Add to memory cache for fast client API read
		item := NotificationItem{
			ID:        notifID,
			TargetNip: nip,
			Title:     title,
			Body:      body,
			Type:      reqType,
			Status:    "unread",
			CreatedAt: now.Format(time.RFC3339),
			Payload:   payload,
		}
		m.AddNotification(item)

		// 2. CHECK CIRCUIT BREAKER BEFORE PUSHING
		if !m.circuitBreaker.AllowExecution() {
			log.Printf("[FCM Control Warning] Circuit Breaker is OPEN. FCM push skipped for NIP: %s. State updated in DB to 'circuit_broken'.", nip)
			if db != nil && dbModel.ID > 0 {
				db.Model(&dbModel).Updates(map[string]interface{}{
					"status":        "circuit_broken",
					"error_message": "FCM Circuit Breaker is OPEN",
					"updated_at":    time.Now(),
				})
			}
			continue
		}

		// 3. EXECUTE PUSH NOTIFICATION WITH FAILURE & RETRY CONTROL
		token := m.GetToken(nip)
		if token != "" {
			go m.controlledFcmPush(db, &dbModel, token, title, body, payload)
		} else {
			log.Printf("[FCM Control] Target NIP %s has no active FCM token, notification stored in DB & in-app inbox.", nip)
		}
	}
}

// controlledFcmPush executes FCM push with Circuit Breaker tracking & DB audit update
func (m *FcmManager) controlledFcmPush(db *gorm.DB, dbModel *NotificationModel, fcmToken string, title string, body string, payload map[string]string) {
	err := m.sendFcmHttpV1Push(fcmToken, title, body, payload)

	m.circuitBreaker.RecordResult(err)

	if db == nil || dbModel.ID == 0 {
		return
	}

	if err == nil {
		db.Model(dbModel).Updates(map[string]interface{}{
			"status":     "sent",
			"updated_at": time.Now(),
		})
		log.Printf("[FCM Control] Notification ID %d pushed successfully! DB Status updated to 'sent'.", dbModel.ID)
	} else {
		db.Model(dbModel).Updates(map[string]interface{}{
			"status":        "failed",
			"error_message": err.Error(),
			"retry_count":   gorm.Expr("retry_count + 1"),
			"updated_at":    time.Now(),
		})
		log.Printf("[FCM Control Error] Notification ID %d push failed (%v). DB Status updated to 'failed'.", dbModel.ID, err)
	}
}

func (m *FcmManager) getGoogleAccessToken() (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.cachedToken != "" && time.Now().Before(m.tokenExpiry) {
		return m.cachedToken, nil
	}

	if m.serviceAccount == nil {
		return "", errors.New("service account credentials not loaded")
	}

	block, _ := pem.Decode([]byte(m.serviceAccount.PrivateKey))
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
		"iss":   m.serviceAccount.ClientEmail,
		"sub":   m.serviceAccount.ClientEmail,
		"aud":   m.serviceAccount.TokenUri,
		"iat":   now.Unix(),
		"exp":   now.Add(1 * time.Hour).Unix(),
		"scope": "https://www.googleapis.com/auth/firebase.messaging",
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	signedToken, err := token.SignedString(rsaKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign JWT assertion token: %v", err)
	}

	resp, err := http.PostForm(m.serviceAccount.TokenUri, map[string][]string{
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

	m.cachedToken = tokenResp.AccessToken
	m.tokenExpiry = now.Add(time.Duration(tokenResp.ExpiresIn-60) * time.Second)
	log.Printf("[FCM Manager] Generated new Google OAuth2 Access Token for FCM HTTP v1 API")
	return m.cachedToken, nil
}

func (m *FcmManager) sendFcmHttpV1Push(fcmToken string, title string, body string, payload map[string]string) error {
	accessToken, err := m.getGoogleAccessToken()
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
					"apns-priority": "10", // High priority
				},
				"payload": map[string]interface{}{
					"aps": map[string]interface{}{
						"alert": map[string]string{
							"title": title,
							"body":  body,
						},
						"sound":             "default",
						"badge":             1,
						"content-available": 1, // Memungkinkan background processing jika dibutuhkan
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
		return fmt.Errorf("FCM HTTP v1 Push error for token (%s...): %v", fcmToken[:min(len(fcmToken), 10)], err)
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return fmt.Errorf("FCM API returned status %d: %s", resp.StatusCode, string(respBytes))
	}
	log.Printf("[FCM Push Log] FCM HTTP v1 Push SUCCESS for token (%s...) | Response: %s", fcmToken[:min(len(fcmToken), 10)], string(respBytes))
	return nil
}
