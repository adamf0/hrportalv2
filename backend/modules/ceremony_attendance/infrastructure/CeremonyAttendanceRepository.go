package infrastructure

import (
	"context"

	commonhelper "hrportal_backend/common/helper"
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

func (r *CeremonyAttendanceRepository) getDB() *gorm.DB {
	if r != nil && r.db != nil {
		return r.db
	}
	if fcmDb := commonhelper.GlobalFcmManager.GetDB(); fcmDb != nil {
		return fcmDb
	}
	return nil
}

func (r *CeremonyAttendanceRepository) Create(ctx context.Context, upacara *domain.AbsenUpacara) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, db).Create(upacara).Error
}

func (r *CeremonyAttendanceRepository) Update(ctx context.Context, upacara *domain.AbsenUpacara) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, db).Save(upacara).Error
}

func (r *CeremonyAttendanceRepository) Delete(ctx context.Context, id uint) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, db).Delete(&domain.AbsenUpacara{}, id).Error
}

func (r *CeremonyAttendanceRepository) GetByID(ctx context.Context, id uint) (*domain.AbsenUpacara, error) {
	db := r.getDB()
	if db == nil {
		return nil, nil
	}
	var upacara domain.AbsenUpacara
	err := db.WithContext(ctx).First(&upacara, id).Error
	if err != nil {
		return nil, err
	}
	return &upacara, nil
}

func (r *CeremonyAttendanceRepository) GetAll(ctx context.Context, nip string, nidn string, tanggal string) ([]domain.AbsenUpacara, error) {
	db := r.getDB()
	if db == nil {
		return []domain.AbsenUpacara{}, nil
	}
	var list []domain.AbsenUpacara
	query := db.WithContext(ctx)
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
