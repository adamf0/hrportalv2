package presentation

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/report/application/CalculateReport"
	"hrportal_backend/modules/report/application/GetAllLaporanAbsen"
	"hrportal_backend/modules/report/application/GetSummaryReport"
	"hrportal_backend/modules/report/application/StreamLaporanAbsen"
	"hrportal_backend/modules/report/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleReport(app *fiber.App) {
	group := app.Group("/api/laporan", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Get("/summary", func(c *fiber.Ctx) error {
		nidn := c.FormValue("nidn")
		nip := c.FormValue("nip")

		periodeTypeStr := c.Query("periode_type", "CALENDAR")
		periodeKey := c.Query("periode_key")

		query := &GetSummaryReport.GetSummaryReportQuery{
			Nip:         nip,
			Nidn:        nidn,
			PeriodeType: domain.PeriodeType(periodeTypeStr),
			PeriodeKey:  periodeKey,
		}

		res, err := mediatr.Send[*GetSummaryReport.GetSummaryReportQuery, common.ResultValue[*domain.RekapLaporanBulanan]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Get("/all", func(c *fiber.Ctx) error {
		nidn := c.FormValue("nidn")
		nip := c.FormValue("nip")

		query := &GetAllLaporanAbsen.GetAllLaporanAbsenQuery{
			TanggalMulai: c.Query("tanggal_mulai"),
			TanggalAkhir: c.Query("tanggal_akhir"),
			Nidn:         nidn,
			Nip:          nip,
		}

		res, err := mediatr.Send[*GetAllLaporanAbsen.GetAllLaporanAbsenQuery, common.ResultValue[map[string]interface{}]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	// SSE Endpoint
	group.Get("/stream", func(c *fiber.Ctx) error {
		nidn := c.FormValue("nidn")
		nip := c.FormValue("nip")

		query := &StreamLaporanAbsen.StreamLaporanAbsenQuery{
			TanggalMulai: c.Query("tanggal_mulai"),
			TanggalAkhir: c.Query("tanggal_akhir"),
			Nip:          nip,
			Nidn:         nidn,
			UserType:     c.Query("type"),
		}

		res, err := mediatr.Send[*StreamLaporanAbsen.StreamLaporanAbsenQuery, common.ResultValue[[]domain.FlatRecordItem]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.FlatRecordItem]{}

		return sseAdapter.Send(c, pagedData)
	})

	// API Endpoint for calculation of report v1 & v2 (Bypasses JWT/RBAC middleware via path matching)
	group.Get("/recalculate", func(c *fiber.Ctx) error {
		command := CalculateReport.CalculateReportCommand{}

		res, err := mediatr.Send[*CalculateReport.CalculateReportCommand, common.ResultValue[map[string]interface{}]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})
}
