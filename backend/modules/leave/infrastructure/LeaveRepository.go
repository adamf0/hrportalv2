package infrastructure

import (
	"context"

	commonhelper "hrportal_backend/common/helper"
	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/leave/domain"

	"gorm.io/gorm"
)

type LeaveRepository struct {
	db *gorm.DB
}

func NewLeaveRepository(db *gorm.DB) domain.ILeaveRepository {
	return &LeaveRepository{db: db}
}

func (r *LeaveRepository) CreateCuti(ctx context.Context, cuti *domain.Cuti) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Create(cuti).Error
}

func (r *LeaveRepository) FindByID(ctx context.Context, id uint) (*domain.Cuti, error) {
	if r == nil || r.db == nil {
		return nil, nil
	}
	var cuti domain.Cuti
	err := r.db.WithContext(ctx).Debug().First(&cuti, id).Error
	if err != nil {
		return nil, err
	}
	return &cuti, nil
}

func (r *LeaveRepository) UpdateCuti(ctx context.Context, cuti *domain.Cuti) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Save(cuti).Error
}

func (r *LeaveRepository) DeleteCuti(ctx context.Context, id uint) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Delete(&domain.Cuti{}, id).Error
}

func (r *LeaveRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string, verifikasi bool, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]domain.Cuti, error) {
	if r == nil || r.db == nil {
		return []domain.Cuti{}, nil
	}
	var items []domain.Cuti
	query := r.db.WithContext(ctx).Debug().Model(&domain.Cuti{})

	if isSdm {
		if tanggal_mulai != nil && *tanggal_mulai != "" && tanggal_akhir != nil && *tanggal_akhir != "" {
			query = query.Where("tanggal_mulai >= ? and tanggal_akhir <= ?", *tanggal_mulai, *tanggal_akhir)
		}
		query = query.Where("LOWER(status) IN (?, ?, ?, ?, ?, ?, ?, ?, ?) OR LOWER(status) LIKE ?", "terima atasan", "terima sdm", "tolak sdm", "disetujui atasan", "disetujui sdm", "ditolak sdm", "acc atasan", "acc sdm", "proses sdm", "%sdm%")
	} else if verifikasi {
		if nip != "" || nidn != "" {
			verifIDs := commonhelper.ResolveVerifikatorIDs(ctx, r.db, nip, nidn)
			query = query.Where("verifikasi IN ?", verifIDs)
		} else {
			query = query.Where("verifikasi IS NOT NULL AND verifikasi != ''")
		}
	} else if nip != "" || nidn != "" {
		if nip != "" && nidn != "" {
			query = query.Where("(nip = ? OR nidn = ?)", nip, nidn)
		} else if nip != "" {
			query = query.Where("nip = ?", nip)
		} else {
			query = query.Where("nidn = ?", nidn)
		}
	}

	err := query.Order("created_at desc").Find(&items).Error
	if err != nil {
		return nil, err
	}

	return items, nil
}

func (r *LeaveRepository) GetAllJenisCuti(ctx context.Context) ([]domain.JenisCuti, error) {
	if r == nil || r.db == nil {
		return nil, nil
	}
	var list []domain.JenisCuti
	err := r.db.WithContext(ctx).Debug().Find(&list).Error
	return list, err
}

func (r *LeaveRepository) GetActiveCutiByNip(ctx context.Context, nip string, tanggal string) ([]domain.Cuti, error) {
	if r == nil || r.db == nil {
		return []domain.Cuti{}, nil
	}
	var items []domain.Cuti
	err := r.db.WithContext(ctx).Debug().
		Where("nip = ? AND tanggal_mulai <= ? AND tanggal_akhir >= ?", nip, tanggal, tanggal).
		Find(&items).Error
	if err != nil {
		return nil, err
	}
	return items, nil
}
