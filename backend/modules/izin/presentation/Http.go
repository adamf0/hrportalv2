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

		// Trigger FCM Notification for Create Izin
		if res.Value != nil {
			iz := res.Value
			if iz.Verifikasi != nil && *iz.Verifikasi != "" {
				targets := []string{*iz.Verifikasi}
				title := "Pengajuan Izin Baru"
				body := "Pegawai NIP " + iz.Nip + " mengajukan Izin baru. Mohon verifikasi."
				payload := map[string]string{"type": "izin", "id": strconv.Itoa(int(iz.ID)), "status": iz.Status}
				helper.GlobalFcmManager.DispatchNotification(targets, title, body, "izin", payload)
			}
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

		// Trigger FCM Notification for Update/Verify Izin
		if res.Value != nil {
			iz := res.Value
			status := iz.Status
			atasanNip := ""
			if iz.Verifikasi != nil && *iz.Verifikasi != "" {
				atasanNip = *iz.Verifikasi
			}

			switch status {
			case "terima atasan":
				helper.GlobalFcmManager.DispatchNotification([]string{iz.Nip}, "Pengajuan Izin Disetujui Atasan", "Pengajuan Izin Anda telah disetujui Atasan. Menunggu verifikasi SDM.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})
				helper.GlobalFcmManager.DispatchNotification([]string{"SDM_BROADCAST"}, "Verifikasi SDM Izin", "Pengajuan Izin NIP "+iz.Nip+" telah disetujui Atasan. Mohon verifikasi final SDM.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})

			case "tolak atasan":
				helper.GlobalFcmManager.DispatchNotification([]string{iz.Nip}, "Pengajuan Izin Ditolak Atasan", "Pengajuan Izin Anda ditolak oleh Atasan.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})

			case "terima sdm":
				helper.GlobalFcmManager.DispatchNotification([]string{iz.Nip}, "Pengajuan Izin Disetujui SDM", "Selamat! Pengajuan Izin Anda telah disetujui oleh SDM.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})
				if atasanNip != "" {
					helper.GlobalFcmManager.DispatchNotification([]string{atasanNip}, "Status Final Izin", "Pengajuan Izin NIP "+iz.Nip+" telah disetujui oleh SDM.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})
				}

			case "tolak sdm":
				helper.GlobalFcmManager.DispatchNotification([]string{iz.Nip}, "Pengajuan Izin Ditolak SDM", "Pengajuan Izin Anda ditolak oleh SDM.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})
				if atasanNip != "" {
					helper.GlobalFcmManager.DispatchNotification([]string{atasanNip}, "Status Final Izin", "Pengajuan Izin NIP "+iz.Nip+" ditolak oleh SDM.", "izin", map[string]string{"id": strconv.Itoa(int(iz.ID)), "status": status})
				}
			}
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
			Verifikasi:   c.Query("verifikasi") == "haxor",
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
