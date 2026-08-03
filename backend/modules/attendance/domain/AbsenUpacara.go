package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type AbsenUpacara struct {
	common.Entity
	ID        uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	Nidn      string     `gorm:"column:nidn;type:varchar(100);not null;default:'';index:absen_upacara_nidn_tanggal_IDX,priority:1" json:"nidn"`
	Nip       string     `gorm:"column:nip;type:varchar(100);not null;default:'';index:absen_upacara_nip_tanggal_IDX,priority:1" json:"nip"`
	Nama      string     `gorm:"column:nama" json:"nama"`
	Unit      string     `gorm:"column:unit" json:"unit"`
	Fakultas  string     `gorm:"column:fakultas" json:"fakultas"`
	Prodi     string     `gorm:"column:prodi" json:"prodi"`
	Tanggal   string     `gorm:"column:tanggal;type:date;not null;index:absen_upacara_nip_tanggal_IDX,priority:2;index:absen_upacara_nidn_tanggal_IDX,priority:2" json:"tanggal"`
	CreatedAt *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (AbsenUpacara) TableName() string {
	return "absen_upacara"
}
