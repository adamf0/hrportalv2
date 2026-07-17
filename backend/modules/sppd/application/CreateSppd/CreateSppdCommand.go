package CreateSppd

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	reportInfra "hrportal_backend/modules/report/infrastructure"
	"hrportal_backend/modules/sppd/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type SppdAnggotaInput struct {
	Nip  string `json:"nip"`
	Nidn string `json:"nidn"`
}

type SppdFileLaporanInput struct {
	File string `json:"file"`
	Type string `json:"type"`
}

type CreateSppdCommand struct {
	Nidn                     string                 `json:"nidn"`
	Nip                      string                 `json:"nip"`
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
		dbAnggota = append(dbAnggota, domain.SppdAnggota{
			Nip:       a.Nip,
			Nidn:      a.Nidn,
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
		Tujuan:                   cmd.Tujuan,
		JenisSppdID:              cmd.JenisSppdID,
		TanggalBerangkat:         cmd.TanggalBerangkat,
		TanggalKembali:           cmd.TanggalKembali,
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

	if err := h.sppdRepo.CreateSppd(ctx, sppd); err != nil {
		return common.FailureValue[*domain.Sppd](domain.SppdNotFound()), err
	}

	// Increment counter for report
	nipVal := cmd.Nip
	if nipVal == "" {
		nipVal = cmd.Nidn
	}

	nidnVal := cmd.Nidn
	if nidnVal == "" {
		nidnVal = cmd.Nidn
	}

	if repo := reportInfra.GetReportRepository(); repo != nil && nipVal != "" {
		_ = repo.IncrementCounter(ctx, nipVal, nidnVal, now, "sppd")
	}

	return common.SuccessValue(sppd), nil
}

func init() {
	infrastructure.RegisterValidation(func(cmd CreateSppdCommand) error {
		return cmd.Validate()
	}, "Sppd.CreateSppd.Validation")
}
