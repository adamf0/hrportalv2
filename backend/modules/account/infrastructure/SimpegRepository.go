package infrastructure

import (
	"context"
	"crypto/sha1"
	"encoding/hex"
	"errors"

	"hrportal_backend/common/helper"
	"hrportal_backend/modules/account/domain"

	"gorm.io/gorm"
)

type SimpegRepository struct {
	dbSimpeg *gorm.DB
}

func NewSimpegRepository(dbSimpeg *gorm.DB) domain.ISimpegRepository {
	return &SimpegRepository{dbSimpeg: dbSimpeg}
}

func (r *SimpegRepository) Authenticate(ctx context.Context, username, password string) (*domain.AuthResult, error) {
	var userSimpeg []struct {
		Username string `gorm:"column:username"`
		Password string `gorm:"column:password"`
		Status   string `gorm:"column:status"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("pengguna").Where("username = ?", username).Where("level = ?", "PEGAWAI").Find(&userSimpeg)

	var matchedUsernames []string
	hashedPassSimpeg := r.hashSimpeg(password)
	for _, us := range userSimpeg {
		if us.Password == hashedPassSimpeg {
			if us.Status != "AKTIF" {
				return nil, errors.New("akun sudah tidak aktif")
			}
			matchedUsernames = append(matchedUsernames, us.Username)
		}
	}

	if len(matchedUsernames) > 1 {
		return nil, errors.New("akun " + username + " lebih dari 1")
	}
	if len(matchedUsernames) == 0 {
		return nil, errors.New("akun tidak ditemukan")
	}

	nip := matchedUsernames[0]
	var nPribadi struct {
		Nip  *string `gorm:"column:nip"`
		Nama *string `gorm:"column:nama"`
	}
	_ = r.dbSimpeg.WithContext(ctx).Table("n_pribadi").Where("nip = ?", nip).First(&nPribadi)

	if helper.StringValue(nPribadi.Nama) == "" || helper.StringValue(nPribadi.Nip) == "" {
		return nil, errors.New("data simpeg tidak ditemukan")
	}

	return &domain.AuthResult{
		Sid:    helper.StringValue(nPribadi.Nip),
		Source: "simpeg",
	}, nil
}

func (r *SimpegRepository) GetInfo(ctx context.Context, sid string) (*domain.UserInfo, error) {
	var nPribadi struct {
		Nip   *string `gorm:"column:nip"`
		Nama  *string `gorm:"column:nama"`
		Email *string `gorm:"column:email"`
	}
	err := r.dbSimpeg.WithContext(ctx).Table("n_pribadi").Where("nip = ?", sid).First(&nPribadi).Error
	if err != nil {
		return nil, errors.New("data simpeg tidak ditemukan")
	}

	var unitKerja string
	if nPribadi.Nip != nil {
		_ = r.dbSimpeg.WithContext(ctx).Table("n_pengangkatan").
			Where("nip = ?", *nPribadi.Nip).
			Pluck("unit_kerja", &unitKerja)
	}

	return &domain.UserInfo{
		Sid:      sid,
		Source:   "simpeg",
		Fakultas: "",
		Prodi:    "",
		Unit:     unitKerja,
		Level:    "tendik",
		Name:     helper.StringValue(nPribadi.Nama),
		Email:    helper.StringValue(nPribadi.Email),
		Nip:      helper.StringValue(nPribadi.Nip),
		Nidn:     "",
	}, nil
}

func (r *SimpegRepository) hashSimpeg(password string) string {
	hSHA1 := sha1.Sum([]byte(password))
	return hex.EncodeToString(hSHA1[:])
}
