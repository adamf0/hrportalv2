package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type Absen struct {
	common.Entity
	ID             uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	Nidn           string     `gorm:"column:nidn;index" json:"nidn"`
	Nip            string     `gorm:"column:nip;index" json:"nip"`
	Tanggal        string     `gorm:"column:tanggal;index" json:"tanggal"`
	AbsenMasuk     *time.Time `gorm:"column:absen_masuk" json:"absen_masuk"`
	AbsenKeluar    *time.Time `gorm:"column:absen_keluar" json:"absen_keluar"`
	CatatanTelat   *string    `gorm:"column:catatan_telat" json:"catatan_telat"`
	CatatanPulang  *string    `gorm:"column:catatan_pulang" json:"catatan_pulang"`
	Note           string     `gorm:"column:note;type:varchar(10)" json:"note"`
	OtomatisKeluar bool       `gorm:"column:otomatis_keluar" json:"otomatis_keluar"`
	CreatedAt      *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt      *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (Absen) TableName() string {
	return "absen"
}

type KlaimAbsen struct {
	common.Entity
	ID         uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	Nip        string     `gorm:"column:nip" json:"nip"`
	Tanggal    string     `gorm:"column:tanggal" json:"tanggal"`
	TipeKlaim  string     `gorm:"column:tipe_klaim" json:"tipe_klaim"`
	Keterangan string     `gorm:"column:keterangan" json:"keterangan"`
	Status     string     `gorm:"column:status" json:"status"`
	CreatedAt  *time.Time `gorm:"column:created_at" json:"created_at"`
}

func (KlaimAbsen) TableName() string {
	return "klaim_absen"
}
