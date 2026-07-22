package GetAllMasterData

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/masterdata/domain"
)

type GetAllJenisIzinQuery struct{}

type GetAllJenisIzinQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllJenisIzinQueryHandler(repo domain.IMasterDataRepository) *GetAllJenisIzinQueryHandler {
	return &GetAllJenisIzinQueryHandler{repo: repo}
}

func (h *GetAllJenisIzinQueryHandler) Handle(ctx context.Context, query *GetAllJenisIzinQuery) (common.ResultValue[[]domain.JenisIzin], error) {
	list, err := h.repo.GetAllJenisIzin(ctx)
	if err != nil {
		return common.FailureValue[[]domain.JenisIzin](common.FailureError("MasterData.JenisIzinFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
