package GetAllMasterData

import (
	"context"

	common "hrportal_backend_unpak/common/domain"
	"hrportal_backend_unpak/modules/masterdata/domain"
)

type GetAllPeopleQuery struct{}

type GetAllPeopleQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllPeopleQueryHandler(repo domain.IMasterDataRepository) *GetAllPeopleQueryHandler {
	return &GetAllPeopleQueryHandler{repo: repo}
}

func (h *GetAllPeopleQueryHandler) Handle(ctx context.Context, query *GetAllPeopleQuery) (common.ResultValue[[]domain.Verifikator], error) {
	list, err := h.repo.GetPepoples(ctx)
	if err != nil {
		return common.FailureValue[[]domain.Verifikator](common.FailureError("MasterData.PeopleFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
