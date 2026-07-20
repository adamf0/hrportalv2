package domain

import "time"

type MasterLibur struct {
	ID                uint      `gorm:"primaryKey;column:id;autoIncrement" json:"id"`
	HolidayID         string    `gorm:"column:holiday_id;uniqueIndex;type:varchar(100)" json:"holiday_id"`
	Tanggal           string    `gorm:"column:tanggal;type:date" json:"tanggal"`
	Nama              string    `gorm:"column:nama;type:varchar(255)" json:"nama"`
	Type              string    `gorm:"column:type;type:varchar(100)" json:"type"`
	IsNationalHoliday bool      `gorm:"column:is_national_holiday" json:"is_national_holiday"`
	CreatedAt         time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt         time.Time `gorm:"column:updated_at" json:"updated_at"`
	Libur             int       `gorm:"-" json:"libur"`
}

func (MasterLibur) TableName() string {
	return "master_libur"
}
