package CreateAbsenUpacara

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/ceremony_attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CreateAbsenUpacaraCommand struct {
	Nip     string `json:"nip"`
	Nidn    string `json:"nidn"`
	Tanggal string `json:"tanggal"`
}

func (c CreateAbsenUpacaraCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Tanggal, validation.Required),
	)
}

type CreateAbsenUpacaraCommandHandler struct {
	repo domain.ICeremonyAttendanceRepository
}

func NewCreateAbsenUpacaraCommandHandler(repo domain.ICeremonyAttendanceRepository) *CreateAbsenUpacaraCommandHandler {
	return &CreateAbsenUpacaraCommandHandler{repo: repo}
}

func (h *CreateAbsenUpacaraCommandHandler) Handle(ctx context.Context, cmd *CreateAbsenUpacaraCommand) (common.ResultValue[*domain.AbsenUpacara], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.AbsenUpacara](common.FailureError("CeremonyAttendance.InvalidInput", err.Error())), nil
	}

	now := time.Now()
	upacara := &domain.AbsenUpacara{
		Nip:       cmd.Nip,
		Nidn:      cmd.Nidn,
		Tanggal:   cmd.Tanggal,
		CreatedAt: &now,
		UpdatedAt: &now,
	}

	if err := h.repo.Create(ctx, upacara); err != nil {
		return common.FailureValue[*domain.AbsenUpacara](common.FailureError("CeremonyAttendance.CreateFailed", err.Error())), nil
	}

	// Increment report counter
	nipVal := cmd.Nip
	if nipVal == "" {
		nipVal = cmd.Nidn
	}
	if repo := reportInfra.GetReportRepository(); repo != nil && nipVal != "" {
		_ = repo.IncrementCounter(ctx, nipVal, cmd.Nidn, now, "upacara")
	}

	return common.SuccessValue(upacara), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CreateAbsenUpacaraCommand) error {
		return cmd.Validate()
	}, "CeremonyAttendance.CreateAbsenUpacara.Validation")
}
