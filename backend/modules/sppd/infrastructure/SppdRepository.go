package infrastructure

import (
	"context"

	commonhelper "hrportal_backend/common/helper"
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

func (r *SppdRepository) getDB() *gorm.DB {
	if r != nil && r.db != nil {
		return r.db
	}
	if fcmDb := commonhelper.GlobalFcmManager.GetDB(); fcmDb != nil {
		return fcmDb
	}
	return nil
}

func (r *SppdRepository) CreateSppd(ctx context.Context, sppd *domain.Sppd) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, db).Create(sppd).Error
}

func (r *SppdRepository) FindByID(ctx context.Context, id uint) (*domain.Sppd, error) {
	db := r.getDB()
	if db == nil {
		return nil, nil
	}
	var sppd domain.Sppd
	// Preload Anggota and Files when loading SPPD
	err := db.WithContext(ctx).Preload("Anggota").Preload("Files").First(&sppd, id).Error
	if err != nil {
		return nil, err
	}
	return &sppd, nil
}

func (r *SppdRepository) UpdateSppd(ctx context.Context, sppd *domain.Sppd) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	// Full save handles association updates (inserting new ones, updating, etc.)
	return commoninfra.GetTx(ctx, db).Session(&gorm.Session{FullSaveAssociations: true}).Save(sppd).Error
}

func (r *SppdRepository) DeleteSppd(ctx context.Context, id uint) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, db).Delete(&domain.Sppd{}, id).Error
}

func (r *SppdRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string, verifikasi bool, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]domain.Sppd, error) {
	db := r.getDB()
	if db == nil {
		return []domain.Sppd{}, nil
	}
	var items []domain.Sppd
	var total int64

	query := db.WithContext(ctx).Model(&domain.Sppd{})

	if isSdm && tanggal_mulai != nil && tanggal_akhir != nil {
		query = query.Where("tanggal_berangkat >= ? and ? <= tanggal_kembali", tanggal_mulai, tanggal_akhir)
	} else if nip != "" || nidn != "" {
		if nip != "" && nidn != "" {
			if verifikasi {
				query = query.Where("verifikasi = ? or verifikasi = ?", nip, nidn)
			} else {
				query = query.Where("nip = ? OR nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ? OR nidn = ?)", nip, nidn, nip, nidn)
			}
		} else if nip != "" {
			if verifikasi {
				query = query.Where("verifikasi = ? or verifikasi = ?", nip, nip)
			} else {
				query = query.Where("nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ?)", nip, nip)
			}
		} else {
			if verifikasi {
				query = query.Where("verifikasi = ? or verifikasi = ?", nidn, nidn)
			} else {
				query = query.Where("nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ?)", nidn, nidn)
			}
		}
	}

	err := query.Preload("Anggota").Preload("Files").Count(&total).Order("tanggal_berangkat desc").Find(&items).Error
	if err != nil {
		return nil, err
	}

	return items, nil
}
