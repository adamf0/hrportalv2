package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type Izin struct {
	common.Entity
	ID               uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	Nip              string     `gorm:"column:nip;index" json:"nip"`
	Nidn             string     `gorm:"column:nidn;index" json:"nidn"`
	JenisIzinID      int        `gorm:"column:id_jenis_izin;type:int" json:"jenis_izin_id"`
	TanggalPengajuan string     `gorm:"column:tanggal_pengajuan;index" json:"tanggal_pengajuan"`
	Tujuan           string     `gorm:"column:tujuan" json:"tujuan"`
	Status           string     `gorm:"column:status" json:"status"`
	CreatedAt        *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt        *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (Izin) TableName() string {
	return "izin"
}
