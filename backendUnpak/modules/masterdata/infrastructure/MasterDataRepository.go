package infrastructure

import (
	"context"
	"hrportal_backend_unpak/modules/masterdata/domain"
	"strings"

	"gorm.io/gorm"
)

type MasterDataRepository struct {
	db *gorm.DB
}

func NewMasterDataRepository(db *gorm.DB) domain.IMasterDataRepository {
	return &MasterDataRepository{db: db}
}

func (r *MasterDataRepository) GetAllFakultas(ctx context.Context) ([]domain.Fakultas, error) {
	if r == nil || r.db == nil {
		return []domain.Fakultas{}, nil
	}
	var list []domain.Fakultas
	err := r.db.WithContext(ctx).Find(&list).Error
	if err != nil {
		return nil, err
	}
	for i := range list {
		list[i].ID = list[i].KodeFakultas
		list[i].Kode = list[i].KodeFakultas
		list[i].Nama = list[i].NamaFakultas
	}
	return list, nil
}

func (r *MasterDataRepository) GetAllProdi(ctx context.Context) ([]domain.Prodi, error) {
	if r == nil || r.db == nil {
		return []domain.Prodi{}, nil
	}
	var list []domain.Prodi
	err := r.db.WithContext(ctx).Find(&list).Error
	if err != nil {
		return nil, err
	}
	for i := range list {
		list[i].ID = list[i].KodeProdi
		list[i].FakultasID = list[i].KodeFakultas
		list[i].Kode = list[i].KodeProdi
		list[i].Nama = list[i].NamaProdi
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

func (r *MasterDataRepository) GetVerifikators(ctx context.Context, verifikatorType string) ([]domain.Verifikator, error) {
	if r == nil || r.db == nil {
		return []domain.Verifikator{}, nil
	}
	var list []domain.Verifikator
	query := r.db.WithContext(ctx).Table("connect_payroll_m_pegawai").
		Where("CHAR_LENGTH(nip) >= 3").
		Where("struktural != ''")

	err := query.Find(&list).Error
	if err != nil {
		return nil, err
	}

	if verifikatorType == "sppd" || verifikatorType == "verifikator" {
		var filtered []domain.Verifikator
		for _, v := range list {
			strukturalLower := strings.ToLower(v.Struktural)
			if strings.Contains(strukturalLower, "wakil rektor bid sdm dan keuangan") ||
				strings.Contains(strukturalLower, "wakil dekan 2") ||
				strings.Contains(strukturalLower, "wakil dekan ii") {
				filtered = append(filtered, v)
			}
		}
		return filtered, nil
	}

	return list, nil
}
