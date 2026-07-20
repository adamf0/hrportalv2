package infrastructure

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	"hrportal_backend/modules/holiday/domain"

	"gorm.io/gorm"
)

type HolidaySyncWorker struct {
	db *gorm.DB
}

func NewHolidaySyncWorker(db *gorm.DB) *HolidaySyncWorker {
	return &HolidaySyncWorker{db: db}
}

func (w *HolidaySyncWorker) Start() {
	// Run first sync on startup in a goroutine so it doesn't block main startup
	go func() {
		log.Println("[HolidaySyncWorker] Starting startup holiday synchronization...")
		if err := w.Sync(); err != nil {
			log.Printf("[HolidaySyncWorker] Startup sync error: %v", err)
		} else {
			log.Println("[HolidaySyncWorker] Startup holiday synchronization finished successfully.")
		}
	}()

	// Schedule to run periodically every 24 hours
	go func() {
		ticker := time.NewTicker(24 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			log.Println("[HolidaySyncWorker] Starting periodic holiday synchronization...")
			if err := w.Sync(); err != nil {
				log.Printf("[HolidaySyncWorker] Periodic sync error: %v", err)
			} else {
				log.Println("[HolidaySyncWorker] Periodic holiday synchronization finished successfully.")
			}
		}
	}()
}

func (w *HolidaySyncWorker) Sync() error {
	var count int64
	if err := w.db.Model(&domain.MasterLibur{}).Count(&count).Error; err != nil {
		return err
	}

	currentYear := time.Now().Year()

	if count == 0 {
		// First time sync (database empty): pull Y-1, Y, Y+1
		log.Printf("[HolidaySyncWorker] Database is empty. Syncing 3 years: %d, %d, %d", currentYear-1, currentYear, currentYear+1)
		for _, year := range []int{currentYear - 1, currentYear, currentYear + 1} {
			if err := w.syncYear(year); err != nil {
				log.Printf("[HolidaySyncWorker] Error syncing year %d: %v", year, err)
			}
		}
	} else {
		// Database already populated: sync Y+1
		// log.Printf("[HolidaySyncWorker] Database already populated. Syncing year Y+1: %d", currentYear+1)
		// if err := w.syncYear(currentYear + 1); err != nil {
		// 	log.Printf("[HolidaySyncWorker] Error syncing year Y+1 %d: %v", currentYear+1, err)
		// }

		// Also check if Y-1 or Y are missing from database and sync them if they are
		for _, year := range []int{currentYear - 1, currentYear} {
			var yearCount int64
			w.db.Model(&domain.MasterLibur{}).Where("YEAR(tanggal) = ?", year).Count(&yearCount)
			if yearCount == 0 {
				log.Printf("[HolidaySyncWorker] Year %d has no data in database. Syncing it now...", year)
				if err := w.syncYear(year); err != nil {
					log.Printf("[HolidaySyncWorker] Error syncing missing year %d: %v", year, err)
				}
			}
		}
	}

	return nil
}

func (w *HolidaySyncWorker) syncYear(year int) error {
	types := []string{"Public Holiday", "Joint Holiday", "National Holiday", "Observance"}
	apiKey := os.Getenv("API_KEY_CO_ID")
	if apiKey == "" {
		apiKey = "-"
	}

	for _, t := range types {
		page := 1
		for {
			targetUrl := fmt.Sprintf("https://use.api.co.id/holidays/indonesia/?year=%d&page=%d&type=%s", year, page, url.QueryEscape(t))
			req, err := http.NewRequest("GET", targetUrl, nil)
			if err != nil {
				return err
			}
			req.Header.Set("x-api-co-id", apiKey)
			req.Header.Set("Content-Type", "application/json")

			client := &http.Client{Timeout: 15 * time.Second}
			resp, err := client.Do(req)
			if err != nil {
				return err
			}
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				return fmt.Errorf("API returned status code %d for url: %s", resp.StatusCode, targetUrl)
			}

			var apiResp struct {
				IsSuccess bool   `json:"is_success"`
				Message   string `json:"message"`
				Data      []struct {
					ID                int    `json:"id"`
					Date              string `json:"date"`
					Name              string `json:"name"`
					Type              string `json:"type"`
					IsHoliday         bool   `json:"is_holiday"`
					IsNationalHoliday bool   `json:"is_national_holiday"`
				} `json:"data"`
				Paging struct {
					Page      int `json:"page"`
					Size      int `json:"size"`
					TotalItem int `json:"total_item"`
					TotalPage int `json:"total_page"`
				} `json:"paging"`
			}

			if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
				return err
			}

			if !apiResp.IsSuccess {
				return fmt.Errorf("API error: %s", apiResp.Message)
			}

			for _, d := range apiResp.Data {
				// is_national_holiday in master_libur should be true for all holidays (Public, Joint, National Holiday)
				isNational := d.IsHoliday || d.IsNationalHoliday || d.Type == "Public Holiday" || d.Type == "Joint Holiday" || d.Type == "National Holiday"
				holiday := domain.MasterLibur{
					HolidayID:         fmt.Sprintf("%d", d.ID),
					Tanggal:           d.Date,
					Nama:              d.Name,
					Type:              d.Type,
					IsNationalHoliday: isNational,
				}

				var existing domain.MasterLibur
				err := w.db.Where("holiday_id = ?", holiday.HolidayID).First(&existing).Error
				if err == gorm.ErrRecordNotFound {
					if err := w.db.Create(&holiday).Error; err != nil {
						log.Printf("[HolidaySyncWorker] Error creating holiday %s: %v", holiday.HolidayID, err)
					}
				} else if err == nil {
					holiday.ID = existing.ID
					holiday.CreatedAt = existing.CreatedAt
					if err := w.db.Save(&holiday).Error; err != nil {
						log.Printf("[HolidaySyncWorker] Error updating holiday %s: %v", holiday.HolidayID, err)
					}
				} else {
					log.Printf("[HolidaySyncWorker] Database query error: %v", err)
				}
			}

			if page >= apiResp.Paging.TotalPage || len(apiResp.Data) == 0 {
				break
			}
			page++
		}
	}

	return nil
}
