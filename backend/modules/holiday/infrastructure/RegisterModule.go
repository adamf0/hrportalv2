package infrastructure

import (
	commondomain "hrportal_backend/common/domain"
	"hrportal_backend/modules/holiday/application/GetHolidays"
	"hrportal_backend/modules/holiday/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleHoliday(db *gorm.DB) error {
	repo := NewHolidayRepository(db)

	mediatr.RegisterRequestHandler[
		*GetHolidays.GetHolidaysQuery,
		commondomain.ResultValue[[]domain.MasterLibur],
	](GetHolidays.NewGetHolidaysQueryHandler(repo))

	return nil
}
