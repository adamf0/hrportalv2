package infrastructure

import (
	"context"
	"hrportal_backend/modules/payroll/domain"

	"gorm.io/gorm"
)

type PayrollRepository struct {
	db       *gorm.DB
	dbSimpeg *gorm.DB
}

func NewPayrollRepository(db *gorm.DB, dbSimpeg *gorm.DB) domain.IPayrollRepository {
	return &PayrollRepository{
		db:       db,
		dbSimpeg: dbSimpeg,
	}
}

func (r *PayrollRepository) GetSlipGaji(ctx context.Context, tahunStr string, bulanNum int, bulanStr string, namaBulanStr string, nip string) (*domain.SlipGaji, error) {
	targetDB := r.db
	if r.dbSimpeg != nil {
		targetDB = r.dbSimpeg
	}

	var slipGaji domain.SlipGaji
	err := targetDB.WithContext(ctx).Table("payroll_publishb").
		Where("tahun = ?", tahunStr).
		Where("(bulan = ? OR bulan = ? OR bulan = ?)", bulanNum, bulanStr, namaBulanStr).
		Where("(TRIM(nip) = ? OR nip = ?)", nip, nip).
		First(&slipGaji).Error

	if err != nil {
		return nil, err
	}

	if namaBulanStr != "" {
		slipGaji.Bulan = namaBulanStr
	}

	return &slipGaji, nil
}
