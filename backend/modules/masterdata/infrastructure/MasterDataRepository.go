package infrastructure

import (
	"context"
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
