package UpdateIzin

import (
	"context"
	common "hrportal_backend/common/domain"
	commonhelper "hrportal_backend/common/helper"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/izin/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"
	"time"

	validation "github.com/go-ozzo/ozzo-validation/v4"
	"gorm.io/gorm"
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
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.NotFound", "Izin tidak ditemukan")), nil
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
	if cmd.JenisIzinID != 0 {
		izin.JenisIzinID = int(cmd.JenisIzinID)
	}
	if cmd.TanggalPengajuan != "" {
		izin.TanggalPengajuan = common.FormatDateOnly(cmd.TanggalPengajuan)
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

	var db *gorm.DB
	if repo := reportInfra.GetReportRepository(); repo != nil {
		db = repo.GetDB()
	}
	if db == nil {
		db = commonhelper.GlobalFcmManager.GetDB()
	}

	ctxTx := ctx
	var tx *gorm.DB
	if db != nil {
		tx = db.Begin()
		if tx != nil && tx.Error == nil {
			defer func() {
				if r := recover(); r != nil {
					tx.Rollback()
				}
			}()
			ctxTx = context.WithValue(ctx, commoninfra.TxKey, tx)
		} else {
			tx = nil
		}
	}

	if err := h.Repo.Update(ctxTx, izin); err != nil {
		if tx != nil {
			tx.Rollback()
		}
		return common.FailureValue[*domain.Izin](common.FailureError("Izin.UpdateFailed", err.Error())), nil
	}

	if tx != nil {
		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.Izin](common.FailureError("Izin.CommitFailed", err.Error())), nil
		}
	}

	return common.SuccessValue(izin), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd UpdateIzinCommand) error {
		return cmd.Validate()
	}, "Izin.UpdateIzin.Validation")
}
