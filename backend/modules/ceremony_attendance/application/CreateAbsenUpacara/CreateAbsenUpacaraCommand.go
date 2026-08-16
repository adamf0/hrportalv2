package CreateAbsenUpacara

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/ceremony_attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
	"gorm.io/gorm"
)

type CreateAbsenUpacaraCommand struct {
	Nip      string `json:"nip"`
	Nidn     string `json:"nidn"`
	Nama     string `json:"nama"`
	Unit     string `json:"unit"`
	Fakultas string `json:"fakultas"`
	Prodi    string `json:"prodi"`
	Tanggal  string `json:"tanggal"`
}

func (c CreateAbsenUpacaraCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Tanggal, validation.Required),
	)
}

type CreateAbsenUpacaraCommandHandler struct {
	repo domain.ICeremonyAttendanceRepository
}

func NewCreateAbsenUpacaraCommandHandler(repo domain.ICeremonyAttendanceRepository) *CreateAbsenUpacaraCommandHandler {
	return &CreateAbsenUpacaraCommandHandler{repo: repo}
}

func (h *CreateAbsenUpacaraCommandHandler) Handle(ctx context.Context, cmd *CreateAbsenUpacaraCommand) (common.ResultValue[*domain.AbsenUpacara], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.AbsenUpacara](common.FailureError("CeremonyAttendance.InvalidInput", err.Error())), nil
	}

	now := time.Now()
	upacara := &domain.AbsenUpacara{
		Nip:       cmd.Nip,
		Nidn:      cmd.Nidn,
		Nama:      cmd.Nama,
		Unit:      cmd.Unit,
		Fakultas:  cmd.Fakultas,
		Prodi:     cmd.Prodi,
		Tanggal:   cmd.Tanggal,
		CreatedAt: &now,
		UpdatedAt: &now,
	}

	nipVal := cmd.Nip
	if nipVal == "" {
		nipVal = cmd.Nidn
	}

	var db *gorm.DB
	if repo := reportInfra.GetReportRepository(); repo != nil {
		db = repo.GetDB()
	}

	ctxTx := ctx
	var tx *gorm.DB
	if db != nil && nipVal != "" {
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

	if err := h.repo.Create(ctxTx, upacara); err != nil {
		if tx != nil {
			tx.Rollback()
		}
		return common.FailureValue[*domain.AbsenUpacara](common.FailureError("CeremonyAttendance.CreateFailed", err.Error())), nil
	}

	if tx != nil {
		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.AbsenUpacara](common.FailureError("CeremonyAttendance.CreateFailed", err.Error())), nil
		}
	}

	return common.SuccessValue(upacara), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CreateAbsenUpacaraCommand) error {
		return cmd.Validate()
	}, "CeremonyAttendance.CreateAbsenUpacara.Validation")
}
