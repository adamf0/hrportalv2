package infrastructure

import (
	"context"
	"hrportal_backend/modules/holiday/domain"
	"gorm.io/gorm"
)

type HolidayRepository struct {
	db *gorm.DB
}

func NewHolidayRepository(db *gorm.DB) domain.IHolidayRepository {
	return &HolidayRepository{db: db}
}

func (r *HolidayRepository) Create(ctx context.Context, holiday *domain.MasterLibur) error {
	return r.db.WithContext(ctx).Create(holiday).Error
}

func (r *HolidayRepository) Update(ctx context.Context, holiday *domain.MasterLibur) error {
	return r.db.WithContext(ctx).Save(holiday).Error
}

func (r *HolidayRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&domain.MasterLibur{}, "id = ?", id).Error
}

func (r *HolidayRepository) GetByID(ctx context.Context, id uint) (*domain.MasterLibur, error) {
	var item domain.MasterLibur
	if err := r.db.WithContext(ctx).First(&item, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *HolidayRepository) GetHolidays(ctx context.Context, year int) ([]domain.MasterLibur, error) {
	var list []domain.MasterLibur
	query := r.db.WithContext(ctx).Model(&domain.MasterLibur{})
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
