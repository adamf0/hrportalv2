package CreateIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/izin/domain"
	"hrportal_backend/modules/notification/application/CreateNotification"
	"strconv"
	"time"

	validation "github.com/go-ozzo/ozzo-validation/v4"
	"github.com/mehdihadeli/go-mediatr"
)

type CreateIzinCommand struct {
	Nip              string  `json:"nip"`
	Nidn             string  `json:"nidn"`
	NamaPemohon      string  `json:"nama_pemohon"`
	Unit             string  `json:"unit"`
	Fakultas         string  `json:"fakultas"`
	Prodi            string  `json:"prodi"`
	JenisIzinID      uint    `json:"id_jenis_izin"`
	TanggalPengajuan string  `json:"tanggal_pengajuan"`
	Tujuan           string  `json:"tujuan"`
	FileLampiran     *string `json:"file_lampiran"`
	Verifikasi       *string `json:"verifikasi"`
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
		NamaPemohon:      cmd.NamaPemohon,
		Unit:             cmd.Unit,
		Fakultas:         cmd.Fakultas,
		Prodi:            cmd.Prodi,
		JenisIzinID:      int(cmd.JenisIzinID),
		TanggalPengajuan: cmd.TanggalPengajuan,
		Tujuan:           cmd.Tujuan,
		FileLampiran:     cmd.FileLampiran,
		Verifikasi:       cmd.Verifikasi,
		Status:           "menunggu",
		CreatedAt:        &now,
		UpdatedAt:        &now,
	}

	if err := h.Repo.Create(ctx, izin); err != nil {
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.CreateFailed", err.Error())), nil
	}

	targets := []string{*izin.Verifikasi}
	title := "Pengajuan Izin Baru"
	body := "Pegawai NIP " + izin.Nip + " mengajukan Izin baru. Mohon verifikasi."
	payload := map[string]string{"type": "izin", "id": strconv.Itoa(int(izin.ID)), "status": izin.Status}
	_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](ctx, &CreateNotification.CreateNotificationCommand{
		TargetNips: targets,
		Title:      title,
		Body:       body,
		Type:       "izin",
		Payload:    payload,
	})

	return common.SuccessValue(izin), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CreateIzinCommand) error {
		return cmd.Validate()
	}, "Izin.CreateIzin.Validation")
}
