package DeleteAbsenUpacara

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/ceremony_attendance/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type DeleteAbsenUpacaraCommand struct {
	ID uint `json:"id"`
}

func (c DeleteAbsenUpacaraCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type DeleteAbsenUpacaraCommandHandler struct {
	repo domain.ICeremonyAttendanceRepository
}

func NewDeleteAbsenUpacaraCommandHandler(repo domain.ICeremonyAttendanceRepository) *DeleteAbsenUpacaraCommandHandler {
	return &DeleteAbsenUpacaraCommandHandler{repo: repo}
}

func (h *DeleteAbsenUpacaraCommandHandler) Handle(ctx context.Context, cmd *DeleteAbsenUpacaraCommand) (common.ResultValue[bool], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[bool](common.FailureError("CeremonyAttendance.InvalidInput", err.Error())), nil
	}

	_, err := h.repo.GetByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[bool](domain.UpacaraNotFound()), nil
	}

	if err := h.repo.Delete(ctx, cmd.ID); err != nil {
		return common.FailureValue[bool](common.FailureError("CeremonyAttendance.DeleteFailed", err.Error())), nil
	}

	return common.SuccessValue(true), nil
}
