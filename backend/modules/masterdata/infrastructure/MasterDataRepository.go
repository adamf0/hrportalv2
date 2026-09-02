package infrastructure

import (
	"context"
	"hrportal_backend/modules/masterdata/domain"
	"strings"

	"gorm.io/gorm"
)

type MasterDataRepository struct {
	db          *gorm.DB
	dbSimak     *gorm.DB
	dbSimpeg    *gorm.DB
	dbSimpegNew *gorm.DB
}

func NewMasterDataRepository(db *gorm.DB, dbSimak *gorm.DB, dbSimpeg *gorm.DB, dbSimpegNew *gorm.DB) domain.IMasterDataRepository {
	return &MasterDataRepository{db: db, dbSimak: dbSimak, dbSimpeg: dbSimpeg, dbSimpegNew: dbSimpegNew}
}

func (r *MasterDataRepository) GetAllFakultas(ctx context.Context) ([]domain.Fakultas, error) {
	if r == nil {
		return []domain.Fakultas{}, nil
	}
	targetDB := r.dbSimak
	if targetDB == nil {
		targetDB = r.db
	}
	if targetDB == nil {
		return []domain.Fakultas{}, nil
	}

	var list []domain.Fakultas
	// Try table m_fakultas on SIMAK DB
	err := targetDB.WithContext(ctx).Table("m_fakultas").Find(&list).Error
	if err != nil || len(list) == 0 {
		// Fallback to connect_m_fakultas or default table
		err = r.db.WithContext(ctx).Table("connect_m_fakultas").Find(&list).Error
	}
	if err != nil && len(list) == 0 {
		err = r.db.WithContext(ctx).Find(&list).Error
	}

	for i := range list {
		if list[i].KodeFakultas != "" {
			list[i].ID = list[i].KodeFakultas
			list[i].Kode = list[i].KodeFakultas
		}
		if list[i].NamaFakultas != "" {
			list[i].Nama = list[i].NamaFakultas
		}
	}
	return list, nil
}

func (r *MasterDataRepository) GetAllProdi(ctx context.Context) ([]domain.Prodi, error) {
	if r == nil {
		return []domain.Prodi{}, nil
	}
	targetDB := r.dbSimak
	if targetDB == nil {
		targetDB = r.db
	}
	if targetDB == nil {
		return []domain.Prodi{}, nil
	}

	var rawList []domain.Prodi
	// Try table r_prodi on SIMAK DB
	err := targetDB.WithContext(ctx).Table("r_prodi").
		Where("LOWER(nama_prodi) NOT LIKE '%isi nama ps%'").
		Find(&rawList).Error

	if err != nil || len(rawList) == 0 {
		// Fallback to connect_r_prodi or default table
		err = r.db.WithContext(ctx).Table("connect_r_prodi").
			Where("LOWER(nama_prodi) NOT LIKE '%isi nama ps%'").
			Find(&rawList).Error
	}
	if err != nil && len(rawList) == 0 {
		err = r.db.WithContext(ctx).
			Where("LOWER(nama_prodi) NOT LIKE '%isi nama ps%'").
			Find(&rawList).Error
	}

	var list []domain.Prodi
	for i := range rawList {
		namaLower := strings.ToLower(rawList[i].NamaProdi)
		if strings.Contains(namaLower, "isi nama ps") {
			continue
		}
		if rawList[i].KodeProdi != "" {
			rawList[i].ID = rawList[i].KodeProdi
			rawList[i].Kode = rawList[i].KodeProdi
		}
		if rawList[i].KodeFakultas != "" {
			rawList[i].FakultasID = rawList[i].KodeFakultas
		}
		if rawList[i].NamaProdi != "" {
			rawList[i].Nama = rawList[i].NamaProdi
		}
		list = append(list, rawList[i])
	}
	return list, nil
}

func (r *MasterDataRepository) GetAllJenisCuti(ctx context.Context) ([]domain.JenisCuti, error) {
	if r == nil || r.db == nil {
		return []domain.JenisCuti{}, nil
	}
	var list []domain.JenisCuti
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetAllJenisIzin(ctx context.Context) ([]domain.JenisIzin, error) {
	if r == nil || r.db == nil {
		return []domain.JenisIzin{}, nil
	}
	var list []domain.JenisIzin
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetAllJenisSppd(ctx context.Context) ([]domain.JenisSppd, error) {
	if r == nil || r.db == nil {
		return []domain.JenisSppd{}, nil
	}
	var list []domain.JenisSppd
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetPeople(ctx context.Context) ([]domain.Verifikator, error) {
	if r == nil {
		return []domain.Verifikator{}, nil
	}

	var rawPeople []struct {
		Nip      string `gorm:"column:nip"`
		Nama     string `gorm:"column:nama"`
		NamaUnit string `gorm:"column:nama_unit"`
	}

	targetDB := r.dbSimpegNew
	if targetDB == nil {
		targetDB = r.db
	}

	if len(rawPeople) == 0 && targetDB != nil {
		_ = targetDB.WithContext(ctx).
			Table("pegawais").
			Select("nip, nama, '' as nama_unit").
			Where("nip IS NOT NULL AND nip != ''").
			Order("nama asc").
			// Limit(2000).
			Scan(&rawPeople).Error
	}

	var list []domain.Verifikator
	seen := make(map[string]bool)
	for _, p := range rawPeople {
		nipClean := strings.TrimSpace(p.Nip)
		namaClean := strings.TrimSpace(p.Nama)
		if nipClean == "" || namaClean == "" || seen[nipClean] {
			continue
		}
		seen[nipClean] = true
		unitStr := p.NamaUnit
		list = append(list, domain.Verifikator{
			Nip:        nipClean,
			Nama:       namaClean,
			Struktural: unitStr,
		})
	}
	return list, nil
}

func (r *MasterDataRepository) GetVerifikators(ctx context.Context, verifikatorType string) ([]domain.Verifikator, error) {
	if r == nil {
		return []domain.Verifikator{}, nil
	}

	targetDB := r.dbSimpeg
	if targetDB == nil {
		targetDB = r.db
	}
	if targetDB == nil {
		return []domain.Verifikator{}, nil
	}

	var list []domain.Verifikator

	err := targetDB.WithContext(ctx).Table("payroll_m_pegawai").
		Where("CHAR_LENGTH(nip) >= 3").
		Where("LENGTH(TRIM(struktural)) > 0").
		Order("nama asc").
		Find(&list).Error

	if err != nil {
		return []domain.Verifikator{}, err
	}

	return list, nil
}
