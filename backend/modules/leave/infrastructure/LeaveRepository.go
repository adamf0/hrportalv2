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

func (r *LeaveRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string) ([]domain.Cuti, error) {
	if nip == "" && nidn == "" {
		return []domain.Cuti{}, nil
	}
	var items []domain.Cuti

	var query *gorm.DB
	if nip != "" && nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Cuti{}).Where("(nip = ? OR nidn = ?)", nip, nidn)
	} else if nip != "" {
		query = r.db.WithContext(ctx).Model(&domain.Cuti{}).Where("nip = ?", nip)
	} else if nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Cuti{}).Where("nidn = ?", nidn)
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
