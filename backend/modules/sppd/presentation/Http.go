package presentation

import (
	"strconv"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/helper"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/sppd/application/CreateSppd"
	"hrportal_backend/modules/sppd/application/DeleteSppd"
	"hrportal_backend/modules/sppd/application/GetSppd"
	"hrportal_backend/modules/sppd/application/GetSppdHistory"
	"hrportal_backend/modules/sppd/application/UpdateSppd"
	"hrportal_backend/modules/sppd/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleSppd(app *fiber.App) {
	group := app.Group("/api/sppd", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/create", func(c *fiber.Ctx) error {
		var command CreateSppd.CreateSppdCommand
		_ = c.BodyParser(&command)
		if command.JenisSppdID == 0 && command.TanggalBerangkat == "" {
			jenisSppdID, _ := strconv.Atoi(c.FormValue("jenis_sppd_id"))
			var verifikasi *string
			vStr := c.FormValue("verifikasi")
			if vStr != "" {
				verifikasi = &vStr
			}
			command = CreateSppd.CreateSppdCommand{
				Nidn:             c.FormValue("nidn"),
				Nip:              c.FormValue("nip"),
				Tujuan:           c.FormValue("tujuan"),
				JenisSppdID:      uint(jenisSppdID),
				TanggalBerangkat: c.FormValue("tanggal_berangkat"),
				TanggalKembali:   c.FormValue("tanggal_kembali"),
				Keterangan:       c.FormValue("keterangan"),
				Verifikasi:       verifikasi,
			}
		}

		res, err := mediatr.Send[*CreateSppd.CreateSppdCommand, common.ResultValue[*domain.Sppd]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Put("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		var command UpdateSppd.UpdateSppdCommand
		_ = c.BodyParser(&command)
		if command.JenisSppdID == 0 && command.TanggalBerangkat == "" {
			jenisSppdID, _ := strconv.Atoi(c.FormValue("jenis_sppd_id"))
			command = UpdateSppd.UpdateSppdCommand{
				Nidn:             c.FormValue("nidn"),
				Nip:              c.FormValue("nip"),
				Tujuan:           c.FormValue("tujuan"),
				JenisSppdID:      uint(jenisSppdID),
				TanggalBerangkat: c.FormValue("tanggal_berangkat"),
				TanggalKembali:   c.FormValue("tanggal_kembali"),
				Keterangan:       c.FormValue("keterangan"),
				Status:           c.FormValue("status"),
			}
		}
		command.ID = uint(id)

		res, err := mediatr.Send[*UpdateSppd.UpdateSppdCommand, common.ResultValue[*domain.Sppd]](c.UserContext(), &command)
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

		command := DeleteSppd.DeleteSppdCommand{
			ID: uint(id),
		}

		res, err := mediatr.Send[*DeleteSppd.DeleteSppdCommand, common.ResultValue[bool]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{"success": res.Value})
	})

	group.Get("/history", func(c *fiber.Ctx) error {
		nip := c.FormValue("nip")
		nidn := c.FormValue("nidn")
		isSdm := c.FormValue("role") == "sdm"

		query := &GetSppdHistory.GetSppdHistoryQuery{
			Nip:          nip,
			Nidn:         nidn,
			Verifikasi:   c.Query("verifikasi") == "haxor",
			IsSdm:        isSdm,
			TanggalMulai: helper.StrPtr(c.Query("tanggal_mulai")),
			TanggalAkhir: helper.StrPtr(c.Query("tanggal_akhir")),
		}

		res, err := mediatr.Send[*GetSppdHistory.GetSppdHistoryQuery, common.ResultValue[[]domain.Sppd]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Sppd]{}

		return sseAdapter.Send(c, pagedData)
	})

	group.Get("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		query := GetSppd.GetSppdQuery{
			ID: uint(id),
		}

		res, err := mediatr.Send[*GetSppd.GetSppdQuery, common.ResultValue[*domain.Sppd]](c.UserContext(), &query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})
}
