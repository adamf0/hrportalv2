package infrastructure

import (
	"context"

	"hrportal_backend/modules/sppd/domain"

	"gorm.io/gorm"
)

type SppdRepository struct {
	db *gorm.DB
}

func NewSppdRepository(db *gorm.DB) domain.ISppdRepository {
	return &SppdRepository{db: db}
}

func (r *SppdRepository) CreateSppd(ctx context.Context, sppd *domain.Sppd) error {
	return r.db.WithContext(ctx).Create(sppd).Error
}

func (r *SppdRepository) FindByID(ctx context.Context, id uint) (*domain.Sppd, error) {
	var sppd domain.Sppd
	// Preload Anggota and Files when loading SPPD
	err := r.db.WithContext(ctx).Preload("Anggota").Preload("Files").First(&sppd, id).Error
	if err != nil {
		return nil, err
	}
	return &sppd, nil
}

func (r *SppdRepository) UpdateSppd(ctx context.Context, sppd *domain.Sppd) error {
	// Full save handles association updates (inserting new ones, updating, etc.)
	return r.db.WithContext(ctx).Session(&gorm.Session{FullSaveAssociations: true}).Save(sppd).Error
}

func (r *SppdRepository) DeleteSppd(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&domain.Sppd{}, id).Error
}

func (r *SppdRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string) ([]domain.Sppd, error) {
	if nip == "" && nidn == "" {
		return []domain.Sppd{}, nil
	}
	var items []domain.Sppd
	var total int64

	var query *gorm.DB
	if nip != "" && nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Sppd{}).Where("(nip = ? OR nidn = ?)", nip, nidn)
	} else if nip != "" {
		query = r.db.WithContext(ctx).Model(&domain.Sppd{}).Where("nip = ?", nip)
	} else if nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Sppd{}).Where("nidn = ?", nidn)
	}

	query.Count(&total)

	err := query.Preload("Anggota").Preload("Files").Order("created_at desc").Find(&items).Error
	if err != nil {
		return []domain.Sppd{}, err
	}

	return items, nil
}
