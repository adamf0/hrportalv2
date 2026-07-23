package infrastructure

import (
	"context"

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
	return commoninfra.GetTx(ctx, r.db).Create(cuti).Error
}

func (r *LeaveRepository) FindByID(ctx context.Context, id uint) (*domain.Cuti, error) {
	var cuti domain.Cuti
	err := r.db.WithContext(ctx).First(&cuti, id).Error
	if err != nil {
		return nil, err
	}
	return &cuti, nil
}

func (r *LeaveRepository) UpdateCuti(ctx context.Context, cuti *domain.Cuti) error {
	return commoninfra.GetTx(ctx, r.db).Save(cuti).Error
}

func (r *LeaveRepository) DeleteCuti(ctx context.Context, id uint) error {
	return commoninfra.GetTx(ctx, r.db).Delete(&domain.Cuti{}, id).Error
}

func (r *LeaveRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string, verifikasi bool, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]domain.Cuti, error) {
	var items []domain.Cuti
	query := r.db.WithContext(ctx).Model(&domain.Cuti{})

	if isSdm && tanggal_mulai != nil && tanggal_akhir != nil {
		query = query.Where("tanggal_mulai >= ? and ? <= tanggal_akhir", tanggal_mulai, tanggal_akhir)
	} else if nip != "" || nidn != "" {
		if nip != "" && nidn != "" {
			if verifikasi {
				query = query.Where("verifikasi = ? or verifikasi = ?", nip, nidn)
			} else {
				query = query.Where("(nip = ? OR nidn = ?)", nip, nidn)
			}
		} else if nip != "" {
			if verifikasi {
				query = query.Where("verifikasi = ?", nip)
			} else {
				query = query.Where("nip = ?", nip)
			}
		} else {
			if verifikasi {
				query = query.Where("verifikasi = ?", nidn)
			} else {
				query = query.Where("nidn = ?", nidn)
			}
		}
	}

	err := query.Order("created_at desc").Find(&items).Error
	if err != nil {
		return []domain.Cuti{}, err
	}

	return items, nil
}

func (r *LeaveRepository) GetAllJenisCuti(ctx context.Context) ([]domain.JenisCuti, error) {
	var list []domain.JenisCuti
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}
