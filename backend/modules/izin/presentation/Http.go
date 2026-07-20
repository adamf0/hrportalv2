package presentation

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"

	commondomain "hrportal_backend/common/domain"
	commoninfra "hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	create "hrportal_backend/modules/izin/application/CreateIzin"
	delete "hrportal_backend/modules/izin/application/DeleteIzin"
	getAll "hrportal_backend/modules/izin/application/GetAllIzins"
	get "hrportal_backend/modules/izin/application/GetIzin"
	update "hrportal_backend/modules/izin/application/UpdateIzin"
	"hrportal_backend/modules/izin/domain"
)

func ModuleIzin(app *fiber.App) {
	group := app.Group("/api/izin", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/", func(c *fiber.Ctx) error {
		jenisIzinID, _ := strconv.Atoi(c.FormValue("jenis_izin_id"))

		cmd := create.CreateIzinCommand{
			Nip:              c.FormValue("nip"),
			Nidn:             c.FormValue("nidn"),
			JenisIzinID:      uint(jenisIzinID),
			TanggalPengajuan: c.FormValue("tanggal_pengajuan"),
			Tujuan:           c.FormValue("tujuan"),
		}

		res, err := mediatr.Send[*create.CreateIzinCommand, commondomain.ResultValue[*domain.Izin]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Put("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))
		jenisIzinID, _ := strconv.Atoi(c.FormValue("jenis_izin_id"))

		cmd := update.UpdateIzinCommand{
			ID:               uint(id),
			JenisIzinID:      uint(jenisIzinID),
			TanggalPengajuan: c.FormValue("tanggal_pengajuan"),
			Tujuan:           c.FormValue("tujuan"),
			Status:           c.FormValue("status"),
		}

		res, err := mediatr.Send[*update.UpdateIzinCommand, commondomain.ResultValue[*domain.Izin]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Delete("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		cmd := delete.DeleteIzinCommand{
			ID: uint(id),
		}

		res, err := mediatr.Send[*delete.DeleteIzinCommand, commondomain.ResultValue[bool]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{"success": res.Value})
	})

	group.Get("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		query := get.GetIzinQuery{
			ID: uint(id),
		}

		res, err := mediatr.Send[*get.GetIzinQuery, commondomain.ResultValue[*domain.Izin]](c.UserContext(), &query)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Get("/", func(c *fiber.Ctx) error {
		nidn := c.FormValue("nidn")
		nip := c.FormValue("nip")

		query := getAll.GetAllIzinsQuery{
			Nidn: nidn,
			Nip:  nip,
		}

		res, err := mediatr.Send[*getAll.GetAllIzinsQuery, commondomain.ResultValue[[]domain.Izin]](c.UserContext(), &query)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		pagedData := commondomain.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Izin]{}

		return sseAdapter.Send(c, pagedData)
	})
}
