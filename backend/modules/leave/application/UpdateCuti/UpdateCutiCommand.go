package UpdateCuti

import (
	"context"
	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/leave/domain"
	"time"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type UpdateCutiCommand struct {
	ID             uint    `json:"id"`
	JenisCutiID    uint    `json:"jenis_cuti_id"`
	TanggalMulai   string  `json:"tanggal_mulai"`
	TanggalSelesai string  `json:"tanggal_selesai"`
	JumlahHari     int     `json:"jumlah_hari"`
	Alasan         string  `json:"alasan"`
	FileLampiran   *string `json:"file_lampiran"`
	Status         string  `json:"status"`
	CatatanAtasan  *string `json:"catatan_atasan"`
}

func (c UpdateCutiCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
		validation.Field(&c.JenisCutiID, validation.Required),
		validation.Field(&c.TanggalMulai, validation.Required),
		validation.Field(&c.TanggalSelesai, validation.Required),
		validation.Field(&c.JumlahHari, validation.Required),
		validation.Field(&c.Alasan, validation.Required),
		validation.Field(&c.Status, validation.Required),
	)
}

type UpdateCutiCommandHandler struct {
	leaveRepo domain.ILeaveRepository
}

func NewUpdateCutiCommandHandler(leaveRepo domain.ILeaveRepository) *UpdateCutiCommandHandler {
	return &UpdateCutiCommandHandler{leaveRepo: leaveRepo}
}

func (h *UpdateCutiCommandHandler) Handle(ctx context.Context, cmd *UpdateCutiCommand) (common.ResultValue[*domain.Cuti], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.Cuti](common.FailureError("Cuti.InvalidInput", err.Error())), nil
	}

	cuti, err := h.leaveRepo.FindByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[*domain.Cuti](domain.LeaveNotFound()), nil
	}

	now := time.Now()
	cuti.JenisCutiID = cmd.JenisCutiID
	cuti.TanggalMulai = cmd.TanggalMulai
	cuti.TanggalSelesai = cmd.TanggalSelesai
	cuti.JumlahHari = cmd.JumlahHari
	cuti.Alasan = cmd.Alasan
	if cmd.FileLampiran != nil {
		cuti.FileLampiran = cmd.FileLampiran
	}
	cuti.Status = cmd.Status
	if cmd.CatatanAtasan != nil {
		cuti.CatatanAtasan = cmd.CatatanAtasan
	}
	cuti.UpdatedAt = &now

	if err := h.leaveRepo.UpdateCuti(ctx, cuti); err != nil {
		return common.FailureValue[*domain.Cuti](common.FailureError("Cuti.UpdateFailed", err.Error())), nil
	}

	return common.SuccessValue(cuti), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd UpdateCutiCommand) error {
		return cmd.Validate()
	}, "Leave.UpdateCuti.Validation")
}
