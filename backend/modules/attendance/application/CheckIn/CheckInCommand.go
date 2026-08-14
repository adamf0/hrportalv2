package CheckIn

import (
	"context"
	"errors"
	"strings"
	"time"

	common "hrportal_backend/common/domain"
	commonhelper "hrportal_backend/common/helper"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/attendance/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"

	validation "github.com/go-ozzo/ozzo-validation/v4"
	"gorm.io/gorm"
)

type CheckInCommand struct {
	Nip         string  `json:"nip"`
	Nidn        string  `json:"nidn"`
	NamaPegawai string  `json:"nama_pegawai"`
	Unit        string  `json:"unit"`
	Fakultas    string  `json:"fakultas"`
	Prodi       string  `json:"prodi"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	Note        string  `json:"note"`
}

func (c CheckInCommand) Validate() error {
	if strings.TrimSpace(c.Nip) == "" && strings.TrimSpace(c.Nidn) == "" {
		return validation.Errors{
			"nip": errors.New("nip or nidn is required"),
		}
	}
	return nil
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

	if existing == nil {
		absen := &domain.Absen{
			Nip:            cmd.Nip,
			Nidn:           cmd.Nidn,
			NamaPegawai:    cmd.NamaPegawai,
			Unit:           cmd.Unit,
			Fakultas:       cmd.Fakultas,
			Prodi:          cmd.Prodi,
			Tanggal:        today,
			AbsenMasuk:     &now,
			Note:           cmd.Note,
			OtomatisKeluar: false,
			CreatedAt:      &now,
			UpdatedAt:      &now,
			IsCreated:      true,
		}
		if err := h.attendanceRepo.CreateAbsen(ctxTx, absen); err != nil {
			if tx != nil {
				tx.Rollback()
			}
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
		if tx != nil {
			if err := tx.Commit().Error; err != nil {
				return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
			}
		}
		return common.SuccessValue(absen), nil
	}

	existing.AbsenMasuk = &now
	existing.Note = cmd.Note
	existing.UpdatedAt = &now
	existing.IsCreated = false
	if err := h.attendanceRepo.UpdateAbsen(ctxTx, existing); err != nil {
		if tx != nil {
			tx.Rollback()
		}
		return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
	}
	if tx != nil {
		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.Absen](domain.AttendanceNotFound()), err
		}
	}
	return common.SuccessValue(existing), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CheckInCommand) error {
		return cmd.Validate()
	}, "Attendance.CheckIn.Validation")
}
