package DeleteIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/izin/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type DeleteIzinCommand struct {
	ID uint `json:"id"`
}

func (c DeleteIzinCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type DeleteIzinCommandHandler struct {
	Repo domain.IIzinRepository
}

func NewDeleteIzinCommandHandler(repo domain.IIzinRepository) *DeleteIzinCommandHandler {
	return &DeleteIzinCommandHandler{Repo: repo}
}

func (h *DeleteIzinCommandHandler) Handle(ctx context.Context, cmd *DeleteIzinCommand) (common.ResultValue[bool], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[bool](common.FailureError("Izin.InvalidInput", err.Error())), nil
	}

	// Verify it exists
	_, err := h.Repo.GetByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[bool](domain.EmptyData()), nil
	}

	if err := h.Repo.Delete(ctx, cmd.ID); err != nil {
		return common.FailureValue[bool](common.FailureError("Izin.DeleteFailed", err.Error())), nil
	}

	return common.SuccessValue(true), nil
}
