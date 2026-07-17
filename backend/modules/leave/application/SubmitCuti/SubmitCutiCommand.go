package SubmitCuti

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/leave/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type SubmitCutiCommand struct {
	Nip            string  `json:"nip"`
	Nidn           string  `json:"nidn"`
	JenisCutiID    uint    `json:"jenis_cuti_id"`
	TanggalMulai   string  `json:"tanggal_mulai"`
	TanggalSelesai string  `json:"tanggal_selesai"`
	JumlahHari     int     `json:"jumlah_hari"`
	Alasan         string  `json:"alasan"`
	NipAtasan      *string `json:"nip_atasan"`
	FileLampiran   *string `json:"file_lampiran"`
}

func (c SubmitCutiCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.JenisCutiID, validation.Required),
		validation.Field(&c.TanggalMulai, validation.Required),
		validation.Field(&c.TanggalSelesai, validation.Required),
		validation.Field(&c.Alasan, validation.Required),
	)
}

type SubmitCutiCommandHandler struct {
	leaveRepo domain.ILeaveRepository
}

func NewSubmitCutiCommandHandler(leaveRepo domain.ILeaveRepository) *SubmitCutiCommandHandler {
	return &SubmitCutiCommandHandler{leaveRepo: leaveRepo}
}

func (h *SubmitCutiCommandHandler) Handle(ctx context.Context, cmd *SubmitCutiCommand) (common.ResultValue[*domain.Cuti], error) {
	now := time.Now()
	cuti := &domain.Cuti{
		Nip:            cmd.Nip,
		Nidn:           cmd.Nidn,
		JenisCutiID:    cmd.JenisCutiID,
		TanggalMulai:   cmd.TanggalMulai,
		TanggalSelesai: cmd.TanggalSelesai,
		JumlahHari:     cmd.JumlahHari,
		Alasan:         cmd.Alasan,
		NipAtasan:      cmd.NipAtasan,
		FileLampiran:   cmd.FileLampiran,
		Status:         "menunggu",
		CreatedAt:      &now,
		UpdatedAt:      &now,
	}

	if err := h.leaveRepo.CreateCuti(ctx, cuti); err != nil {
		return common.FailureValue[*domain.Cuti](domain.LeaveNotFound()), err
	}

	if repo := reportInfra.GetReportRepository(); repo != nil {
		_ = repo.IncrementCounter(ctx, cmd.Nip, cmd.Nidn, now, "cuti")
	}

	return common.SuccessValue(cuti), nil
}

func init() {
	infrastructure.RegisterValidation(func(cmd SubmitCutiCommand) error {
		return cmd.Validate()
	}, "Leave.SubmitCuti.Validation")
}
