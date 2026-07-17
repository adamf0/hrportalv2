package presentation

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/calendar/application/GetAllCalendar"
	"hrportal_backend/modules/calendar/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleCalendar(app *fiber.App) {
	group := app.Group("/api/calendar", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Get("/stream", func(c *fiber.Ctx) error {
		query := &GetAllCalendar.GetAllCalendarQuery{
			Nip:       c.FormValue("nip"),
			Nidn:      c.FormValue("nidn"),
			StartDate: c.Query("start_date"),
			EndDate:   c.Query("end_date"),
		}

		res, err := mediatr.Send[*GetAllCalendar.GetAllCalendarQuery, common.ResultValue[[]domain.CalendarItem]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.CalendarItem]{}

		return sseAdapter.Send(c, pagedData)
	})

	group.Get("/", func(c *fiber.Ctx) error {
		query := &GetAllCalendar.GetAllCalendarQuery{
			Nip:       c.FormValue("nip"),
			Nidn:      c.FormValue("nidn"),
			StartDate: c.Query("start_date"),
			EndDate:   c.Query("end_date"),
		}

		res, err := mediatr.Send[*GetAllCalendar.GetAllCalendarQuery, common.ResultValue[[]domain.CalendarItem]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})
}
