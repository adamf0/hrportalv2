package DeleteSppd

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/sppd/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type DeleteSppdCommand struct {
	ID uint `json:"id"`
}

func (c DeleteSppdCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type DeleteSppdCommandHandler struct {
	sppdRepo domain.ISppdRepository
}

func NewDeleteSppdCommandHandler(sppdRepo domain.ISppdRepository) *DeleteSppdCommandHandler {
	return &DeleteSppdCommandHandler{sppdRepo: sppdRepo}
}

func (h *DeleteSppdCommandHandler) Handle(ctx context.Context, cmd *DeleteSppdCommand) (common.ResultValue[bool], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[bool](common.FailureError("Sppd.InvalidInput", err.Error())), nil
	}

	_, err := h.sppdRepo.FindByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[bool](domain.SppdNotFound()), err
	}

	if err := h.sppdRepo.DeleteSppd(ctx, cmd.ID); err != nil {
		return common.FailureValue[bool](common.FailureError("Sppd.DeleteFailed", err.Error())), nil
	}

	return common.SuccessValue(true), nil
}
