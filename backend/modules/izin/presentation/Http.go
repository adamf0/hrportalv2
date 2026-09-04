package presentation

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"

	common "hrportal_backend/common/domain"
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

func registerIzinRoutes(group fiber.Router) {

	group.Post("/", func(c *fiber.Ctx) error {
		jenisIzinID, _ := strconv.Atoi(c.FormValue("id_jenis_izin"))
		if jenisIzinID == 0 {
			jenisIzinID, _ = strconv.Atoi(c.FormValue("jenis_izin_id"))
		}
		if jenisIzinID == 0 {
			jenisIzinID, _ = strconv.Atoi(c.FormValue("jenis_izin"))
		}

		tanggalPengajuan := c.FormValue("tanggal_pengajuan")
		if tanggalPengajuan == "" {
			tanggalPengajuan = c.FormValue("tanggal")
		}
		if tanggalPengajuan == "" {
			tanggalPengajuan = c.FormValue("tanggal_mulai")
		}

		var verifikasi *string
		vStr := c.FormValue("verifikasi")
		if vStr == "" {
			vStr = c.FormValue("nip_atasan")
		}
		if vStr != "" {
			verifikasi = &vStr
		}

		var fileLampiran *string
		fStr := c.FormValue("file_lampiran")
		if fStr == "" {
			fStr = c.FormValue("file")
		}
		if fStr == "" {
			fStr = c.FormValue("dokumen")
		}
		if fStr != "" {
			fileLampiran = &fStr
		}

		cmd := create.CreateIzinCommand{
			Nip:              c.FormValue("nip"),
			Nidn:             c.FormValue("nidn"),
			NamaPemohon:      c.FormValue("nama"),
			Unit:             c.FormValue("unit"),
			Fakultas:         c.FormValue("fakultas"),
			Prodi:            c.FormValue("prodi"),
			JenisIzinID:      uint(jenisIzinID),
			TanggalPengajuan: tanggalPengajuan,
			Tujuan:           c.FormValue("tujuan"),
			FileLampiran:     fileLampiran,
			Verifikasi:       verifikasi,
		}

		res, err := mediatr.Send[*create.CreateIzinCommand, common.ResultValue[*domain.Izin]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		// Trigger Notification for Create Izin
		if res.Value != nil {
			iz := res.Value
			helper.GlobalSdmWsHub.Broadcast(fiber.Map{"event": "izin_updated", "module": "izin", "data": iz})
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

		var fileLampiran *string
		fStr := c.FormValue("file_lampiran")
		if fStr == "" {
			fStr = c.FormValue("file")
		}
		if fStr == "" {
			fStr = c.FormValue("dokumen")
		}
		if fStr != "" {
			fileLampiran = &fStr
		}

		cmd := update.UpdateIzinCommand{
			ID:               uint(id),
			NamaPemohon:      c.FormValue("nama"),
			Unit:             c.FormValue("unit"),
			Fakultas:         c.FormValue("fakultas"),
			Prodi:            c.FormValue("prodi"),
			JenisIzinID:      uint(jenisIzinID),
			TanggalPengajuan: c.FormValue("tanggal_pengajuan"),
			Tujuan:           c.FormValue("tujuan"),
			FileLampiran:     fileLampiran,
			Status:           c.FormValue("status"),
			Catatan:          catatan,
			IsSdm:            c.FormValue("role") == "sdm",
		}

		res, err := mediatr.Send[*update.UpdateIzinCommand, common.ResultValue[*domain.Izin]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		// Trigger Notification for Update/Verify Izin
		if res.Value != nil {
			iz := res.Value
			helper.GlobalSdmWsHub.Broadcast(fiber.Map{"event": "izin_updated", "module": "izin", "data": iz})
		}

		return c.JSON(res.Value)
	})

	group.Delete("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		cmd := delete.DeleteIzinCommand{
			ID: uint(id),
		}

		res, err := mediatr.Send[*delete.DeleteIzinCommand, common.ResultValue[bool]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{"success": res.Value})
	})

	getIzinList := func(c *fiber.Ctx, forceVerif bool) error {
		nip := c.FormValue("nip")
		if nip == "" {
			nip = c.Query("nip")
		}
		if nip == "" {
			nip = string(c.Request().PostArgs().Peek("nip"))
		}
		nidn := c.FormValue("nidn")
		if nidn == "" {
			nidn = c.Query("nidn")
		}
		if nidn == "" {
			nidn = string(c.Request().PostArgs().Peek("nidn"))
		}
		role := c.FormValue("role")
		if role == "" {
			role = string(c.Request().PostArgs().Peek("role"))
		}
		isSdm := (role == "sdm" || role == "baum" || c.Query("role") == "sdm" || c.Query("role") == "baum")

		isVerif := forceVerif || c.Query("verifikasi") == "haxor" || c.Query("verifikasi") == "true"

		query := getAll.GetAllIzinsQuery{
			Nidn:         nidn,
			Nip:          nip,
			Verifikasi:   isVerif,
			IsSdm:        isSdm,
			TanggalMulai: helper.StrPtr(c.Query("tanggal_mulai")),
			TanggalAkhir: helper.StrPtr(c.Query("tanggal_akhir")),
		}

		res, err := mediatr.Send[*getAll.GetAllIzinsQuery, common.ResultValue[[]domain.Izin]](c.UserContext(), &query)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Izin]{}

		return sseAdapter.Send(c, pagedData)
	}

	group.Get("/verifikasi", func(c *fiber.Ctx) error {
		return getIzinList(c, true)
	})

	group.Get("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		query := get.GetIzinQuery{
			ID: uint(id),
		}

		res, err := mediatr.Send[*get.GetIzinQuery, common.ResultValue[*domain.Izin]](c.UserContext(), &query)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Get("/", func(c *fiber.Ctx) error {
		return getIzinList(c, false)
	})
}

func ModuleIzin(app *fiber.App) {
	groupV2 := app.Group("/api/v2/izin", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerIzinRoutes(groupV2)

	groupV1 := app.Group("/api/izin", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerIzinRoutes(groupV1)
}
