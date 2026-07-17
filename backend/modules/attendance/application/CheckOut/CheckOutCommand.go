package CheckOut

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/attendance/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type CheckOutCommand struct {
	Nip  string `json:"nip"`
	Nidn string `json:"nidn"`
}

func (c CheckOutCommand) Validate() error {
	return validation.ValidateStruct(&c) // validation.Field(&c.Nip, validation.Required),

}

type CheckOutCommandHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewCheckOutCommandHandler(attendanceRepo domain.IAttendanceRepository) *CheckOutCommandHandler {
	return &CheckOutCommandHandler{attendanceRepo: attendanceRepo}
}

func (h *CheckOutCommandHandler) Handle(ctx context.Context, cmd *CheckOutCommand) (common.ResultValue[*domain.Absen], error) {
	today := time.Now().Format("2006-01-02")
	existing, _ := h.attendanceRepo.FindByNipAndTanggal(ctx, cmd.Nip, cmd.Nidn, today)
	if existing == nil {
		return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), nil
	}

	now := time.Now()
	existing.AbsenKeluar = &now
	existing.UpdatedAt = &now

	if err := h.attendanceRepo.UpdateAbsen(ctx, existing); err != nil {
		return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
	}

	return common.SuccessValue(existing), nil
}

func init() {
	infrastructure.RegisterValidation(func(cmd CheckOutCommand) error {
		return cmd.Validate()
	}, "Attendance.CheckOut.Validation")
}
