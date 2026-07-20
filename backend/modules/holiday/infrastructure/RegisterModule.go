package infrastructure

import (
	"hrportal_backend/modules/holiday/domain"

	"gorm.io/gorm"
)

func RegisterModuleHoliday(db *gorm.DB) error {
	// Auto migrate master_libur table
	if err := db.AutoMigrate(&domain.MasterLibur{}); err != nil {
		return err
	}

	// Initialize and start the background sync job
	worker := NewHolidaySyncWorker(db)
	worker.Start()

	return nil
}
