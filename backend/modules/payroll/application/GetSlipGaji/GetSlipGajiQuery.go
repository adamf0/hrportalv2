package GetSlipGaji

import (
	"context"
	"errors"
	"strconv"
	"strings"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/payroll/domain"

	"gorm.io/gorm"
)

type GetSlipGajiQuery struct {
	Tahun string `json:"tahun"`
	Bulan string `json:"bulan"`
	Nip   string `json:"nip"`
}

type GetSlipGajiQueryHandler struct {
	repo domain.IPayrollRepository
}

func NewGetSlipGajiQueryHandler(repo domain.IPayrollRepository) *GetSlipGajiQueryHandler {
	return &GetSlipGajiQueryHandler{repo: repo}
}

func (h *GetSlipGajiQueryHandler) Handle(ctx context.Context, query *GetSlipGajiQuery) (common.ResultValue[*domain.SlipGaji], error) {
	if strings.TrimSpace(query.Tahun) == "" || strings.TrimSpace(query.Bulan) == "" {
		return common.FailureValue[*domain.SlipGaji](common.FailureError("Payroll.InvalidPeriod", "tahun / bulan tidak boleh kosong")), nil
	}

	bulanNum, errBulan := strconv.Atoi(query.Bulan)
	if errBulan != nil {
		return common.FailureValue[*domain.SlipGaji](common.FailureError("Payroll.InvalidMonth", "format bulan tidak valid")), nil
	}

	nip := strings.TrimSpace(query.Nip)
	if nip == "" {
		return common.FailureValue[*domain.SlipGaji](common.FailureError("Payroll.MissingNip", "nip tidak ditemukan")), nil
	}

	namaBulanStr := domain.NamaBulan(bulanNum)
	slipGaji, err := h.repo.GetSlipGaji(ctx, query.Tahun, bulanNum, query.Bulan, namaBulanStr, nip)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return common.FailureValue[*domain.SlipGaji](common.NotFoundError("Payroll.NotFound", "slip gaji tidak ditemukan")), nil
		}
		return common.FailureValue[*domain.SlipGaji](common.FailureError("Payroll.FetchFailed", err.Error())), nil
	}

	return common.SuccessValue(slipGaji), nil
}
