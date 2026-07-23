package infrastructure

import (
	"gorm.io/gorm"
)

func RegisterModuleHoliday(db *gorm.DB) error {
	// Note: Holiday background sync worker is separated into standalone binary in cmd/holidaysync
	return nil
}
