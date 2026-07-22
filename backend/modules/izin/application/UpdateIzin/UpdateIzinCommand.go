package UpdateIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/izin/domain"
	"time"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type UpdateIzinCommand struct {
	ID               uint    `json:"id"`
	JenisIzinID      uint    `json:"id_jenis_izin"`
	TanggalPengajuan string  `json:"tanggal_pengajuan"`
	Tujuan           string  `json:"tujuan"`
	Status           string  `json:"status"`
	Catatan          *string `json:"catatan"`
}

func (c UpdateIzinCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type UpdateIzinCommandHandler struct {
	Repo domain.IIzinRepository
}

func NewUpdateIzinCommandHandler(repo domain.IIzinRepository) *UpdateIzinCommandHandler {
	return &UpdateIzinCommandHandler{Repo: repo}
}

func (h *UpdateIzinCommandHandler) Handle(ctx context.Context, cmd *UpdateIzinCommand) (common.ResultValue[*domain.Izin], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.InvalidInput", err.Error())), nil
	}

	izin, err := h.Repo.GetByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[*domain.Izin](domain.EmptyData()), nil
	}

	now := time.Now()
	if cmd.JenisIzinID > 0 {
		izin.JenisIzinID = int(cmd.JenisIzinID)
	}
	if cmd.TanggalPengajuan != "" {
		izin.TanggalPengajuan = cmd.TanggalPengajuan
	}
	if cmd.Tujuan != "" {
		izin.Tujuan = cmd.Tujuan
	}
	if cmd.Status != "" {
		izin.Status = cmd.Status
	}
	if cmd.Catatan != nil {
		izin.Catatan = cmd.Catatan
	}
	izin.UpdatedAt = &now

	if err := h.Repo.Update(ctx, izin); err != nil {
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.UpdateFailed", err.Error())), nil
	}

	return common.SuccessValue(izin), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd UpdateIzinCommand) error {
		return cmd.Validate()
	}, "Izin.UpdateIzin.Validation")
}
