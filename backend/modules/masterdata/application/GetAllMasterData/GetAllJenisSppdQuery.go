package GetAllMasterData

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/masterdata/domain"
)

type GetAllJenisSppdQuery struct{}

type GetAllJenisSppdQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllJenisSppdQueryHandler(repo domain.IMasterDataRepository) *GetAllJenisSppdQueryHandler {
	return &GetAllJenisSppdQueryHandler{repo: repo}
}

func (h *GetAllJenisSppdQueryHandler) Handle(ctx context.Context, query *GetAllJenisSppdQuery) (common.ResultValue[[]domain.JenisSppd], error) {
	list, err := h.repo.GetAllJenisSppd(ctx)
	if err != nil {
		return common.FailureValue[[]domain.JenisSppd](common.FailureError("MasterData.JenisSppdFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
