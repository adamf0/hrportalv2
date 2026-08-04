package GetAllMasterData

import (
	"context"

	common "hrportal_backend_unpak/common/domain"
	"hrportal_backend_unpak/modules/masterdata/domain"
)

type GetAllVerifikatorQuery struct{}

type GetAllVerifikatorQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllVerifikatorQueryHandler(repo domain.IMasterDataRepository) *GetAllVerifikatorQueryHandler {
	return &GetAllVerifikatorQueryHandler{repo: repo}
}

func (h *GetAllVerifikatorQueryHandler) Handle(ctx context.Context, query *GetAllVerifikatorQuery) (common.ResultValue[[]domain.Verifikator], error) {
	list, err := h.repo.GetVerifikators(ctx)
	if err != nil {
		return common.FailureValue[[]domain.Verifikator](common.FailureError("MasterData.VerifikatorFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
