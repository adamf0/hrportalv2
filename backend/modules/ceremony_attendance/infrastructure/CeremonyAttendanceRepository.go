package infrastructure

import (
	"context"

	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/ceremony_attendance/domain"

	"gorm.io/gorm"
)

type CeremonyAttendanceRepository struct {
	db *gorm.DB
}

func NewCeremonyAttendanceRepository(db *gorm.DB) domain.ICeremonyAttendanceRepository {
	return &CeremonyAttendanceRepository{db: db}
}

func (r *CeremonyAttendanceRepository) Create(ctx context.Context, upacara *domain.AbsenUpacara) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Create(upacara).Error
}

func (r *CeremonyAttendanceRepository) Update(ctx context.Context, upacara *domain.AbsenUpacara) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Save(upacara).Error
}

func (r *CeremonyAttendanceRepository) Delete(ctx context.Context, id uint) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Delete(&domain.AbsenUpacara{}, id).Error
}

func (r *CeremonyAttendanceRepository) GetByID(ctx context.Context, id uint) (*domain.AbsenUpacara, error) {
	if r == nil || r.db == nil {
		return nil, nil
	}
	var upacara domain.AbsenUpacara
	err := r.db.WithContext(ctx).Debug().First(&upacara, id).Error
	if err != nil {
		return nil, err
	}
	return &upacara, nil
}

func (r *CeremonyAttendanceRepository) GetAll(ctx context.Context, nip string, nidn string, tanggal string) ([]domain.AbsenUpacara, error) {
	if r == nil || r.db == nil {
		return []domain.AbsenUpacara{}, nil
	}
	var list []domain.AbsenUpacara
	query := r.db.WithContext(ctx).Debug()
	if nip != "" && nidn != "" {
		query = query.Where("nip = ? OR nidn = ?", nip, nidn)
	} else if nip != "" {
		query = query.Where("nip = ?", nip)
	} else if nidn != "" {
		query = query.Where("nidn = ?", nidn)
	}
	if tanggal != "" {
		query = query.Where("tanggal = ?", tanggal)
	}
	err := query.Find(&list).Error
	return list, err
}
