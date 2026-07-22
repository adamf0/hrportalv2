package infrastructure

import (
	"context"
	"strings"
	"hrportal_backend/modules/masterdata/domain"

	"gorm.io/gorm"
)

type MasterDataRepository struct {
	db *gorm.DB
}

func NewMasterDataRepository(db *gorm.DB) domain.IMasterDataRepository {
	return &MasterDataRepository{db: db}
}

func (r *MasterDataRepository) GetAllFakultas(ctx context.Context) ([]domain.Fakultas, error) {
	var list []domain.Fakultas
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetAllProdi(ctx context.Context) ([]domain.Prodi, error) {
	var list []domain.Prodi
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetAllJenisCuti(ctx context.Context) ([]domain.JenisCuti, error) {
	var list []domain.JenisCuti
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetAllJenisIzin(ctx context.Context) ([]domain.JenisIzin, error) {
	var list []domain.JenisIzin
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetAllJenisSppd(ctx context.Context) ([]domain.JenisSppd, error) {
	var list []domain.JenisSppd
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}

func (r *MasterDataRepository) GetVerifikators(ctx context.Context, verifikatorType string) ([]domain.Verifikator, error) {
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

func (r *MasterDataRepository) GetAllUnitKerja(ctx context.Context) ([]string, error) {
	var list []string
	err := r.db.WithContext(ctx).Table("connect_payroll_m_pegawai").
		Where("struktural IS NOT NULL AND struktural != ''").
		Distinct("struktural").
		Pluck("struktural", &list).Error
	return list, err
}

