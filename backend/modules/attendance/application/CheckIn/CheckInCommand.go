package CheckIn

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CheckInCommand struct {
	Nip       string  `json:"nip"`
	Nidn      string  `json:"nidn"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func (c CheckInCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Nip, validation.Required),
	)
}

type CheckInCommandHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewCheckInCommandHandler(attendanceRepo domain.IAttendanceRepository) *CheckInCommandHandler {
	return &CheckInCommandHandler{attendanceRepo: attendanceRepo}
}

func (h *CheckInCommandHandler) Handle(ctx context.Context, cmd *CheckInCommand) (common.ResultValue[*domain.Absen], error) {
	today := time.Now().Format("2006-01-02")
	existing, _ := h.attendanceRepo.FindByNipAndTanggal(ctx, cmd.Nip, cmd.Nidn, today)
	if existing != nil && existing.AbsenMasuk != nil {
		return common.FailureValue[*domain.Absen](domain.AlreadyCheckedIn()), nil
	}

	now := time.Now()
	if existing == nil {
		absen := &domain.Absen{
			Nip:            cmd.Nip,
			Nidn:           cmd.Nidn,
			Tanggal:        today,
			AbsenMasuk:     &now,
			OtomatisKeluar: false,
			CreatedAt:      &now,
			UpdatedAt:      &now,
		}
		if err := h.attendanceRepo.CreateAbsen(ctx, absen); err != nil {
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
		if repo := reportInfra.GetReportRepository(); repo != nil {
			_ = repo.IncrementCounter(ctx, cmd.Nip, cmd.Nidn, now, "masuk")
		}
		return common.SuccessValue(absen), nil
	}

	existing.AbsenMasuk = &now
	existing.UpdatedAt = &now
	if err := h.attendanceRepo.UpdateAbsen(ctx, existing); err != nil {
		return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
	}

	if repo := reportInfra.GetReportRepository(); repo != nil {
		_ = repo.IncrementCounter(ctx, cmd.Nip, cmd.Nidn, now, "masuk")
	}

	return common.SuccessValue(existing), nil
}

func init() {
	infrastructure.RegisterValidation(func(cmd CheckInCommand) error {
		return cmd.Validate()
	}, "Attendance.CheckIn.Validation")
}
