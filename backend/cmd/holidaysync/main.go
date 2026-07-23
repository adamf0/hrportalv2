package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	holidayInfra "hrportal_backend/modules/holiday/infrastructure"
)

func main() {
	log.Println("[Holiday Sync Worker] Starting standalone background worker binary...")

	dsn := os.Getenv("DB_HRPORTAL")
	if dsn == "" {
		dsn = "root:@tcp(127.0.0.1:3306)/unpak_hrportal?charset=utf8mb4&parseTime=True&loc=Local"
	}

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("[Holiday Sync Worker] Failed to connect to HRPortal database: %v", err)
	}

	worker := holidayInfra.NewHolidaySyncWorker(db)
	
	log.Println("[Holiday Sync Worker] Running initial sync...")
	if err := worker.Sync(); err != nil {
		log.Printf("[Holiday Sync Worker] Sync error: %v", err)
	} else {
		log.Println("[Holiday Sync Worker] Initial sync finished successfully.")
	}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()

	go func() {
		for range ticker.C {
			log.Println("[Holiday Sync Worker] Running scheduled 24h sync...")
			if err := worker.Sync(); err != nil {
				log.Printf("[Holiday Sync Worker] Sync error: %v", err)
			}
		}
	}()

	sig := <-sigChan
	log.Printf("[Holiday Sync Worker] Shutdown signal received (%v). Exiting gracefully.", sig)
}
