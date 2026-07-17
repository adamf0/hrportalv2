package CreateIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/izin/domain"
	"time"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CreateIzinCommand struct {
	Nip              string `json:"nip"`
	Nidn             string `json:"nidn"`
	JenisIzinID      uint   `json:"jenis_izin_id"`
	TanggalPengajuan string `json:"tanggal_pengajuan"`
	Tujuan           string `json:"tujuan"`
}

func (c CreateIzinCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.JenisIzinID, validation.Required),
		validation.Field(&c.TanggalPengajuan, validation.Required),
		validation.Field(&c.Tujuan, validation.Required),
	)
}

type CreateIzinCommandHandler struct {
	Repo domain.IIzinRepository
}

func NewCreateIzinCommandHandler(repo domain.IIzinRepository) *CreateIzinCommandHandler {
	return &CreateIzinCommandHandler{Repo: repo}
}

func (h *CreateIzinCommandHandler) Handle(ctx context.Context, cmd *CreateIzinCommand) (common.ResultValue[*domain.Izin], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.InvalidInput", err.Error())), nil
	}

	now := time.Now()
	izin := &domain.Izin{
		Nip:              cmd.Nip,
		Nidn:             cmd.Nidn,
		JenisIzinID:      int(cmd.JenisIzinID),
		TanggalPengajuan: cmd.TanggalPengajuan,
		Tujuan:           cmd.Tujuan,
		Status:           "PENDING",
		CreatedAt:        &now,
		UpdatedAt:        &now,
	}

	if err := h.Repo.Create(ctx, izin); err != nil {
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.CreateFailed", err.Error())), nil
	}

	return common.SuccessValue(izin), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CreateIzinCommand) error {
		return cmd.Validate()
	}, "Izin.CreateIzin.Validation")
}
