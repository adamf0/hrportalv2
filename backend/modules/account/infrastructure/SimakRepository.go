package infrastructure

import (
	"context"
	"crypto/md5"
	"crypto/sha1"
	"encoding/hex"
	"errors"
	"strings"

	"hrportal_backend/common/helper"
	"hrportal_backend/modules/account/domain"

	"gorm.io/gorm"
)

type SimakRepository struct {
	dbSimak  *gorm.DB
	dbSimpeg *gorm.DB
}

func NewSimakRepository(dbSimak *gorm.DB, dbSimpeg *gorm.DB) domain.ISimakRepository {
	return &SimakRepository{dbSimak: dbSimak, dbSimpeg: dbSimpeg}
}

func (r *SimakRepository) Authenticate(ctx context.Context, username, password string) (*domain.AuthResult, error) {
	if r == nil || r.dbSimak == nil {
		return nil, errors.New("database SIMAK connection not available")
	}

	rawUsername := strings.TrimSpace(username)
	rawPassword := strings.TrimSpace(password)

	var userSimak []struct {
		Userid string `gorm:"column:userid"`
		Aktif  string `gorm:"column:aktif"`
	}

	_ = r.dbSimak.WithContext(ctx).Table("user").
		Where("username = ? AND (password = SHA1(MD5(?)) OR password = SHA1(?) OR password = MD5(?) OR password = ?)",
			rawUsername, rawPassword, rawPassword, rawPassword, rawPassword).
		Where("level = ?", "DOSEN").
		Where("aktif = ?", "Y").
		Find(&userSimak)

	if len(userSimak) > 1 {
		return nil, errors.New("akun " + rawUsername + " lebih dari 1")
	}

	if len(userSimak) == 1 {
		userid := userSimak[0].Userid

		var dosen struct {
			NIDN *string `gorm:"column:NIDN"`
			NIP  *string `gorm:"column:NIP"`
			Nama *string `gorm:"column:nama"`
		}
		_ = r.dbSimak.WithContext(ctx).Table("m_dosen").Where("NIDN = ? OR NIP = ?", userid, userid).First(&dosen)

		sid := userid
		if helper.StringValue(dosen.NIDN) != "" {
			sid = helper.StringValue(dosen.NIDN)
		}

		return &domain.AuthResult{
			Sid:    sid,
			Source: "simak",
			Name:   helper.StringValue(dosen.Nama),
			Nip:    helper.StringValue(dosen.NIP),
			Nidn:   helper.StringValue(dosen.NIDN),
		}, nil
	}

	return nil, nil
}

func (r *SimakRepository) GetInfo(ctx context.Context, sid string) (*domain.UserInfo, error) {
	if r == nil || r.dbSimak == nil {
		return nil, errors.New("database SIMAK connection not available")
	}

	var simakU struct {
		Userid string  `gorm:"column:userid"`
		Email *string `gorm:"column:email"`
	}
	err := r.dbSimak.WithContext(ctx).Table("user").Where("userid = ?", sid).First(&simakU).Error
	if err != nil {
		return nil, errors.New("user simak tidak ditemukan")
	}

	// Struct penampung yang sudah mendukung data join
	var dosen struct {
		Nidn         string  `gorm:"column:NIDN"`
		NamaDosen    string  `gorm:"column:nama_dosen"`
		KodeFakultas *string `gorm:"column:kode_fakultas"`
		NamaFakultas *string `gorm:"column:nama_fakultas"` // Opsional jika Anda butuh nama fakultasnya
		KodeProdi    *string `gorm:"column:kode_prodi"`
		NamaProdi    *string `gorm:"column:nama_prodi"` // Opsional jika Anda butuh nama prodi-nya
	}

	// Query dengan Inner Join / Left Join sesuai relasi tabel
	_ = r.dbSimak.WithContext(ctx).
		Table("m_dosen").
		Select("m_dosen.NIDN, m_dosen.nama_dosen, m_dosen.kode_fak as kode_fakultas, m_dosen.kode_prodi as kode_prodi, m_fakultas.nama_fakultas as nama_fakultas, m_program_studi.nama_prodi as nama_prodi").
		Joins("LEFT JOIN m_fakultas ON m_fakultas.kode_fakultas = m_dosen.kode_fak").
		Joins("LEFT JOIN m_program_studi ON m_program_studi.kode_prodi = m_dosen.kode_prodi"). // Catatan: sesuaikan nama kolom di ON jika ada typo di db (misal: kode_podi)
		Where("m_dosen.NIDN = ?", sid).
		First(&dosen)

	var ePribadi struct {
		Nip *string `gorm:"column:nip"`
	}
	var unitKerja string
	if r.dbSimpeg != nil {
		_ = r.dbSimpeg.WithContext(ctx).Table("e_pribadi").Where("nidn = ?", sid).First(&ePribadi)
		if ePribadi.Nip != nil {
			_ = r.dbSimpeg.WithContext(ctx).Table("n_pengangkatan").
				Where("nip = ?", *ePribadi.Nip).
				Pluck("unit_kerja", &unitKerja)
		}
	}

	return &domain.UserInfo{
		Sid:          sid,
		Source:       "simak",
		Fakultas:     helper.StringValue(dosen.NamaFakultas),
		Prodi:        helper.StringValue(dosen.NamaProdi),
		KodeFakultas: helper.StringValue(dosen.KodeFakultas),
		KodeProdi:    helper.StringValue(dosen.KodeProdi),
		Unit:         unitKerja,
		Level:        "dosen",
		Name:         dosen.NamaDosen,
		Email:        helper.StringValue(simakU.Email),
		Nip:          helper.StringValue(ePribadi.Nip),
		Nidn:         helper.StringValue(&dosen.Nidn),
	}, nil
}

func (r *SimakRepository) hashSimak(password string) string {
	hMD5 := md5.Sum([]byte(password))
	strMD5 := hex.EncodeToString(hMD5[:])
	hSHA1 := sha1.Sum([]byte(strMD5))
	return hex.EncodeToString(hSHA1[:])
}
