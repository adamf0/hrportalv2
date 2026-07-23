package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	reportInfra "hrportal_backend/modules/report/infrastructure"
)

func main() {
	log.Println("[Export Worker] Starting standalone background worker binary...")

	dsn := os.Getenv("DB_HRPORTAL")
	if dsn == "" {
		dsn = "root:@tcp(127.0.0.1:3306)/unpak_hrportal?charset=utf8mb4&parseTime=True&loc=Local"
	}

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("[Export Worker] Failed to connect to HRPortal database: %v", err)
	}

	sqlDB, _ := db.DB()
	sqlDB.SetMaxOpenConns(20)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(10 * time.Minute)

	repo := reportInfra.NewReportRepository(db)
	worker := reportInfra.NewExportWorker(db, repo)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		worker.ProcessQueueLoop()
	}()

	sig := <-sigChan
	log.Printf("[Export Worker] Shutdown signal received (%v). Exiting gracefully.", sig)
}
