package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type AbsenUpacara struct {
	common.Entity
	ID        uint       `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	Nidn      string     `gorm:"column:nidn" json:"nidn"`
	Nip       string     `gorm:"column:nip" json:"nip"`
	Nama      string     `gorm:"column:nama" json:"nama"`
	Unit      string     `gorm:"column:unit" json:"unit"`
	Fakultas  string     `gorm:"column:fakultas" json:"fakultas"`
	Prodi     string     `gorm:"column:prodi" json:"prodi"`
	Tanggal   string     `gorm:"column:tanggal;type:date" json:"tanggal"`
	CreatedAt *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (AbsenUpacara) TableName() string {
	return "absen_upacara"
}
