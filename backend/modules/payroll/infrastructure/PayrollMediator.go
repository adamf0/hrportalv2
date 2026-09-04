package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/payroll/application/GetSlipGaji"
	"hrportal_backend/modules/payroll/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModulePayroll(db *gorm.DB, dbSimpeg *gorm.DB) error {
	repo := NewPayrollRepository(db, dbSimpeg)

	err := mediatr.RegisterRequestHandler[*GetSlipGaji.GetSlipGajiQuery, common.ResultValue[*domain.SlipGaji]](
		GetSlipGaji.NewGetSlipGajiQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	return nil
}
