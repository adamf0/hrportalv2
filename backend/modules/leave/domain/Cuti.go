package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type Cuti struct {
	common.Entity
	ID             uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	Nip            string     `gorm:"column:nip;index" json:"nip"`
	Nidn           string     `gorm:"column:nidn;index" json:"nidn"`
	JenisCutiID    uint       `gorm:"column:id_jenis_cuti" json:"jenis_cuti_id"`
	TanggalMulai   string     `gorm:"column:tanggal_mulai;index" json:"tanggal_mulai"`
	TanggalSelesai string     `gorm:"column:tanggal_akhir;index" json:"tanggal_selesai"`
	JumlahHari     int        `gorm:"column:lama_cuti" json:"jumlah_hari"`
	Alasan         string     `gorm:"column:tujuan" json:"alasan"`
	NipAtasan      *string    `gorm:"-" json:"nip_atasan"`
	FileLampiran   *string    `gorm:"column:dokumen" json:"file_lampiran"`
	Status         string     `gorm:"column:status" json:"status"`
	CatatanAtasan  *string    `gorm:"column:catatan" json:"catatan_atasan"`
	CreatedAt      *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt      *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (Cuti) TableName() string {
	return "cuti"
}

type JenisCuti struct {
	ID        uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	Nama      string `gorm:"column:nama" json:"nama"`
	MaksHari  int    `gorm:"column:maks_hari" json:"maks_hari"`
	Deskripsi string `gorm:"column:deskripsi" json:"deskripsi"`
}

func (JenisCuti) TableName() string {
	return "jenis_cuti"
}
