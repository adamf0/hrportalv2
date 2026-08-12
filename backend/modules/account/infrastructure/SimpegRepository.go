package infrastructure

import (
	"context"
	"errors"
	"strings"

	"hrportal_backend/common/helper"
	"hrportal_backend/modules/account/domain"

	"gorm.io/gorm"
)

type SimpegRepository struct {
	dbSimpeg *gorm.DB
}

func NewSimpegRepository(dbSimpeg *gorm.DB) *SimpegRepository {
	return &SimpegRepository{
		dbSimpeg: dbSimpeg,
	}
}

func (r *SimpegRepository) Authenticate(ctx context.Context, username, password string) (*domain.AuthResult, error) {
	if r == nil || r.dbSimpeg == nil {
		return nil, errors.New("database SIMPEG connection not available")
	}

	rawUsername := strings.TrimSpace(username)
	rawPassword := strings.TrimSpace(password)

	// 1. Cek login di tabel pengguna: username, password, level harus dosen/pegawai, status = AKTIF
	var pengguna struct {
		ID       int    `gorm:"column:id"`
		Username string `gorm:"column:username"`
		Level    string `gorm:"column:level"`
		Status   string `gorm:"column:status"`
	}

	errUser := r.dbSimpeg.WithContext(ctx).Table("pengguna").
		Where("username = ? AND (password = SHA1(?) OR password = MD5(?) OR password = ?) AND LOWER(level) IN ('dosen', 'pegawai') AND UPPER(status) = 'AKTIF'",
			rawUsername, rawPassword, rawPassword, rawPassword).
		First(&pengguna).Error

	if errUser != nil || pengguna.ID == 0 {
		return nil, errors.New("invalid credentials, level, or status in SIMPEG")
	}

	// 2. Jika valid, baru cari data e_pribadi (Dosen) dan n_pribadi (Pegawai/Tendik) menggunakan username
	var ePribadi struct {
		Nip         *string `gorm:"column:nip"`
		Nidn        *string `gorm:"column:nidn"`
		Nama        *string `gorm:"column:nama"`
		NamaLengkap *string `gorm:"column:nama_lengkap"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("e_pribadi").Where("nidn = ? OR nip = ?", rawUsername, rawUsername).First(&ePribadi)

	var nPribadi struct {
		Nip         *string `gorm:"column:nip"`
		Nama        *string `gorm:"column:nama"`
		NamaLengkap *string `gorm:"column:nama_lengkap"`
		NamaPegawai *string `gorm:"column:nama_pegawai"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("n_pribadi").Where("nip = ?", rawUsername).First(&nPribadi)

	realNip := rawUsername
	if helper.StringValue(ePribadi.Nip) != "" {
		realNip = helper.StringValue(ePribadi.Nip)
	} else if helper.StringValue(nPribadi.Nip) != "" {
		realNip = helper.StringValue(nPribadi.Nip)
	}
	cleanNip := strings.TrimSpace(realNip)

	realNidn := ""
	if helper.StringValue(ePribadi.Nidn) != "" {
		realNidn = helper.StringValue(ePribadi.Nidn)
	}

	realName := ""
	if helper.StringValue(ePribadi.Nama) != "" && helper.StringValue(ePribadi.Nama) != rawUsername && helper.StringValue(ePribadi.Nama) != cleanNip {
		realName = helper.StringValue(ePribadi.Nama)
	} else if helper.StringValue(ePribadi.NamaLengkap) != "" && helper.StringValue(ePribadi.NamaLengkap) != rawUsername && helper.StringValue(ePribadi.NamaLengkap) != cleanNip {
		realName = helper.StringValue(ePribadi.NamaLengkap)
	} else if helper.StringValue(nPribadi.Nama) != "" && helper.StringValue(nPribadi.Nama) != rawUsername && helper.StringValue(nPribadi.Nama) != cleanNip {
		realName = helper.StringValue(nPribadi.Nama)
	} else if helper.StringValue(nPribadi.NamaLengkap) != "" && helper.StringValue(nPribadi.NamaLengkap) != rawUsername && helper.StringValue(nPribadi.NamaLengkap) != cleanNip {
		realName = helper.StringValue(nPribadi.NamaLengkap)
	} else if helper.StringValue(nPribadi.NamaPegawai) != "" && helper.StringValue(nPribadi.NamaPegawai) != rawUsername && helper.StringValue(nPribadi.NamaPegawai) != cleanNip {
		realName = helper.StringValue(nPribadi.NamaPegawai)
	}

	if realName == "" {
		realName = rawUsername
	}

	return &domain.AuthResult{
		Sid:    rawUsername,
		Source: "simpeg",
		Name:   realName,
		Nip:    realNip,
		Nidn:   realNidn,
	}, nil
}

func (r *SimpegRepository) GetInfo(ctx context.Context, sid string) (*domain.UserInfo, error) {
	if r == nil || r.dbSimpeg == nil {
		return nil, errors.New("database SIMPEG connection not available")
	}

	cleanSid := strings.TrimSpace(sid)

	// Query e_pribadi (Dosen)
	var ePribadi struct {
		Nip       *string `gorm:"column:nip"`
		Nidn      *string `gorm:"column:nidn"`
		Nama      *string `gorm:"column:nama"`
		Email     *string `gorm:"column:email"`
		UnitKerja *string `gorm:"column:unit_kerja"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("e_pribadi").Where("nidn = ? OR nip = ?", cleanSid, cleanSid).First(&ePribadi)

	// Query n_pribadi (Tendik/Pegawai)
	var nPribadi struct {
		Nip         *string `gorm:"column:nip"`
		Nama        *string `gorm:"column:nama"`
		NamaLengkap *string `gorm:"column:nama_lengkap"`
		NamaPegawai *string `gorm:"column:nama_pegawai"`
		Email       *string `gorm:"column:email"`
		UnitKerja   *string `gorm:"column:unit_kerja"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("n_pribadi").Where("nip = ?", cleanSid).First(&nPribadi)

	// Query pengguna table (level, status)
	var pengguna struct {
		Level  *string `gorm:"column:level"`
		Status *string `gorm:"column:status"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("pengguna").Select("level, status").Where("username = ?", cleanSid).Scan(&pengguna)

	realNip := cleanSid
	if helper.StringValue(ePribadi.Nip) != "" {
		realNip = helper.StringValue(ePribadi.Nip)
	} else if helper.StringValue(nPribadi.Nip) != "" {
		realNip = helper.StringValue(nPribadi.Nip)
	}
	cleanNip := strings.TrimSpace(realNip)

	realNidn := ""
	if helper.StringValue(ePribadi.Nidn) != "" {
		realNidn = helper.StringValue(ePribadi.Nidn)
	}

	realName := ""
	if helper.StringValue(ePribadi.Nama) != "" && helper.StringValue(ePribadi.Nama) != cleanSid && helper.StringValue(ePribadi.Nama) != cleanNip {
		realName = helper.StringValue(ePribadi.Nama)
	} else if helper.StringValue(nPribadi.Nama) != "" && helper.StringValue(nPribadi.Nama) != cleanSid && helper.StringValue(nPribadi.Nama) != cleanNip {
		realName = helper.StringValue(nPribadi.Nama)
	}

	if realName == "" {
		realName = cleanSid
	}

	realEmail := ""
	if helper.StringValue(ePribadi.Email) != "" {
		realEmail = helper.StringValue(ePribadi.Email)
	} else if helper.StringValue(nPribadi.Email) != "" {
		realEmail = helper.StringValue(nPribadi.Email)
	}

	var unitKerja string
	if helper.StringValue(ePribadi.UnitKerja) != "" {
		unitKerja = helper.StringValue(ePribadi.UnitKerja)
	} else if helper.StringValue(nPribadi.UnitKerja) != "" {
		unitKerja = helper.StringValue(nPribadi.UnitKerja)
	}

	if unitKerja == "" && cleanNip != "" {
		_ = r.dbSimpeg.WithContext(ctx).Table("n_pengangkatan").
			Where("nip = ?", cleanNip).
			Pluck("unit_kerja", &unitKerja)
	}
	if unitKerja == "" && cleanNip != "" {
		_ = r.dbSimpeg.WithContext(ctx).Table("e_pengangkatan").
			Where("nip = ?", cleanNip).
			Pluck("unit_kerja", &unitKerja)
	}

	level := "tendik"
	if (ePribadi.Nama != nil && *ePribadi.Nama != "") || (ePribadi.Nidn != nil && *ePribadi.Nidn != "") {
		level = "dosen"
	}

	return &domain.UserInfo{
		Sid:          cleanSid,
		Source:       "simpeg",
		Fakultas:     "",
		Prodi:        "",
		KodeFakultas: "",
		KodeProdi:    "",
		Unit:         unitKerja,
		Level:        level,
		Name:         realName,
		Email:        realEmail,
		Nip:          cleanNip,
		Nidn:         realNidn,
	}, nil
}
