package presentation

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"

	common "hrportal_backend/common/domain"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/payroll/application/GetSlipGaji"
	"hrportal_backend/modules/payroll/domain"
)

func registerPayrollRoutes(group fiber.Router) {
	group.Get("/", func(c *fiber.Ctx) error {
		nip := strings.TrimSpace(c.Query("nip"))
		if nip == "" {
			nip = strings.TrimSpace(c.FormValue("nip"))
		}
		if nip == "" {
			nip = strings.TrimSpace(c.FormValue("sid"))
		}

		query := &GetSlipGaji.GetSlipGajiQuery{
			Tahun: c.Query("tahun"),
			Bulan: c.Query("bulan"),
			Nip:   nip,
		}

		res, err := mediatr.Send[*GetSlipGaji.GetSlipGajiQuery, common.ResultValue[*domain.SlipGaji]](c.UserContext(), query)
		if err != nil {
			return c.JSON(fiber.Map{
				"status":  "fail",
				"message": err.Error(),
				"data":    nil,
			})
		}

		if !res.IsSuccess {
			return c.JSON(fiber.Map{
				"status":  "fail",
				"message": res.Error.Description,
				"data":    nil,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": nil,
			"data":    res.Value,
		})
	})
}

func ModulePayroll(app *fiber.App) {
	groupV2 := app.Group("/api/v2/payroll", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerPayrollRoutes(groupV2)

	groupV1 := app.Group("/api/payroll", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerPayrollRoutes(groupV1)
}
