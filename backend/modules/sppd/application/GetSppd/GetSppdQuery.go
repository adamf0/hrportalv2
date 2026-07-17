package GetSppd

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/sppd/domain"
)

type GetSppdQuery struct {
	ID uint `json:"id"`
}

type GetSppdQueryHandler struct {
	sppdRepo domain.ISppdRepository
}

func NewGetSppdQueryHandler(sppdRepo domain.ISppdRepository) *GetSppdQueryHandler {
	return &GetSppdQueryHandler{sppdRepo: sppdRepo}
}

func (h *GetSppdQueryHandler) Handle(ctx context.Context, query *GetSppdQuery) (common.ResultValue[*domain.Sppd], error) {
	sppd, err := h.sppdRepo.FindByID(ctx, query.ID)
	if err != nil {
		return common.FailureValue[*domain.Sppd](domain.SppdNotFound()), err
	}

	return common.SuccessValue(sppd), nil
}
