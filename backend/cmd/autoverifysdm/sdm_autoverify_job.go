package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"gorm.io/gorm"
)

type NotificationModel struct {
	ID             uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	NotificationID string    `gorm:"column:notification_id;uniqueIndex" json:"notification_id"`
	TargetNip      string    `gorm:"column:target_nip;index" json:"target_nip"`
	TargetNidn     string    `gorm:"column:target_nidn;index" json:"target_nidn"`
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

func createPendingNotificationDirect(db *gorm.DB, targetNips []string, targetNidns []string, title, body, reqType string, payload map[string]string) {
	if db == nil {
		return
	}
	payloadBytes, _ := json.Marshal(payload)
	payloadJSON := string(payloadBytes)
	now := time.Now()

	for _, nip := range targetNips {
		if nip == "" {
			continue
		}
		notifID := fmt.Sprintf("%s-%s-%d", reqType, nip, now.UnixNano())
		model := NotificationModel{
			NotificationID: notifID,
			TargetNip:      nip,
			TargetNidn:     "",
			Title:          title,
			Body:           body,
			Type:           reqType,
			Status:         "pending",
			RetryCount:     0,
			PayloadJSON:    payloadJSON,
			CreatedAt:      now,
			UpdatedAt:      now,
		}

		if err := db.Create(&model).Error; err != nil {
			log.Printf("[SDM Auto-Verify Job Error] Failed to insert notification %s into DB: %v", notifID, err)
		} else {
			log.Printf("[SDM Auto-Verify Job] Created pending notification ID %d (%s) for NIP %s", model.ID, notifID, nip)
		}
	}

	for _, nidn := range targetNidns {
		if nidn == "" {
			continue
		}
		notifID := fmt.Sprintf("%s-%s-%d", reqType, nidn, now.UnixNano())
		model := NotificationModel{
			NotificationID: notifID,
			TargetNip:      "",
			TargetNidn:     nidn,
			Title:          title,
			Body:           body,
			Type:           reqType,
			Status:         "pending",
			RetryCount:     0,
			PayloadJSON:    payloadJSON,
			CreatedAt:      now,
			UpdatedAt:      now,
		}

		if err := db.Create(&model).Error; err != nil {
			log.Printf("[SDM Auto-Verify Job Error] Failed to insert notification %s into DB: %v", notifID, err)
		} else {
			log.Printf("[SDM Auto-Verify Job] Created pending notification ID %d (%s) for NIDN %s", model.ID, notifID, nidn)
		}
	}
}

// RunSdmAutoVerifyLoop executes the 1x24h SDM Auto-Verification in a blocking worker loop (for standalone worker binary)
func RunSdmAutoVerifyLoop(db *gorm.DB) {
	if db == nil {
		log.Println("[SDM Auto-Verify Worker] Database connection is nil, worker stopped.")
		return
	}

	log.Println("[SDM Auto-Verify Worker] Standalone Golang 1x24h Background Auto-Verification Worker active.")
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	// Initial run
	processAutoVerifyRequests(db)

	for range ticker.C {
		processAutoVerifyRequests(db)
	}
}

func StartSdmAutoVerifyBackgroundJob(db *gorm.DB) {
	if db == nil {
		log.Println("[SDM Auto-Verify Job] Database connection is nil, background job skipped.")
		return
	}

	log.Println("[SDM Auto-Verify Job] Starting Golang 1x24h Background Auto-Verification Worker...")

	// Ticker runs every 30 seconds to check for expired pending requests (older than 24 hours)
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		for range ticker.C {
			processAutoVerifyRequests(db)
		}
	}()
}

func processAutoVerifyRequests(db *gorm.DB) {
	thresholdTime := time.Now().Add(-24 * time.Hour)
	now := time.Now()

	// 1. Auto-verify Cuti (Leave)
	var pendingLeaves []struct {
		ID          uint   `gorm:"column:id"`
		Nidn        string `gorm:"column:nidn"`
		Nip         string `gorm:"column:nip"`
		NamaPemohon string `gorm:"column:nama_pemohon"`
		Unit        string `gorm:"column:unit"`
		Fakultas    string `gorm:"column:fakultas"`
		Prodi       string `gorm:"column:prodi"`
		Verifikasi  string `gorm:"column:verifikasi"`
		Status      string `gorm:"column:status"`
		CreatedAt   time.Time
		UpdatedAt   time.Time
	}

	errLeave := db.Table("cuti").
		Select("id, nidn, nip, nama_pemohon, unit, fakultas, prodi, verifikasi, status, created_at, updated_at").
		Where("LOWER(status) IN ('terima atasan', 'disetujui atasan') AND (updated_at <= ? OR created_at <= ?)", thresholdTime, thresholdTime).
		Find(&pendingLeaves).Error

	if errLeave == nil && len(pendingLeaves) > 0 {
		for _, leave := range pendingLeaves {
			log.Printf("[SDM Auto-Verify Job] Auto-verifying Cuti ID %d for NIP %s NIDN %s (1x24h threshold met)", leave.ID, leave.Nip, leave.Nidn)
			db.Table("cuti").Where("id = ?", leave.ID).Updates(map[string]interface{}{
				"status":     "terima sdm",
				"updated_at": now,
			})

			// Dispatch FCM Notifications to Employee and Atasan
			var targetsNips []string
			var targetsNidns []string
			if leave.Nip != "" {
				targetsNips = append(targetsNips, leave.Nip)
			}
			if leave.Nidn != "" {
				targetsNidns = append(targetsNips, leave.Nidn)
			}
			if leave.Verifikasi != "" {
				targetsNips = append(targetsNips, leave.Verifikasi)
			}

			title := "Verifikasi Otomatis SDM (1x24 Jam)"
			body := "Pengajuan Cuti NIP " + leave.Nip + " NIDN " + leave.Nidn + " telah diverifikasi dan disetujui otomatis oleh Sistem SDM setelah 1x24 jam."
			payload := map[string]string{
				"type":       "cuti",
				"id":         strconvUint(leave.ID),
				"status":     "terima sdm",
				"autoverify": "true",
			}
			createPendingNotificationDirect(db, targetsNips, targetsNidns, title, body, "cuti", payload)
		}
	}

	// 2. Auto-verify Izin
	var pendingIzin []struct {
		ID          uint   `gorm:"column:id"`
		Nidn        string `gorm:"column:nidn"`
		Nip         string `gorm:"column:nip"`
		NamaPemohon string `gorm:"column:nama_pemohon"`
		Unit        string `gorm:"column:unit"`
		Fakultas    string `gorm:"column:fakultas"`
		Prodi       string `gorm:"column:prodi"`
		Verifikasi  string `gorm:"column:verifikasi"`
		Status      string `gorm:"column:status"`
		CreatedAt   time.Time
		UpdatedAt   time.Time
	}

	errIzin := db.Table("izin").
		Select("id, nidn, nip, nama_pemohon, unit, fakultas, prodi, verifikasi, status, created_at, updated_at").
		Where("LOWER(status) IN ('terima atasan', 'disetujui atasan') AND (updated_at <= ? OR created_at <= ?)", thresholdTime, thresholdTime).
		Find(&pendingIzin).Error

	if errIzin == nil && len(pendingIzin) > 0 {
		for _, iz := range pendingIzin {
			log.Printf("[SDM Auto-Verify Job] Auto-verifying Izin ID %d for NIP %s (1x24h threshold met)", iz.ID, iz.Nip)
			db.Table("izin").Where("id = ?", iz.ID).Updates(map[string]interface{}{
				"status":     "terima sdm",
				"updated_at": now,
			})

			targetNips := []string{iz.Nip}
			targetNidns := []string{iz.Nidn}
			if iz.Verifikasi != "" {
				targetNips = append(targetNips, iz.Verifikasi)
			}

			title := "Verifikasi Otomatis SDM (1x24 Jam)"
			body := "Pengajuan Izin NIP " + iz.Nip + " telah diverifikasi dan disetujui otomatis oleh Sistem SDM setelah 1x24 jam."
			payload := map[string]string{
				"type":       "izin",
				"id":         strconvUint(iz.ID),
				"status":     "terima sdm",
				"autoverify": "true",
			}
			createPendingNotificationDirect(db, targetNips, targetNidns, title, body, "izin", payload)
		}
	}

	// 3. Auto-verify SPPD
	var pendingSppd []struct {
		ID          uint   `gorm:"column:id"`
		Nidn        string `gorm:"column:nidn"`
		Nip         string `gorm:"column:nip"`
		NamaPemohon string `gorm:"column:nama_pemohon"`
		Unit        string `gorm:"column:unit"`
		Fakultas    string `gorm:"column:fakultas"`
		Prodi       string `gorm:"column:prodi"`
		Verifikasi  string `gorm:"column:verifikasi"`
		Status      string `gorm:"column:status"`
		CreatedAt   time.Time
		UpdatedAt   time.Time
	}

	errSppd := db.Table("sppd").
		Select("id, nidn, nip, nama_pemohon, unit, fakultas, prodi, verifikasi, status, created_at, updated_at").
		Where("LOWER(status) IN ('terima atasan', 'disetujui atasan') AND (updated_at <= ? OR created_at <= ?)", thresholdTime, thresholdTime).
		Find(&pendingSppd).Error

	if errSppd == nil && len(pendingSppd) > 0 {
		for _, sppd := range pendingSppd {
			log.Printf("[SDM Auto-Verify Job] Auto-verifying SPPD ID %d for NIP %s (1x24h threshold met)", sppd.ID, sppd.Nip)
			db.Table("sppd").Where("id = ?", sppd.ID).Updates(map[string]interface{}{
				"status":     "terima sdm",
				"updated_at": now,
			})

			targetNips := []string{sppd.Nip}
			targetNidns := []string{sppd.Nidn}
			if sppd.Verifikasi != "" {
				targetNips = append(targetNips, sppd.Verifikasi)
			}

			title := "Verifikasi Otomatis SDM (1x24 Jam)"
			body := "Pengajuan SPPD NIP " + sppd.Nip + " telah diverifikasi dan disetujui otomatis oleh Sistem SDM setelah 1x24 jam."
			payload := map[string]string{
				"type":       "sppd",
				"id":         strconvUint(sppd.ID),
				"status":     "terima sdm",
				"autoverify": "true",
			}
			createPendingNotificationDirect(db, targetNips, targetNidns, title, body, "sppd", payload)
		}
	}
}

func strconvUint(n uint) string {
	if n == 0 {
		return "0"
	}
	var b [20]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	return string(b[i:])
}
