package GetAllMasterData

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/masterdata/domain"
)

type GetAllJenisCutiQuery struct{}

type GetAllJenisCutiQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllJenisCutiQueryHandler(repo domain.IMasterDataRepository) *GetAllJenisCutiQueryHandler {
	return &GetAllJenisCutiQueryHandler{repo: repo}
}

func (h *GetAllJenisCutiQueryHandler) Handle(ctx context.Context, query *GetAllJenisCutiQuery) (common.ResultValue[[]domain.JenisCuti], error) {
	list, err := h.repo.GetAllJenisCuti(ctx)
	if err != nil {
		return common.FailureValue[[]domain.JenisCuti](common.FailureError("MasterData.JenisCutiFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
