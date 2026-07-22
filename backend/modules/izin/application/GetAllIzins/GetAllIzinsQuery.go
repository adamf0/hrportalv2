package GetAllIzins

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/izin/domain"
)

type GetAllIzinsQuery struct {
	Nip   string `json:"nip"`
	Nidn  string `json:"nidn"`
	IsSdm bool   `json:"is_sdm"`
}

type GetAllIzinsQueryHandler struct {
	Repo domain.IIzinRepository
}

func NewGetAllIzinsQueryHandler(repo domain.IIzinRepository) *GetAllIzinsQueryHandler {
	return &GetAllIzinsQueryHandler{Repo: repo}
}

func (h *GetAllIzinsQueryHandler) Handle(ctx context.Context, query *GetAllIzinsQuery) (common.ResultValue[[]domain.Izin], error) {
	izins, err := h.Repo.GetAll(ctx, query.Nip, query.Nidn, query.IsSdm)
	if err != nil {
		return common.FailureValue[[]domain.Izin](common.FailureError("Izin.FetchFailed", err.Error())), nil
	}

	return common.SuccessValue(izins), nil
}
