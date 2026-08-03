package presentation

import (
	"strconv"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/helper"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/ceremony_attendance/application/CreateAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/application/DeleteAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/application/GetAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/application/GetAllAbsenUpacaras"
	"hrportal_backend/modules/ceremony_attendance/application/UpdateAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleCeremonyAttendance(app *fiber.App) {
	group := app.Group("/api/ceremony-attendance", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/", func(c *fiber.Ctx) error {
		var command CreateAbsenUpacara.CreateAbsenUpacaraCommand
		if err := c.BodyParser(&command); err != nil {
			command = CreateAbsenUpacara.CreateAbsenUpacaraCommand{
				Nip:      c.FormValue("nip"),
				Nidn:     c.FormValue("nidn"),
				Nama:     c.FormValue("nama"),
				Unit:     c.FormValue("unit"),
				Fakultas: c.FormValue("fakultas"),
				Prodi:    c.FormValue("prodi"),
				Tanggal:  c.FormValue("tanggal"),
			}
		}

		res, err := mediatr.Send[*CreateAbsenUpacara.CreateAbsenUpacaraCommand, common.ResultValue[*domain.AbsenUpacara]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		// Trigger FCM Notification for Ceremony Attendance Success
		if res.Value != nil {
			upacaraData := res.Value
			targetNip := upacaraData.Nip
			if targetNip == "" {
				targetNip = upacaraData.Nidn
			}
			if targetNip != "" {
				helper.GlobalFcmManager.DispatchNotification(
					[]string{targetNip},
					"Presensi Upacara Berhasil",
					"Presensi Upacara Anda pada tanggal "+upacaraData.Tanggal+" telah berhasil dicatat.",
					"upacara",
					map[string]string{"type": "check-in-upacara", "id": strconv.Itoa(int(upacaraData.ID))},
				)
			}
		}

		return c.JSON(res.Value)
	})

	group.Put("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		var command UpdateAbsenUpacara.UpdateAbsenUpacaraCommand
		if err := c.BodyParser(&command); err != nil {
			command = UpdateAbsenUpacara.UpdateAbsenUpacaraCommand{
				Nip:     c.FormValue("nip"),
				Nidn:    c.FormValue("nidn"),
				Nama:    c.FormValue("nama"),
				Tanggal: c.FormValue("tanggal"),
			}
		}
		command.ID = uint(id)

		res, err := mediatr.Send[*UpdateAbsenUpacara.UpdateAbsenUpacaraCommand, common.ResultValue[*domain.AbsenUpacara]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Delete("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		command := DeleteAbsenUpacara.DeleteAbsenUpacaraCommand{
			ID: uint(id),
		}

		res, err := mediatr.Send[*DeleteAbsenUpacara.DeleteAbsenUpacaraCommand, common.ResultValue[bool]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(fiber.Map{"success": res.Value})
	})

	group.Get("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		query := GetAbsenUpacara.GetAbsenUpacaraQuery{
			ID: uint(id),
		}

		res, err := mediatr.Send[*GetAbsenUpacara.GetAbsenUpacaraQuery, common.ResultValue[*domain.AbsenUpacara]](c.UserContext(), &query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/", func(c *fiber.Ctx) error {
		query := GetAllAbsenUpacaras.GetAllAbsenUpacarasQuery{
			Nip:     c.FormValue("nip"),
			Nidn:    c.FormValue("nidn"),
			Tanggal: c.Query("tanggal"),
		}

		res, err := mediatr.Send[*GetAllAbsenUpacaras.GetAllAbsenUpacarasQuery, common.ResultValue[[]domain.AbsenUpacara]](c.UserContext(), &query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.AbsenUpacara]{}

		return sseAdapter.Send(c, pagedData)
	})
}
