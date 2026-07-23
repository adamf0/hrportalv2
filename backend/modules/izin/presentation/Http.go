package presentation

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"

	commondomain "hrportal_backend/common/domain"
	"hrportal_backend/common/helper"
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
		jenisIzinID, _ := strconv.Atoi(c.FormValue("id_jenis_izin"))

		var verifikasi *string
		vStr := c.FormValue("verifikasi")
		if vStr != "" {
			verifikasi = &vStr
		}

		cmd := create.CreateIzinCommand{
			Nip:              c.FormValue("nip"),
			Nidn:             c.FormValue("nidn"),
			JenisIzinID:      uint(jenisIzinID),
			TanggalPengajuan: c.FormValue("tanggal_pengajuan"),
			Tujuan:           c.FormValue("tujuan"),
			Verifikasi:       verifikasi,
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
		jenisIzinID, _ := strconv.Atoi(c.FormValue("id_jenis_izin"))

		var catatan *string
		cStr := c.FormValue("catatan")
		if cStr != "" {
			catatan = &cStr
		}

		cmd := update.UpdateIzinCommand{
			ID:               uint(id),
			JenisIzinID:      uint(jenisIzinID),
			TanggalPengajuan: c.FormValue("tanggal_pengajuan"),
			Tujuan:           c.FormValue("tujuan"),
			Status:           c.FormValue("status"),
			Catatan:          catatan,
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
		isSdm := c.FormValue("role") == "sdm"

		query := getAll.GetAllIzinsQuery{
			Nidn:         nidn,
			Nip:          nip,
			IsSdm:        isSdm,
			TanggalMulai: helper.StrPtr(c.Query("tanggal_mulai")),
			TanggalAkhir: helper.StrPtr(c.Query("tanggal_akhir")),
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
