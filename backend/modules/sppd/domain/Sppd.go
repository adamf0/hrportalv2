package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type Sppd struct {
	common.Entity
	ID                       uint               `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	Nidn                     string             `gorm:"column:nidn;index" json:"nidn"`
	Nip                      string             `gorm:"column:nip;index" json:"nip"`
	Tujuan                   string             `gorm:"column:tujuan" json:"tujuan"`
	JenisSppdID              uint               `gorm:"column:id_jenis_sppd" json:"jenis_sppd_id"`
	TanggalBerangkat         string             `gorm:"column:tanggal_berangkat;index" json:"tanggal_berangkat"`
	TanggalKembali           string             `gorm:"column:tanggal_kembali;index" json:"tanggal_kembali"`
	Keterangan               string             `gorm:"column:keterangan" json:"keterangan"`
	SaranaTransportasi       *string            `gorm:"column:sarana_transportasi" json:"sarana_transportasi"`
	Verifikasi               *string            `gorm:"column:verifikasi" json:"verifikasi"`
	Status                   string             `gorm:"column:status" json:"status"`
	DokumenAnggaran          *string            `gorm:"column:dokumen_anggaran" json:"dokumen_anggaran"`
	Catatan                  *string            `gorm:"column:catatan" json:"catatan"`
	Intisari                 *string            `gorm:"column:intisari" json:"intisari"`
	Kontribusi               *string            `gorm:"column:kontribusi" json:"kontribusi"`
	RencanaTindakLanjut      *string            `gorm:"column:rencana_tindak_lanjut" json:"rencana_tindak_lanjut"`
	RencanaWaktuTindakLanjut *string            `gorm:"column:rencana_waktu_tindak_lanjut" json:"rencana_waktu_tindak_lanjut"`
	FileSppdLaporan          *string            `gorm:"column:file_sppd_laporan" json:"file_sppd_laporan"`
	IdUser                   *uint64            `gorm:"column:id_user" json:"id_user"`
	CreatedAt                *time.Time         `gorm:"column:created_at" json:"created_at"`
	UpdatedAt                *time.Time         `gorm:"column:updated_at" json:"updated_at"`
	Anggota                  []SppdAnggota      `gorm:"foreignKey:SppdID" json:"anggota"`
	Files                    []SppdFileLaporan  `gorm:"foreignKey:SppdID" json:"files"`
}

func (Sppd) TableName() string {
	return "sppd"
}

type SppdAnggota struct {
	ID        uint       `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	SppdID    uint       `gorm:"column:id_sppd" json:"sppd_id"`
	Nip       string     `gorm:"column:nip;index" json:"nip"`
	Nidn      string     `gorm:"column:nidn;index" json:"nidn"`
	CreatedAt *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (SppdAnggota) TableName() string {
	return "sppd_anggota"
}

type SppdFileLaporan struct {
	ID        uint       `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	SppdID    uint       `gorm:"column:id_sppd" json:"sppd_id"`
	File      string     `gorm:"column:file" json:"file"`
	Type      string     `gorm:"column:type" json:"type"` // enum('foto_kegiatan','undangan')
	CreatedAt *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (SppdFileLaporan) TableName() string {
	return "sppd_file_laporan"
}
