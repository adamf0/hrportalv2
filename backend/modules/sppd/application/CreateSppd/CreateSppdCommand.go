package CreateSppd

import (
	"context"
	"strconv"
	"time"

	common "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/notification/application/CreateNotification"
	reportInfra "hrportal_backend/modules/report/infrastructure"
	"hrportal_backend/modules/sppd/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

type SppdAnggotaInput struct {
	Nip      string `json:"nip"`
	Nidn     string `json:"nidn"`
	Nama     string `json:"nama"`
	Unit     string `json:"unit"`
	Fakultas string `json:"fakultas"`
	Prodi    string `json:"prodi"`
}

type SppdFileLaporanInput struct {
	File string `json:"file"`
	Type string `json:"type"`
}

type CreateSppdCommand struct {
	Nidn                     string                 `json:"nidn"`
	Nip                      string                 `json:"nip"`
	NamaPemohon              string                 `json:"nama_pemohon"`
	Unit                     string                 `json:"unit"`
	Fakultas                 string                 `json:"fakultas"`
	Prodi                    string                 `json:"prodi"`
	Tujuan                   string                 `json:"tujuan"`
	JenisSppdID              uint                   `json:"jenis_sppd_id"`
	TanggalBerangkat         string                 `json:"tanggal_berangkat"`
	TanggalKembali           string                 `json:"tanggal_kembali"`
	Keterangan               string                 `json:"keterangan"`
	SaranaTransportasi       *string                `json:"sarana_transportasi"`
	Verifikasi               *string                `json:"verifikasi"`
	DokumenAnggaran          *string                `json:"dokumen_anggaran"`
	Catatan                  *string                `json:"catatan"`
	Intisari                 *string                `json:"intisari"`
	Kontribusi               *string                `json:"kontribusi"`
	RencanaTindakLanjut      *string                `json:"rencana_tindak_lanjut"`
	RencanaWaktuTindakLanjut *string                `json:"rencana_waktu_tindak_lanjut"`
	FileSppdLaporan          *string                `json:"file_sppd_laporan"`
	IdUser                   *uint64                `json:"id_user"`
	Anggota                  []SppdAnggotaInput     `json:"anggota"`
	Files                    []SppdFileLaporanInput `json:"files"`
}

func (c CreateSppdCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Tujuan, validation.Required),
		validation.Field(&c.JenisSppdID, validation.Required),
		validation.Field(&c.TanggalBerangkat, validation.Required),
		validation.Field(&c.TanggalKembali, validation.Required),
	)
}

type CreateSppdCommandHandler struct {
	sppdRepo domain.ISppdRepository
}

func NewCreateSppdCommandHandler(sppdRepo domain.ISppdRepository) *CreateSppdCommandHandler {
	return &CreateSppdCommandHandler{sppdRepo: sppdRepo}
}

func (h *CreateSppdCommandHandler) Handle(ctx context.Context, cmd *CreateSppdCommand) (common.ResultValue[*domain.Sppd], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.Sppd](common.FailureError("Sppd.InvalidInput", err.Error())), nil
	}

	now := time.Now()

	var dbAnggota []domain.SppdAnggota
	for _, a := range cmd.Anggota {
		nama := a.Nama
		unit := a.Unit
		fakultas := a.Fakultas
		prodi := a.Prodi

		dbAnggota = append(dbAnggota, domain.SppdAnggota{
			Nip:       a.Nip,
			Nidn:      a.Nidn,
			Nama:      nama,
			Unit:      unit,
			Fakultas:  fakultas,
			Prodi:     prodi,
			CreatedAt: &now,
			UpdatedAt: &now,
		})
	}

	var dbFiles []domain.SppdFileLaporan
	for _, f := range cmd.Files {
		dbFiles = append(dbFiles, domain.SppdFileLaporan{
			File:      f.File,
			Type:      f.Type,
			CreatedAt: &now,
			UpdatedAt: &now,
		})
	}

	sppd := &domain.Sppd{
		Nidn:                     cmd.Nidn,
		Nip:                      cmd.Nip,
		NamaPemohon:              cmd.NamaPemohon,
		Unit:                     cmd.Unit,
		Fakultas:                 cmd.Fakultas,
		Prodi:                    cmd.Prodi,
		Tujuan:                   cmd.Tujuan,
		JenisSppdID:              cmd.JenisSppdID,
		TanggalBerangkat:         common.FormatDateOnly(cmd.TanggalBerangkat),
		TanggalKembali:           common.FormatDateOnly(cmd.TanggalKembali),
		Keterangan:               cmd.Keterangan,
		SaranaTransportasi:       cmd.SaranaTransportasi,
		Verifikasi:               cmd.Verifikasi,
		Status:                   "menunggu",
		DokumenAnggaran:          cmd.DokumenAnggaran,
		Catatan:                  cmd.Catatan,
		Intisari:                 cmd.Intisari,
		Kontribusi:               cmd.Kontribusi,
		RencanaTindakLanjut:      cmd.RencanaTindakLanjut,
		RencanaWaktuTindakLanjut: cmd.RencanaWaktuTindakLanjut,
		FileSppdLaporan:          cmd.FileSppdLaporan,
		IdUser:                   cmd.IdUser,
		CreatedAt:                &now,
		UpdatedAt:                &now,
		Anggota:                  dbAnggota,
		Files:                    dbFiles,
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

	if err := h.sppdRepo.CreateSppd(ctxTx, sppd); err != nil {
		if tx != nil {
			tx.Rollback()
		}
		return common.FailureValue[*domain.Sppd](domain.SppdNotFound()), err
	}

	if tx != nil {
		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.Sppd](domain.SppdNotFound()), err
		}
	}

	if sppd.Verifikasi != nil && *sppd.Verifikasi != "" {
		targets := []string{*sppd.Verifikasi}
		title := "Pengajuan SPPD Baru"
		body := "Pegawai NIP " + sppd.Nip + " mengajukan SPPD baru. Mohon verifikasi."
		payload := map[string]string{"type": "sppd", "id": strconv.Itoa(int(sppd.ID)), "status": sppd.Status}
		_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](ctx, &CreateNotification.CreateNotificationCommand{
			TargetNips: targets,
			Title:      title,
			Body:       body,
			Type:       "sppd",
			Payload:    payload,
		})
	}

	if sppd.Nip != "" && (sppd.Verifikasi == nil || *sppd.Verifikasi != sppd.Nip) {
		titleApp := "Pengajuan SPPD Berhasil Dikirim"
		bodyApp := "Pengajuan SPPD Anda ke " + sppd.Tujuan + " (ID: " + strconv.Itoa(int(sppd.ID)) + ") telah berhasil dikirim dan menunggu verifikasi."
		payloadApp := map[string]string{"type": "sppd", "id": strconv.Itoa(int(sppd.ID)), "status": sppd.Status}
		_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](ctx, &CreateNotification.CreateNotificationCommand{
			TargetNips: []string{sppd.Nip},
			Title:      titleApp,
			Body:       bodyApp,
			Type:       "sppd",
			Payload:    payloadApp,
		})
	}

	return common.SuccessValue(sppd), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd CreateSppdCommand) error {
		return cmd.Validate()
	}, "Sppd.CreateSppd.Validation")
}
