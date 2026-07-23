package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	commonhelper "hrportal_backend/common/helper"
)

func main() {
	log.Println("[SDM Auto-Verify Worker] Starting standalone background worker binary...")

	dsn := os.Getenv("DB_HRPORTAL")
	if dsn == "" {
		dsn = "root:@tcp(127.0.0.1:3306)/unpak_hrportal?charset=utf8mb4&parseTime=True&loc=Local"
	}

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("[SDM Auto-Verify Worker] Failed to connect to HRPortal database: %v", err)
	}

	sqlDB, _ := db.DB()
	sqlDB.SetMaxOpenConns(20)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(10 * time.Minute)

	log.Println("[SDM Auto-Verify Worker] Connected to HRPortal database. Running worker loop...")

	// Listen for OS termination signals (SIGINT, SIGTERM)
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		commonhelper.RunSdmAutoVerifyLoop(db)
	}()

	sig := <-sigChan
	log.Printf("[SDM Auto-Verify Worker] Shutdown signal received (%v). Exiting gracefully.", sig)
}
