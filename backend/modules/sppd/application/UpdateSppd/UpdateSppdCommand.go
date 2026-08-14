package UpdateSppd

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
	commonhelper "hrportal_backend/common/helper"
	commoninfra "hrportal_backend/common/infrastructure"
	reportInfra "hrportal_backend/modules/report/infrastructure"
	"hrportal_backend/modules/sppd/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
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

type UpdateSppdCommand struct {
	ID                       uint                   `json:"id"`
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
	IsSdm                    bool                   `json:"isSdm"`
}

func (c UpdateSppdCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.ID, validation.Required),
	)
}

type UpdateSppdCommandHandler struct {
	sppdRepo domain.ISppdRepository
}

func NewUpdateSppdCommandHandler(sppdRepo domain.ISppdRepository) *UpdateSppdCommandHandler {
	return &UpdateSppdCommandHandler{sppdRepo: sppdRepo}
}

func (h *UpdateSppdCommandHandler) Handle(ctx context.Context, cmd *UpdateSppdCommand) (common.ResultValue[*domain.Sppd], error) {
	sppd, err := h.sppdRepo.FindByID(ctx, cmd.ID)
	if err != nil {
		return common.FailureValue[*domain.Sppd](common.FailureError("Sppd.NotFound", "SPPD tidak ditemukan")), nil
	}

	now := time.Now()
	if cmd.Nidn != "" {
		sppd.Nidn = cmd.Nidn
	}
	if cmd.Nip != "" {
		sppd.Nip = cmd.Nip
	}
	if cmd.NamaPemohon != "" {
		sppd.NamaPemohon = cmd.NamaPemohon
	}
	if cmd.Unit != "" {
		sppd.Unit = cmd.Unit
	}
	if cmd.Fakultas != "" {
		sppd.Fakultas = cmd.Fakultas
	}
	if cmd.Prodi != "" {
		sppd.Prodi = cmd.Prodi
	}
	if cmd.Tujuan != "" {
		sppd.Tujuan = cmd.Tujuan
	}
	if cmd.JenisSppdID != 0 {
		sppd.JenisSppdID = cmd.JenisSppdID
	}
	if cmd.TanggalBerangkat != "" {
		sppd.TanggalBerangkat = common.FormatDateOnly(cmd.TanggalBerangkat)
	}
	if cmd.TanggalKembali != "" {
		sppd.TanggalKembali = common.FormatDateOnly(cmd.TanggalKembali)
	}
	if cmd.Keterangan != "" {
		sppd.Keterangan = cmd.Keterangan
	}
	if cmd.SaranaTransportasi != nil {
		sppd.SaranaTransportasi = cmd.SaranaTransportasi
	}
	if cmd.Verifikasi != nil {
		sppd.Verifikasi = cmd.Verifikasi
	}
	if cmd.Status != "" {
		sppd.Status = cmd.Status
	}
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

	var dbAnggota []domain.SppdAnggota
	for _, a := range cmd.Anggota {
		dbAnggota = append(dbAnggota, domain.SppdAnggota{
			SppdID:    sppd.ID,
			Nip:       a.Nip,
			Nidn:      a.Nidn,
			Nama:      a.Nama,
			Unit:      a.Unit,
			Fakultas:  a.Fakultas,
			Prodi:     a.Prodi,
			CreatedAt: &now,
			UpdatedAt: &now,
		})
	}
	sppd.Anggota = dbAnggota

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

	if err := h.sppdRepo.UpdateSppd(ctxTx, sppd); err != nil {
		if tx != nil {
			tx.Rollback()
		}
		return common.FailureValue[*domain.Sppd](common.FailureError("Sppd.UpdateFailed", err.Error())), nil
	}

	if tx != nil {
		if err := tx.Commit().Error; err != nil {
			return common.FailureValue[*domain.Sppd](common.FailureError("Sppd.CommitFailed", err.Error())), nil
		}
	}

	return common.SuccessValue(sppd), nil
}

func init() {
	commoninfra.RegisterValidation(func(cmd UpdateSppdCommand) error {
		return cmd.Validate()
	}, "Sppd.UpdateSppd.Validation")
}
