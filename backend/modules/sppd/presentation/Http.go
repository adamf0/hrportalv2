package presentation

import (
	"encoding/json"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/helper"
	commoninfra "hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	create "hrportal_backend/modules/sppd/application/CreateSppd"
	delete "hrportal_backend/modules/sppd/application/DeleteSppd"
	get "hrportal_backend/modules/sppd/application/GetSppd"
	getHistory "hrportal_backend/modules/sppd/application/GetSppdHistory"
	update "hrportal_backend/modules/sppd/application/UpdateSppd"
	"hrportal_backend/modules/sppd/domain"
)

func ModuleSppd(app *fiber.App) {
	group := app.Group("/api/sppd", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/create", func(c *fiber.Ctx) error {
		jenisSppdID, _ := strconv.Atoi(c.FormValue("jenis_sppd_id"))
		if jenisSppdID == 0 {
			jenisSppdID, _ = strconv.Atoi(c.FormValue("id_jenis_sppd"))
		}
		if jenisSppdID == 0 {
			jenisSppdID, _ = strconv.Atoi(c.FormValue("jenis_sppd"))
		}

		tanggalBerangkat := c.FormValue("tanggal_berangkat")
		if tanggalBerangkat == "" {
			tanggalBerangkat = c.FormValue("tanggal_mulai")
		}

		tanggalKembali := c.FormValue("tanggal_kembali")
		if tanggalKembali == "" {
			tanggalKembali = c.FormValue("tanggal_selesai")
		}

		var verifikasi *string
		vStr := c.FormValue("verifikasi")
		if vStr == "" {
			vStr = c.FormValue("nip_atasan")
		}
		if vStr != "" {
			verifikasi = &vStr
		}

		cmd := create.CreateSppdCommand{
			Nip:              c.FormValue("nip"),
			Nidn:             c.FormValue("nidn"),
			NamaPemohon:      c.FormValue("nama"),
			Unit:             c.FormValue("unit"),
			Fakultas:         c.FormValue("fakultas"),
			Prodi:            c.FormValue("prodi"),
			Tujuan:           c.FormValue("tujuan"),
			JenisSppdID:      uint(jenisSppdID),
			TanggalBerangkat: tanggalBerangkat,
			TanggalKembali:   tanggalKembali,
			Keterangan:       c.FormValue("keterangan"),
			Verifikasi:       verifikasi,
		}

		if len(cmd.Anggota) == 0 {
			anggotaJson := c.FormValue("anggota")
			if anggotaJson != "" {
				_ = json.Unmarshal([]byte(anggotaJson), &cmd.Anggota)
			}
		}

		if len(cmd.Files) == 0 {
			filesJson := c.FormValue("files")
			if filesJson != "" {
				_ = json.Unmarshal([]byte(filesJson), &cmd.Files)
			}
		}

		res, err := mediatr.Send[*create.CreateSppdCommand, common.ResultValue[*domain.Sppd]](c.UserContext(), &cmd)
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
		jenisSppdID, _ := strconv.Atoi(c.FormValue("jenis_sppd_id"))
		if jenisSppdID == 0 {
			jenisSppdID, _ = strconv.Atoi(c.FormValue("jenis_sppd"))
		}

		var verifikasi *string
		vStr := c.FormValue("verifikasi")
		if vStr != "" {
			verifikasi = &vStr
		}

		var catatan *string
		cStr := c.FormValue("catatan")
		if cStr != "" {
			catatan = &cStr
		}

		cmd := update.UpdateSppdCommand{
			ID:               uint(id),
			Nip:              c.FormValue("nip"),
			Nidn:             c.FormValue("nidn"),
			NamaPemohon:      c.FormValue("nama"),
			Unit:             c.FormValue("unit"),
			Fakultas:         c.FormValue("fakultas"),
			Prodi:            c.FormValue("prodi"),
			Tujuan:           c.FormValue("tujuan"),
			JenisSppdID:      uint(jenisSppdID),
			TanggalBerangkat: c.FormValue("tanggal_berangkat"),
			TanggalKembali:   c.FormValue("tanggal_kembali"),
			Keterangan:       c.FormValue("keterangan"),
			Verifikasi:       verifikasi,
			Status:           c.FormValue("status"),
			Catatan:          catatan,
			IsSdm:            c.FormValue("role") == "sdm",
		}

		if len(cmd.Anggota) == 0 {
			anggotaJson := c.FormValue("anggota")
			if anggotaJson != "" {
				_ = json.Unmarshal([]byte(anggotaJson), &cmd.Anggota)
			}
		}

		if len(cmd.Files) == 0 {
			filesJson := c.FormValue("files")
			if filesJson != "" {
				_ = json.Unmarshal([]byte(filesJson), &cmd.Files)
			}
		}

		res, err := mediatr.Send[*update.UpdateSppdCommand, common.ResultValue[*domain.Sppd]](c.UserContext(), &cmd)
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

		cmd := delete.DeleteSppdCommand{
			ID: uint(id),
		}

		res, err := mediatr.Send[*delete.DeleteSppdCommand, common.ResultValue[bool]](c.UserContext(), &cmd)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{"success": res.Value})
	})

	group.Get("/history", func(c *fiber.Ctx) error {
		nip := c.FormValue("nip")
		nidn := c.FormValue("nidn")
		role := c.FormValue("role")
		if role == "" {
			role = string(c.Request().PostArgs().Peek("role"))
		}
		isSdm := (role == "sdm" || role == "baum" || c.Query("role") == "sdm" || c.Query("role") == "baum")

		query := &getHistory.GetSppdHistoryQuery{
			Nip:          nip,
			Nidn:         nidn,
			Verifikasi:   c.Query("verifikasi") == "haxor",
			IsSdm:        isSdm,
			TanggalMulai: helper.StrPtr(c.Query("tanggal_mulai")),
			TanggalAkhir: helper.StrPtr(c.Query("tanggal_akhir")),
		}

		res, err := mediatr.Send[*getHistory.GetSppdHistoryQuery, common.ResultValue[[]domain.Sppd]](c.UserContext(), query)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Sppd]{}

		return sseAdapter.Send(c, pagedData)
	})

	group.Get("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		query := get.GetSppdQuery{
			ID: uint(id),
		}

		res, err := mediatr.Send[*get.GetSppdQuery, common.ResultValue[*domain.Sppd]](c.UserContext(), &query)
		if err != nil {
			return commoninfra.HandleError(c, err)
		}

		if !res.IsSuccess {
			return commoninfra.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})
}
