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
	if r.dbSimpeg == nil {
		return nil, errors.New("database SIMPEG connection not available")
	}

	rawUsername := strings.TrimSpace(username)

	// Query e_pribadi (Dosen)
	var ePribadi struct {
		Nip         *string `gorm:"column:nip"`
		Nidn        *string `gorm:"column:nidn"`
		Nama        *string `gorm:"column:nama"`
		NamaLengkap *string `gorm:"column:nama_lengkap"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("e_pribadi").Where("nidn = ? OR nip = ?", rawUsername, rawUsername).First(&ePribadi)

	// Query n_pribadi (Pegawai/Tendik)
	var nPribadi struct {
		Nip         *string `gorm:"column:nip"`
		Nama        *string `gorm:"column:nama"`
		NamaLengkap *string `gorm:"column:nama_lengkap"`
		NamaPegawai *string `gorm:"column:nama_pegawai"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("n_pribadi").Where("nip = ?", rawUsername).First(&nPribadi)

	// Query pengguna table
	var pengguna struct {
		Nama *string `gorm:"column:nama"`
		Name *string `gorm:"column:name"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("pengguna").Select("nama, name").Where("username = ?", rawUsername).Scan(&pengguna)

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
	} else if helper.StringValue(pengguna.Nama) != "" && helper.StringValue(pengguna.Nama) != rawUsername && helper.StringValue(pengguna.Nama) != cleanNip {
		realName = helper.StringValue(pengguna.Nama)
	} else if helper.StringValue(pengguna.Name) != "" && helper.StringValue(pengguna.Name) != rawUsername && helper.StringValue(pengguna.Name) != cleanNip {
		realName = helper.StringValue(pengguna.Name)
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

	// Query pengguna table as additional fallback
	var pengguna struct {
		Nama *string `gorm:"column:nama"`
		Name *string `gorm:"column:name"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("pengguna").Select("nama, name").Where("username = ?", cleanSid).Scan(&pengguna)

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
	} else if helper.StringValue(pengguna.Nama) != "" && helper.StringValue(pengguna.Nama) != cleanSid && helper.StringValue(pengguna.Nama) != cleanNip {
		realName = helper.StringValue(pengguna.Nama)
	} else if helper.StringValue(pengguna.Name) != "" && helper.StringValue(pengguna.Name) != cleanSid && helper.StringValue(pengguna.Name) != cleanNip {
		realName = helper.StringValue(pengguna.Name)
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
