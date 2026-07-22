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
func (r *IzinRepository) GetAll(ctx context.Context, nip string, nidn string, isSdm bool) ([]domain.Izin, error) {
	var izins []domain.Izin
	query := r.db.WithContext(ctx).Model(&domain.Izin{})

	if isSdm {
		// SDM user gets all records across all statuses (terima atasan, tolak atasan, terima sdm, tolak sdm, menunggu, etc)
	} else if nip != "" || nidn != "" {
		if nip != "" && nidn != "" {
			query = query.Where("(nip = ? OR nidn = ?) or verifikasi = ?", nip, nidn, nip)
		} else if nip != "" {
			query = query.Where("nip = ? or verifikasi = ?", nip, nip)
		} else {
			query = query.Where("nidn = ?", nidn)
		}
	}

	err := query.Order("created_at desc").Find(&izins).Error
	return izins, err
}
