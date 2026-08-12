package domain

import (
	"context"
)

type IHolidayRepository interface {
	Create(ctx context.Context, holiday *MasterLibur) error
	Update(ctx context.Context, holiday *MasterLibur) error
	Delete(ctx context.Context, id uint) error
	GetByID(ctx context.Context, id uint) (*MasterLibur, error)
	GetHolidays(ctx context.Context, year int) ([]MasterLibur, error)
}
