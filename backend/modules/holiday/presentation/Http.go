package presentation

import (
	"strconv"
	"strings"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/holiday/domain"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

func ModuleHoliday(app *fiber.App, db *gorm.DB) {
	// Register public /holiday route
	app.Get("/holiday", func(c *fiber.Ctx) error {
		return getHolidaysHandler(c, db)
	})

	// Register protected /api/holiday route
	group := app.Group("/api/holiday", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	group.Get("/", func(c *fiber.Ctx) error {
		return getHolidaysHandler(c, db)
	})
}

func getHolidaysHandler(c *fiber.Ctx, db *gorm.DB) error {
	var list []domain.MasterLibur
	query := db.Model(&domain.MasterLibur{})

	yearStr := c.Query("year")
	if yearStr != "" {
		year, err := strconv.Atoi(yearStr)
		if err == nil {
			query = query.Where("YEAR(tanggal) = ?", year)
		}
	}

	err := query.Order("tanggal asc").Find(&list).Error
	if err != nil {
		return infrastructure.HandleError(c, err)
	}

	// Populate dynamic 'libur' field: 1 if type contains "Holiday" or is_national_holiday is true/1, else 0
	for i := range list {
		if strings.Contains(list[i].Type, "Holiday") || list[i].IsNationalHoliday {
			list[i].Libur = 1
		} else {
			list[i].Libur = 0
		}
	}

	pagedData := common.NewPaged(list, int64(len(list)), 1, len(list))
	sseAdapter := &commonpresentation.SSEAdapter[domain.MasterLibur]{}

	return sseAdapter.Send(c, pagedData)
}
