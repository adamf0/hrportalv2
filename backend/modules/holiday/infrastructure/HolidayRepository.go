package infrastructure

import (
	"context"
	commonhelper "hrportal_backend/common/helper"
	"hrportal_backend/modules/holiday/domain"
	"gorm.io/gorm"
)

type HolidayRepository struct {
	db *gorm.DB
}

func NewHolidayRepository(db *gorm.DB) domain.IHolidayRepository {
	return &HolidayRepository{db: db}
}

func (r *HolidayRepository) getDB() *gorm.DB {
	if r != nil && r.db != nil {
		return r.db
	}
	if fcmDb := commonhelper.GlobalFcmManager.GetDB(); fcmDb != nil {
		return fcmDb
	}
	return nil
}

func (r *HolidayRepository) Create(ctx context.Context, holiday *domain.MasterLibur) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return db.WithContext(ctx).Create(holiday).Error
}

func (r *HolidayRepository) Update(ctx context.Context, holiday *domain.MasterLibur) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return db.WithContext(ctx).Save(holiday).Error
}

func (r *HolidayRepository) Delete(ctx context.Context, id uint) error {
	db := r.getDB()
	if db == nil {
		return nil
	}
	return db.WithContext(ctx).Delete(&domain.MasterLibur{}, "id = ?", id).Error
}

func (r *HolidayRepository) GetByID(ctx context.Context, id uint) (*domain.MasterLibur, error) {
	db := r.getDB()
	if db == nil {
		return nil, nil
	}
	var item domain.MasterLibur
	if err := db.WithContext(ctx).First(&item, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *HolidayRepository) GetHolidays(ctx context.Context, year int) ([]domain.MasterLibur, error) {
	db := r.getDB()
	if db == nil {
		return []domain.MasterLibur{}, nil
	}
	var list []domain.MasterLibur
	query := db.WithContext(ctx).Model(&domain.MasterLibur{})
	if year > 0 {
		query = query.Where("YEAR(tanggal) = ?", year)
	}
	if err := query.Order("tanggal asc").Find(&list).Error; err != nil {
		return nil, err
	}
	for i := range list {
		if list[i].IsNationalHoliday {
			list[i].Libur = 1
		} else {
			list[i].Libur = 0
		}
	}
	return list, nil
}
