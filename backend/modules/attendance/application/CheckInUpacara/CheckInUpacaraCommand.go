package CheckInUpacara

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CheckInUpacaraCommand struct {
	Nip  string `json:"nip"`
	Nidn string `json:"nidn"`
}

func (c CheckInUpacaraCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Nip, validation.Required),
	)
}

type CheckInUpacaraCommandHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewCheckInUpacaraCommandHandler(attendanceRepo domain.IAttendanceRepository) *CheckInUpacaraCommandHandler {
	return &CheckInUpacaraCommandHandler{attendanceRepo: attendanceRepo}
}

func (h *CheckInUpacaraCommandHandler) Handle(ctx context.Context, cmd *CheckInUpacaraCommand) (common.ResultValue[*domain.AbsenUpacara], error) {
	today := time.Now().Format("2006-01-02")
	existing, _ := h.attendanceRepo.FindByNipAndTanggalUpacara(ctx, cmd.Nip, cmd.Nidn, today)
	if existing != nil {
		return common.FailureValue[*domain.AbsenUpacara](domain.AlreadyCheckedIn()), nil
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

		upacara := &domain.AbsenUpacara{
			Nip:       cmd.Nip,
			Nidn:      cmd.Nidn,
			Tanggal:   today,
			CreatedAt: &now,
			UpdatedAt: &now,
		}

		if err := h.attendanceRepo.CreateAbsenUpacara(ctxTx, upacara); err != nil {
			tx.Rollback()
			return common.FailureValue[*domain.AbsenUpacara](domain.AttendanceNotFound()), err
		}

		if err := repo.IncrementCounter(ctxTx, cmd.Nip, cmd.Nidn, now, "upacara"); err != nil {
			tx.Rollback()
			return common.FailureValue[*domain.AbsenUpacara](domain.AttendanceNotFound()), err
		}

		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.AbsenUpacara](domain.AttendanceNotFound()), err
		}

		return common.SuccessValue(upacara), nil
	}

	// Fallback if report repository is nil (should not happen in production)
	upacara := &domain.AbsenUpacara{
		Nip:       cmd.Nip,
		Nidn:      cmd.Nidn,
		Tanggal:   today,
		CreatedAt: &now,
		UpdatedAt: &now,
	}

	if err := h.attendanceRepo.CreateAbsenUpacara(ctx, upacara); err != nil {
		return common.FailureValue[*domain.AbsenUpacara](domain.AttendanceNotFound()), err
	}

	return common.SuccessValue(upacara), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CheckInUpacaraCommand) error {
		return cmd.Validate()
	}, "Attendance.CheckInUpacara.Validation")
}
