package infrastructure

import (
	"context"
	"hrportal_backend/modules/izin/domain"

	"gorm.io/gorm"
)

type IzinRepository struct {
	db *gorm.DB
}

func NewIzinRepository(db *gorm.DB) domain.IIzinRepository {
	return &IzinRepository{db: db}
}

func (r *IzinRepository) Create(ctx context.Context, izin *domain.Izin) error {
	return r.db.WithContext(ctx).Create(izin).Error
}

func (r *IzinRepository) Update(ctx context.Context, izin *domain.Izin) error {
	return r.db.WithContext(ctx).Save(izin).Error
}

func (r *IzinRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&domain.Izin{}, id).Error
}

func (r *IzinRepository) GetByID(ctx context.Context, id uint) (*domain.Izin, error) {
	var izin domain.Izin
	err := r.db.WithContext(ctx).First(&izin, id).Error
	if err != nil {
		return nil, err
	}
	return &izin, nil
}
func (r *IzinRepository) GetAll(ctx context.Context, nip string, nidn string) ([]domain.Izin, error) {
	var izins []domain.Izin
	query := r.db.WithContext(ctx).Model(&domain.Izin{})
	if nip != "" && nidn != "" {
		query = query.Where("(nip = ? OR nidn = ?)", nip, nidn)
	} else if nip != "" {
		query = query.Where("nip = ?", nip)
	} else if nidn != "" {
		query = query.Where("nidn = ?", nidn)
	} else {
		return []domain.Izin{}, nil
	}
	err := query.Find(&izins).Error
	return izins, err
}
