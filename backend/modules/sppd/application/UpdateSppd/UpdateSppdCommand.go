package UpdateSppd

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
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

type UpdateSppdCommand struct {
	ID                       uint                   `json:"id"`
	Nidn                     string                 `json:"nidn"`
	Nip                      string                 `json:"nip"`
	Tujuan                   string                 `json:"tujuan"`
	JenisSppdID              uint                   `json:"jenis_sppd_id"`
	TanggalBerangkat         string                 `json:"tanggal_berangkat"`
	TanggalKembali           string                 `json:"tanggal_kembali"`
	Keterangan               string                 `json:"keterangan"`
	SaranaTransportasi       *string                `json:"sarana_transportasi"`
	Verifikasi               *string                `json:"verifikasi"`
	Status                   string                 `json:"status"`
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

func (c UpdateSppdCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
		validation.Field(&c.Tujuan, validation.Required),
		validation.Field(&c.JenisSppdID, validation.Required),
		validation.Field(&c.TanggalBerangkat, validation.Required),
		validation.Field(&c.TanggalKembali, validation.Required),
	)
}

type UpdateSppdCommandHandler struct {
	sppdRepo domain.ISppdRepository
}

func NewUpdateSppdCommandHandler(sppdRepo domain.ISppdRepository) *UpdateSppdCommandHandler {
	return &UpdateSppdCommandHandler{sppdRepo: sppdRepo}
}

func (h *UpdateSppdCommandHandler) Handle(ctx context.Context, cmd *UpdateSppdCommand) (common.ResultValue[*domain.Sppd], error) {
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[*domain.Sppd](common.FailureError("Sppd.InvalidInput", err.Error())), nil
	}

	sppd, err := h.sppdRepo.FindByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[*domain.Sppd](domain.SppdNotFound()), err
	}

	now := time.Now()
	sppd.Nidn = cmd.Nidn
	sppd.Nip = cmd.Nip
	sppd.Tujuan = cmd.Tujuan
	sppd.JenisSppdID = cmd.JenisSppdID
	sppd.TanggalBerangkat = cmd.TanggalBerangkat
	sppd.TanggalKembali = cmd.TanggalKembali
	sppd.Keterangan = cmd.Keterangan
	
	if cmd.SaranaTransportasi != nil {
		sppd.SaranaTransportasi = cmd.SaranaTransportasi
	}
	if cmd.Verifikasi != nil {
		sppd.Verifikasi = cmd.Verifikasi
	}
	sppd.Status = cmd.Status
	if cmd.DokumenAnggaran != nil {
		sppd.DokumenAnggaran = cmd.DokumenAnggaran
	}
	if cmd.Catatan != nil {
		sppd.Catatan = cmd.Catatan
	}
	if cmd.Intisari != nil {
		sppd.Intisari = cmd.Intisari
	}
	if cmd.Kontribusi != nil {
		sppd.Kontribusi = cmd.Kontribusi
	}
	if cmd.RencanaTindakLanjut != nil {
		sppd.RencanaTindakLanjut = cmd.RencanaTindakLanjut
	}
	if cmd.RencanaWaktuTindakLanjut != nil {
		sppd.RencanaWaktuTindakLanjut = cmd.RencanaWaktuTindakLanjut
	}
	if cmd.FileSppdLaporan != nil {
		sppd.FileSppdLaporan = cmd.FileSppdLaporan
	}
	if cmd.IdUser != nil {
		sppd.IdUser = cmd.IdUser
	}
	sppd.UpdatedAt = &now

	// Map Anggota
	var dbAnggota []domain.SppdAnggota
	for _, a := range cmd.Anggota {
		dbAnggota = append(dbAnggota, domain.SppdAnggota{
			SppdID:    sppd.ID,
			Nip:       a.Nip,
			Nidn:      a.Nidn,
			CreatedAt: &now,
			UpdatedAt: &now,
		})
	}
	sppd.Anggota = dbAnggota

	// Map Files
	var dbFiles []domain.SppdFileLaporan
	for _, f := range cmd.Files {
		dbFiles = append(dbFiles, domain.SppdFileLaporan{
			SppdID:    sppd.ID,
			File:      f.File,
			Type:      f.Type,
			CreatedAt: &now,
			UpdatedAt: &now,
		})
	}
	sppd.Files = dbFiles

	if err := h.sppdRepo.UpdateSppd(ctx, sppd); err != nil {
		return common.FailureValue[*domain.Sppd](common.FailureError("Sppd.UpdateFailed", err.Error())), nil
	}

	return common.SuccessValue(sppd), nil
}

func init() {
	infrastructure.RegisterValidation(func(cmd UpdateSppdCommand) error {
		return cmd.Validate()
	}, "Sppd.UpdateSppd.Validation")
}
