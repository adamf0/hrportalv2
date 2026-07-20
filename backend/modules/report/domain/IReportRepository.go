package domain

import (
	"context"
	"time"

	"gorm.io/gorm"
)

type IReportRepository interface {
	GetDB() *gorm.DB
	IncrementCounter(ctx context.Context, nip string, nidn string, date time.Time, counterType string) error
	GetReportSummary(ctx context.Context, nip string, periodeType PeriodeType, periodeKey string) (*RekapLaporanBulanan, error)
	GetAllLaporanAbsen(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string) (map[string]interface{}, error)
	GetLaporanMergedParallel(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string, userType string) ([]LaporanPenggunaMerged, error)
	GetFlatLaporanMergedParallel(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string, userType string) ([]FlatRecordItem, error)
	CalculateReport(ctx context.Context) (map[string]interface{}, error)
}
