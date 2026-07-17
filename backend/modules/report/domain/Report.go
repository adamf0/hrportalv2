package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type PeriodeType string

const (
	PeriodeCalendar PeriodeType = "CALENDAR"
	PeriodeCutoff   PeriodeType = "CUTOFF"
)

type RekapLaporanBulanan struct {
	common.Entity
	ID           uint        `gorm:"primaryKey;autoIncrement" json:"id"`
	Nip          string      `gorm:"column:nip;type:varchar(100);not null;default:'';uniqueIndex:rekap_emp_periode_IDX,priority:1" json:"nip"`
	Nidn         string      `gorm:"column:nidn;type:varchar(100);not null;default:'';uniqueIndex:rekap_emp_periode_IDX,priority:2" json:"nidn"`
	PeriodeType  PeriodeType `gorm:"column:periode_type;type:varchar(50);not null;default:'CALENDAR';uniqueIndex:rekap_emp_periode_IDX,priority:3" json:"periode_type"`
	PeriodeKey   string      `gorm:"column:periode_key;type:varchar(50);not null;default:'';uniqueIndex:rekap_emp_periode_IDX,priority:4" json:"periode_key"`
	TanggalMulai string      `gorm:"column:tanggal_mulai;type:date;not null" json:"tanggal_mulai"`
	TanggalAkhir string      `gorm:"column:tanggal_akhir;type:date;not null" json:"tanggal_akhir"`
	TotalMasuk   int         `gorm:"column:total_masuk;not null;default:0" json:"total_masuk"`
	TotalIzin    int         `gorm:"column:total_izin;not null;default:0" json:"total_izin"`
	TotalCuti    int         `gorm:"column:total_cuti;not null;default:0" json:"total_cuti"`
	TotalSppd    int         `gorm:"column:total_sppd;not null;default:0" json:"total_sppd"`
	TotalUpacara int         `gorm:"column:total_upacara;not null;default:0" json:"total_upacara"`
	UpdatedAt    *time.Time  `gorm:"column:updated_at" json:"updated_at"`
}

func (RekapLaporanBulanan) TableName() string {
	return "rekap_laporan_bulanan"
}

type RecordItem struct {
	ID      uint                   `json:"id"`
	Tanggal string                 `json:"tanggal"`
	Type    string                 `json:"type"`
	Info    map[string]interface{} `json:"info"`
}

type LaporanPenggunaMerged struct {
	Kode     string       `json:"kode"`
	Pengguna interface{}  `json:"pengguna"`
	Type     string       `json:"type"`
	Records  []RecordItem `json:"records"`
}

type FlatRecordItem struct {
	ID       uint                   `json:"id"`
	Tanggal  string                 `json:"tanggal"`
	Type     string                 `json:"type"`
	Info     map[string]interface{} `json:"info"`
	Pengguna interface{}            `json:"pengguna"`
}
