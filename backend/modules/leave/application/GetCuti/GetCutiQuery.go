package GetCuti

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/leave/domain"
)

type GetCutiQuery struct {
	ID uint `json:"id"`
}

type GetCutiQueryHandler struct {
	leaveRepo domain.ILeaveRepository
}

func NewGetCutiQueryHandler(leaveRepo domain.ILeaveRepository) *GetCutiQueryHandler {
	return &GetCutiQueryHandler{leaveRepo: leaveRepo}
}

func (h *GetCutiQueryHandler) Handle(ctx context.Context, query *GetCutiQuery) (common.ResultValue[*domain.Cuti], error) {
	cuti, err := h.leaveRepo.FindByID(ctx, query.ID)
	if err != nil {
		return common.FailureValue[*domain.Cuti](domain.LeaveNotFound()), err
	}
	return common.SuccessValue(cuti), nil
}
