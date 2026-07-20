package presentation

import (
	"strconv"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/attendance/application/CheckIn"
	"hrportal_backend/modules/attendance/application/CheckInUpacara"
	"hrportal_backend/modules/attendance/application/CheckOut"
	"hrportal_backend/modules/attendance/application/DeleteEmptyAttendance"
	"hrportal_backend/modules/attendance/application/GetAttendanceHistory"
	"hrportal_backend/modules/attendance/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleAttendance(app *fiber.App) {
	group := app.Group("/api/attendance", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/check-in", func(c *fiber.Ctx) error {
		lat, _ := strconv.ParseFloat(c.FormValue("latitude"), 64)
		lon, _ := strconv.ParseFloat(c.FormValue("longitude"), 64)

		command := CheckIn.CheckInCommand{
			Nip:       c.FormValue("nip"),
			Nidn:      c.FormValue("nidn"),
			Latitude:  lat,
			Longitude: lon,
			Note:      c.FormValue("note"),
		}

		res, err := mediatr.Send[*CheckIn.CheckInCommand, common.ResultValue[*domain.Absen]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Post("/check-in-upacara", func(c *fiber.Ctx) error {
		command := CheckInUpacara.CheckInUpacaraCommand{
			Nip:  c.FormValue("nip"),
			Nidn: c.FormValue("nidn"),
		}

		res, err := mediatr.Send[*CheckInUpacara.CheckInUpacaraCommand, common.ResultValue[*domain.AbsenUpacara]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Post("/check-out", func(c *fiber.Ctx) error {
		command := CheckOut.CheckOutCommand{
			Nip:  c.FormValue("nip"),
			Nidn: c.FormValue("nidn"),
		}

		res, err := mediatr.Send[*CheckOut.CheckOutCommand, common.ResultValue[*domain.Absen]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Get("/history", func(c *fiber.Ctx) error {
		query := &GetAttendanceHistory.GetAttendanceHistoryQuery{
			Nidn: c.FormValue("nidn"),
			Nip:  c.FormValue("nip"),
		}

		res, err := mediatr.Send[*GetAttendanceHistory.GetAttendanceHistoryQuery, common.ResultValue[[]domain.Absen]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Absen]{}

		return sseAdapter.Send(c, pagedData)
	})

	group.Delete("/empty-masuk", func(c *fiber.Ctx) error {
		command := DeleteEmptyAttendance.DeleteEmptyAttendanceCommand{}

		res, err := mediatr.Send[*DeleteEmptyAttendance.DeleteEmptyAttendanceCommand, common.ResultValue[int64]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{
			"status":        "success",
			"message":       "Data absen dengan absen_masuk kosong berhasil dihapus",
			"deleted_count": res.Value,
		})
	})
}
