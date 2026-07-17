package GetIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/izin/domain"
)

type GetIzinQuery struct {
	ID uint `json:"id"`
}

type GetIzinQueryHandler struct {
	Repo domain.IIzinRepository
}

func NewGetIzinQueryHandler(repo domain.IIzinRepository) *GetIzinQueryHandler {
	return &GetIzinQueryHandler{Repo: repo}
}

func (h *GetIzinQueryHandler) Handle(ctx context.Context, query *GetIzinQuery) (common.ResultValue[*domain.Izin], error) {
	izin, err := h.Repo.GetByID(ctx, query.ID)
	if err != nil {
		return common.FailureValue[*domain.Izin](domain.EmptyData()), nil
	}

	return common.SuccessValue(izin), nil
}
