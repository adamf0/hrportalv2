package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/calendar/application/GetAllCalendar"
	"hrportal_backend/modules/calendar/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleCalendar(db *gorm.DB) error {
	repo := NewCalendarRepository(db)

	err := mediatr.RegisterRequestHandler[*GetAllCalendar.GetAllCalendarQuery, common.ResultValue[[]domain.CalendarItem]](
		GetAllCalendar.NewGetAllCalendarQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	return nil
}
