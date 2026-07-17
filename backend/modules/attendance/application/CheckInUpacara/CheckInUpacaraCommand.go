package CheckInUpacara

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CheckInUpacaraCommand struct {
	Nip  string `json:"nip"`
	Nidn string `json:"nidn"`
}

func (c CheckInUpacaraCommand) Validate() error {
	return validation.ValidateStruct(&c) // validation.Field(&c.Nip, validation.Required),

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

	if repo := reportInfra.GetReportRepository(); repo != nil {
		_ = repo.IncrementCounter(ctx, cmd.Nip, cmd.Nidn, now, "upacara")
	}

	return common.SuccessValue(upacara), nil
}

func init() {
	infrastructure.RegisterValidation(func(cmd CheckInUpacaraCommand) error {
		return cmd.Validate()
	}, "Attendance.CheckInUpacara.Validation")
}
