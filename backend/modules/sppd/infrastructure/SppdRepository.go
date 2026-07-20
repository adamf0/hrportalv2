package infrastructure

import (
	"context"

	commoninfra "hrportal_backend/common/infrastructure"
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
	return commoninfra.GetTx(ctx, r.db).Create(sppd).Error
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
	return commoninfra.GetTx(ctx, r.db).Session(&gorm.Session{FullSaveAssociations: true}).Save(sppd).Error
}

func (r *SppdRepository) DeleteSppd(ctx context.Context, id uint) error {
	return commoninfra.GetTx(ctx, r.db).Delete(&domain.Sppd{}, id).Error
}

func (r *SppdRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string) ([]domain.Sppd, error) {
	if nip == "" && nidn == "" {
		return []domain.Sppd{}, nil
	}
	var items []domain.Sppd
	var total int64

	var query *gorm.DB
	if nip != "" && nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Sppd{}).Where("(nip = ? OR nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ? OR nidn = ?))", nip, nidn, nip, nidn)
	} else if nip != "" {
		query = r.db.WithContext(ctx).Model(&domain.Sppd{}).Where("(nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ?))", nip, nip)
	} else if nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Sppd{}).Where("(nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ?))", nidn, nidn)
	}

	query.Count(&total)

	err := query.Preload("Anggota").Preload("Files").Order("created_at desc").Find(&items).Error
	if err != nil {
		return []domain.Sppd{}, err
	}

	return items, nil
}
