package DeleteCuti

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/leave/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type DeleteCutiCommand struct {
	ID uint `json:"id"`
}

func (c DeleteCutiCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type DeleteCutiCommandHandler struct {
	leaveRepo domain.ILeaveRepository
}

func NewDeleteCutiCommandHandler(leaveRepo domain.ILeaveRepository) *DeleteCutiCommandHandler {
	return &DeleteCutiCommandHandler{leaveRepo: leaveRepo}
}

func (h *DeleteCutiCommandHandler) Handle(ctx context.Context, cmd *DeleteCutiCommand) (common.ResultValue[bool], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[bool](common.FailureError("Cuti.InvalidInput", err.Error())), nil
	}

	_, err := h.leaveRepo.FindByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[bool](domain.LeaveNotFound()), nil
	}

	if err := h.leaveRepo.DeleteCuti(ctx, cmd.ID); err != nil {
		return common.FailureValue[bool](common.FailureError("Cuti.DeleteFailed", err.Error())), nil
	}

	return common.SuccessValue(true), nil
}
