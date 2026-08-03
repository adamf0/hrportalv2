package GetAllMasterData

import (
	"context"

	common "hrportal_backend_unpak/common/domain"
	"hrportal_backend_unpak/modules/masterdata/domain"
)

type GetAllProdiQuery struct{}

type GetAllProdiQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllProdiQueryHandler(repo domain.IMasterDataRepository) *GetAllProdiQueryHandler {
	return &GetAllProdiQueryHandler{repo: repo}
}

func (h *GetAllProdiQueryHandler) Handle(ctx context.Context, query *GetAllProdiQuery) (common.ResultValue[[]domain.Prodi], error) {
	list, err := h.repo.GetAllProdi(ctx)
	if err != nil {
		return common.FailureValue[[]domain.Prodi](common.FailureError("MasterData.ProdiFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
