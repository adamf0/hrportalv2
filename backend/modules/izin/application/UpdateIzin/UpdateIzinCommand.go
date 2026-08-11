package UpdateIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/izin/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"
	"time"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type UpdateIzinCommand struct {
	ID               uint    `json:"id"`
	NamaPemohon      string  `json:"nama_pemohon"`
	Unit             string  `json:"unit"`
	Fakultas         string  `json:"fakultas"`
	Prodi            string  `json:"prodi"`
	JenisIzinID      uint    `json:"id_jenis_izin"`
	TanggalPengajuan string  `json:"tanggal_pengajuan"`
	Tujuan           string  `json:"tujuan"`
	FileLampiran     *string `json:"file_lampiran"`
	Status           string  `json:"status"`
	Catatan          *string `json:"catatan"`
	IsSdm            bool    `json:"isSdm"`
}

func (c UpdateIzinCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type UpdateIzinCommandHandler struct {
	Repo domain.IIzinRepository
}

func NewUpdateIzinCommandHandler(repo domain.IIzinRepository) *UpdateIzinCommandHandler {
	return &UpdateIzinCommandHandler{Repo: repo}
}

func (h *UpdateIzinCommandHandler) Handle(ctx context.Context, cmd *UpdateIzinCommand) (common.ResultValue[*domain.Izin], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.InvalidInput", err.Error())), nil
	}

	izin, err := h.Repo.GetByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[*domain.Izin](domain.EmptyData()), nil
	}

	now := time.Now()
	if cmd.NamaPemohon != "" {
		izin.NamaPemohon = cmd.NamaPemohon
	}
	if cmd.Unit != "" {
		izin.Unit = cmd.Unit
	}
	if cmd.Fakultas != "" {
		izin.Fakultas = cmd.Fakultas
	}
	if cmd.Prodi != "" {
		izin.Prodi = cmd.Prodi
	}
	if cmd.JenisIzinID > 0 {
		izin.JenisIzinID = int(cmd.JenisIzinID)
	}
	if cmd.TanggalPengajuan != "" {
		izin.TanggalPengajuan = cmd.TanggalPengajuan
	}
	if cmd.Tujuan != "" {
		izin.Tujuan = cmd.Tujuan
	}
	if cmd.FileLampiran != nil {
		izin.FileLampiran = cmd.FileLampiran
	}
	if cmd.Status != "" {
		izin.Status = cmd.Status
	}
	if cmd.Catatan != nil {
		izin.Catatan = cmd.Catatan
	}
	izin.UpdatedAt = &now

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

		if err := h.Repo.Update(ctxTx, izin); err != nil {
			tx.Rollback()
			return common.FailureValue[*domain.Izin](common.FailureError("Izin.UpdateFailed", err.Error())), nil
		}

		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.Izin](common.FailureError("Izin.CommitFailed", err.Error())), nil
		}
	} else {
		if err := h.Repo.Update(ctx, izin); err != nil {
			return common.FailureValue[*domain.Izin](common.FailureError("Izin.UpdateFailed", err.Error())), nil
		}
	}

	return common.SuccessValue(izin), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd UpdateIzinCommand) error {
		return cmd.Validate()
	}, "Izin.UpdateIzin.Validation")
}
