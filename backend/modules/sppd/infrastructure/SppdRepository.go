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

func (r *SppdRepository) CreateSppd(ctx context.Context, sppd *domain.Sppd) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Create(sppd).Error
}

func (r *SppdRepository) FindByID(ctx context.Context, id uint) (*domain.Sppd, error) {
	if r == nil || r.db == nil {
		return nil, nil
	}
	var sppd domain.Sppd
	// Preload Anggota and Files when loading SPPD
	err := r.db.WithContext(ctx).Debug().Preload("Anggota").Preload("Files").First(&sppd, id).Error
	if err != nil {
		return nil, err
	}
	return &sppd, nil
}

func (r *SppdRepository) UpdateSppd(ctx context.Context, sppd *domain.Sppd) error {
	if r == nil || r.db == nil {
		return nil
	}
	// Full save handles association updates (inserting new ones, updating, etc.)
	return commoninfra.GetTx(ctx, r.db).Session(&gorm.Session{FullSaveAssociations: true}).Save(sppd).Error
}

func (r *SppdRepository) DeleteSppd(ctx context.Context, id uint) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Delete(&domain.Sppd{}, id).Error
}

func (r *SppdRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string, verifikasi bool, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]domain.Sppd, error) {
	if r == nil || r.db == nil {
		return []domain.Sppd{}, nil
	}
	var items []domain.Sppd
	var total int64

	query := r.db.WithContext(ctx).Debug().Model(&domain.Sppd{})

	if isSdm {
		if tanggal_mulai != nil && *tanggal_mulai != "" && tanggal_akhir != nil && *tanggal_akhir != "" {
			query = query.Where("tanggal_berangkat >= ? and tanggal_kembali <= ?", *tanggal_mulai, *tanggal_akhir)
		}
		query = query.Where("LOWER(status) IN (?, ?, ?, ?, ?, ?, ?, ?, ?) OR LOWER(status) LIKE ?", "terima atasan", "terima sdm", "tolak sdm", "disetujui atasan", "disetujui sdm", "ditolak sdm", "acc atasan", "acc sdm", "proses sdm", "%sdm%")
	} else if verifikasi {
		if nip != "" || nidn != "" {
			verifIDs := commonhelper.ResolveVerifikatorIDs(ctx, r.db, nip, nidn)
			query = query.Where("verifikasi IN ? or id IN (SELECT id_sppd FROM sppd_anggota WHERE nip IN ? OR nidn IN ?)", verifIDs, verifIDs, verifIDs)
		} else {
			query = query.Where("verifikasi IS NOT NULL AND verifikasi != ''")
		}
	} else if nip != "" || nidn != "" {
		if nip != "" && nidn != "" {
			query = query.Where("nip = ? OR nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ? OR nidn = ?)", nip, nidn, nip, nidn)
		} else if nip != "" {
			query = query.Where("nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ?)", nip, nip)
		} else {
			query = query.Where("nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ?)", nidn, nidn)
		}
	}

	err := query.Preload("Anggota").Preload("Files").Count(&total).Order("created_at desc").Find(&items).Error
	if err != nil {
		return nil, err
	}

	return items, nil
}
