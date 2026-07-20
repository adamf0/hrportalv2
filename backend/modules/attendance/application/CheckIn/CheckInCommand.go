package CheckIn

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CheckInCommand struct {
	Nip       string  `json:"nip"`
	Nidn      string  `json:"nidn"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Note      string  `json:"note"`
}

func (c CheckInCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Nip, validation.Required),
	)
}

type CheckInCommandHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewCheckInCommandHandler(repo domain.IAttendanceRepository) *CheckInCommandHandler {
	return &CheckInCommandHandler{attendanceRepo: repo}
}

func (h *CheckInCommandHandler) Handle(ctx context.Context, cmd *CheckInCommand) (common.ResultValue[*domain.Absen], error) {
	today := time.Now().Format("2006-01-02")
	existing, _ := h.attendanceRepo.FindByNipAndTanggal(ctx, cmd.Nip, cmd.Nidn, today)
	if existing != nil && existing.AbsenMasuk != nil {
		return common.FailureValue[*domain.Absen](domain.AlreadyCheckedIn()), nil
	}

	now := time.Now()
	repo := reportInfra.GetReportRepository()
	if repo != nil {
		db := repo.GetDB()
		tx := db.Begin()
		defer func() {
			if r := recover(); r != nil {
				tx.Rollback()
			}
		}()
		ctxTx := context.WithValue(ctx, commoninfra.TxKey, tx)

		if existing == nil {
			absen := &domain.Absen{
				Nip:            cmd.Nip,
				Nidn:           cmd.Nidn,
				Tanggal:        today,
				AbsenMasuk:     &now,
				Note:           cmd.Note,
				OtomatisKeluar: false,
				CreatedAt:      &now,
				UpdatedAt:      &now,
			}
			if err := h.attendanceRepo.CreateAbsen(ctxTx, absen); err != nil {
				tx.Rollback()
				return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
			}
			if err := repo.IncrementCounter(ctxTx, cmd.Nip, cmd.Nidn, now, "masuk"); err != nil {
				tx.Rollback()
				return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
			}
			if err := tx.Commit().Error; err != nil {
				return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
			}
			return common.SuccessValue(absen), nil
		}

		existing.AbsenMasuk = &now
		existing.Note = cmd.Note
		existing.UpdatedAt = &now
		if err := h.attendanceRepo.UpdateAbsen(ctxTx, existing); err != nil {
			tx.Rollback()
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
		if err := repo.IncrementCounter(ctxTx, cmd.Nip, cmd.Nidn, now, "masuk"); err != nil {
			tx.Rollback()
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
		return common.SuccessValue(existing), nil
	}

	// Fallback if report repository is nil (should not happen in production)
	if existing == nil {
		absen := &domain.Absen{
			Nip:            cmd.Nip,
			Nidn:           cmd.Nidn,
			Tanggal:        today,
			AbsenMasuk:     &now,
			Note:           cmd.Note,
			OtomatisKeluar: false,
			CreatedAt:      &now,
			UpdatedAt:      &now,
		}
		if err := h.attendanceRepo.CreateAbsen(ctx, absen); err != nil {
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
		return common.SuccessValue(absen), nil
	}

	existing.AbsenMasuk = &now
	existing.UpdatedAt = &now
	if err := h.attendanceRepo.UpdateAbsen(ctx, existing); err != nil {
		return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
	}
	return common.SuccessValue(existing), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CheckInCommand) error {
		return cmd.Validate()
	}, "Attendance.CheckIn.Validation")
}
