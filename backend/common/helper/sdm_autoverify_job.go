package helper

import (
	"log"
	"time"

	"gorm.io/gorm"
)

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

	// 1. Auto-verify Cuti (Leave)
	var pendingLeaves []struct {
		ID        uint   `gorm:"column:id"`
		Nip       string `gorm:"column:nip"`
		NipAtasan string `gorm:"column:nip_atasan"`
		Status    string `gorm:"column:status"`
		CreatedAt time.Time
		UpdatedAt time.Time
	}

	errLeave := db.Table("leave").
		Select("id, nip, nip_atasan, status, created_at, updated_at").
		Where("status = ? AND (updated_at <= ? OR created_at <= ?)", "terima atasan", thresholdTime, thresholdTime).
		Find(&pendingLeaves).Error

	if errLeave == nil && len(pendingLeaves) > 0 {
		for _, leave := range pendingLeaves {
			log.Printf("[SDM Auto-Verify Job] Auto-verifying Cuti ID %d for NIP %s (1x24h threshold met)", leave.ID, leave.Nip)
			db.Table("leave").Where("id = ?", leave.ID).Update("status", "terima sdm")

			// Dispatch FCM Notifications to Employee and Atasan
			targets := []string{leave.Nip}
			if leave.NipAtasan != "" {
				targets = append(targets, leave.NipAtasan)
			}

			title := "Verifikasi Otomatis SDM (1x24 Jam)"
			body := "Pengajuan Cuti NIP " + leave.Nip + " telah diverifikasi dan disetujui otomatis oleh Sistem SDM setelah 1x24 jam."
			payload := map[string]string{
				"type":        "cuti",
				"id":          strconvUint(leave.ID),
				"status":      "terima sdm",
				"autoverify":  "true",
			}
			GlobalFcmManager.DispatchNotification(targets, title, body, "cuti", payload)
		}
	}

	// 2. Auto-verify Izin
	var pendingIzin []struct {
		ID         uint   `gorm:"column:id"`
		Nip        string `gorm:"column:nip"`
		Verifikasi string `gorm:"column:verifikasi"`
		Status     string `gorm:"column:status"`
		CreatedAt  time.Time
		UpdatedAt  time.Time
	}

	errIzin := db.Table("izin").
		Select("id, nip, verifikasi, status, created_at, updated_at").
		Where("status = ? AND (updated_at <= ? OR created_at <= ?)", "terima atasan", thresholdTime, thresholdTime).
		Find(&pendingIzin).Error

	if errIzin == nil && len(pendingIzin) > 0 {
		for _, iz := range pendingIzin {
			log.Printf("[SDM Auto-Verify Job] Auto-verifying Izin ID %d for NIP %s (1x24h threshold met)", iz.ID, iz.Nip)
			db.Table("izin").Where("id = ?", iz.ID).Update("status", "terima sdm")

			targets := []string{iz.Nip}
			if iz.Verifikasi != "" {
				targets = append(targets, iz.Verifikasi)
			}

			title := "Verifikasi Otomatis SDM (1x24 Jam)"
			body := "Pengajuan Izin NIP " + iz.Nip + " telah diverifikasi dan disetujui otomatis oleh Sistem SDM setelah 1x24 jam."
			payload := map[string]string{
				"type":       "izin",
				"id":         strconvUint(iz.ID),
				"status":     "terima sdm",
				"autoverify": "true",
			}
			GlobalFcmManager.DispatchNotification(targets, title, body, "izin", payload)
		}
	}

	// 3. Auto-verify SPPD
	var pendingSppd []struct {
		ID         uint   `gorm:"column:id"`
		Nip        string `gorm:"column:nip"`
		Verifikasi string `gorm:"column:verifikasi"`
		Status     string `gorm:"column:status"`
		CreatedAt  time.Time
		UpdatedAt  time.Time
	}

	errSppd := db.Table("sppd").
		Select("id, nip, verifikasi, status, created_at, updated_at").
		Where("status = ? AND (updated_at <= ? OR created_at <= ?)", "terima atasan", thresholdTime, thresholdTime).
		Find(&pendingSppd).Error

	if errSppd == nil && len(pendingSppd) > 0 {
		for _, sppd := range pendingSppd {
			log.Printf("[SDM Auto-Verify Job] Auto-verifying SPPD ID %d for NIP %s (1x24h threshold met)", sppd.ID, sppd.Nip)
			db.Table("sppd").Where("id = ?", sppd.ID).Update("status", "terima sdm")

			targets := []string{sppd.Nip}
			if sppd.Verifikasi != "" {
				targets = append(targets, sppd.Verifikasi)
			}

			title := "Verifikasi Otomatis SDM (1x24 Jam)"
			body := "Pengajuan SPPD NIP " + sppd.Nip + " telah diverifikasi dan disetujui otomatis oleh Sistem SDM setelah 1x24 jam."
			payload := map[string]string{
				"type":       "sppd",
				"id":         strconvUint(sppd.ID),
				"status":     "terima sdm",
				"autoverify": "true",
			}
			GlobalFcmManager.DispatchNotification(targets, title, body, "sppd", payload)
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
