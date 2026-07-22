package GetAllMasterData

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/masterdata/domain"
)

type GetAllFakultasQuery struct{}

type GetAllFakultasQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllFakultasQueryHandler(repo domain.IMasterDataRepository) *GetAllFakultasQueryHandler {
	return &GetAllFakultasQueryHandler{repo: repo}
}

func (h *GetAllFakultasQueryHandler) Handle(ctx context.Context, query *GetAllFakultasQuery) (common.ResultValue[[]domain.Fakultas], error) {
	list, err := h.repo.GetAllFakultas(ctx)
	if err != nil {
		return common.FailureValue[[]domain.Fakultas](common.FailureError("MasterData.FakultasFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
