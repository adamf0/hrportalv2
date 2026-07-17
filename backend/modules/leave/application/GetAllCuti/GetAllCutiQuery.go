package GetAllCuti

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/leave/domain"
)

type GetAllCutiQuery struct {
	Nip  string
	Nidn string
}

type GetAllCutiQueryHandler struct {
	leaveRepo domain.ILeaveRepository
}

func NewGetAllCutiQueryHandler(leaveRepo domain.ILeaveRepository) *GetAllCutiQueryHandler {
	return &GetAllCutiQueryHandler{leaveRepo: leaveRepo}
}

func (h *GetAllCutiQueryHandler) Handle(ctx context.Context, query *GetAllCutiQuery) (common.ResultValue[[]domain.Cuti], error) {
	cutis, err := h.leaveRepo.GetHistoryByNip(ctx, query.Nip, query.Nidn)
	if err != nil {
		return common.FailureValue[[]domain.Cuti](domain.LeaveNotFound()), err
	}
	return common.SuccessValue(cutis), nil
}
