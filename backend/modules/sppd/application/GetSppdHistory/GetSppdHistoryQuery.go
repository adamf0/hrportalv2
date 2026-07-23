package GetSppdHistory

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/sppd/domain"
)

type GetSppdHistoryQuery struct {
	Nip          string
	Nidn         string
	Verifikasi   bool
	IsSdm        bool
	TanggalMulai *string
	TanggalAkhir *string
}

type GetSppdHistoryQueryHandler struct {
	sppdRepo domain.ISppdRepository
}

func NewGetSppdHistoryQueryHandler(sppdRepo domain.ISppdRepository) *GetSppdHistoryQueryHandler {
	return &GetSppdHistoryQueryHandler{sppdRepo: sppdRepo}
}

func (h *GetSppdHistoryQueryHandler) Handle(ctx context.Context, query *GetSppdHistoryQuery) (common.ResultValue[[]domain.Sppd], error) {
	paged, err := h.sppdRepo.GetHistoryByNip(ctx, query.Nip, query.Nidn, query.Verifikasi, query.IsSdm, query.TanggalMulai, query.TanggalAkhir)
	if err != nil {
		return common.FailureValue[[]domain.Sppd](domain.SppdNotFound()), err
	}
	return common.SuccessValue(paged), nil
}
