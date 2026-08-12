package presentation

import (
	"strconv"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/holiday/application/GetHolidays"
	"hrportal_backend/modules/holiday/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func ModuleHoliday(app *fiber.App, db *gorm.DB) {
	group := app.Group("/api/holiday", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Get("/", func(c *fiber.Ctx) error {
		return getHolidaysHandler(c)
	})

	group.Post("/", func(c *fiber.Ctx) error {
		var item domain.MasterLibur
		if err := c.BodyParser(&item); err != nil {
			item.Nama = c.FormValue("nama")
			item.Tanggal = c.FormValue("tanggal")
			item.Type = c.FormValue("type")
			isNatStr := c.FormValue("is_national_holiday")
			item.IsNationalHoliday = isNatStr == "true" || isNatStr == "1"
		}
		if item.HolidayID == "" {
			item.HolidayID = "libur-" + strconv.FormatInt(time.Now().UnixNano(), 10)
		}
		if item.Type == "" {
			item.Type = "Libur Nasional"
		}
		if err := db.Create(&item).Error; err != nil {
			return infrastructure.HandleError(c, err)
		}
		return c.Status(201).JSON(item)
	})

	group.Put("/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		var existing domain.MasterLibur
		if err := db.First(&existing, "id = ?", id).Error; err != nil {
			return infrastructure.HandleError(c, err)
		}

		var updateData domain.MasterLibur
		if err := c.BodyParser(&updateData); err != nil {
			updateData.Nama = c.FormValue("nama")
			updateData.Tanggal = c.FormValue("tanggal")
			updateData.Type = c.FormValue("type")
			isNatStr := c.FormValue("is_national_holiday")
			updateData.IsNationalHoliday = isNatStr == "true" || isNatStr == "1"
		}

		if updateData.Nama != "" {
			existing.Nama = updateData.Nama
		}
		if updateData.Tanggal != "" {
			existing.Tanggal = updateData.Tanggal
		}
		if updateData.Type != "" {
			existing.Type = updateData.Type
		}
		existing.IsNationalHoliday = updateData.IsNationalHoliday

		if err := db.Save(&existing).Error; err != nil {
			return infrastructure.HandleError(c, err)
		}
		return c.JSON(existing)
	})

	group.Delete("/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		if err := db.Delete(&domain.MasterLibur{}, "id = ?", id).Error; err != nil {
			return infrastructure.HandleError(c, err)
		}
		return c.JSON(fiber.Map{"status": "ok", "message": "Hari libur berhasil dihapus"})
	})
}

func getHolidaysHandler(c *fiber.Ctx) error {
	year := 0
	yearStr := c.Query("year")
	if yearStr != "" {
		if y, err := strconv.Atoi(yearStr); err == nil {
			year = y
		}
	}

	query := &GetHolidays.GetHolidaysQuery{
		Year: year,
	}

	res, err := mediatr.Send[*GetHolidays.GetHolidaysQuery, common.ResultValue[[]domain.MasterLibur]](c.UserContext(), query)
	if err != nil {
		return infrastructure.HandleError(c, err)
	}
	if !res.IsSuccess {
		return infrastructure.HandleError(c, res.Error)
	}

	list := res.Value
	pagedData := common.NewPaged(list, int64(len(list)), 1, len(list))
	sseAdapter := &commonpresentation.SSEAdapter[domain.MasterLibur]{}

	return sseAdapter.Send(c, pagedData)
}
