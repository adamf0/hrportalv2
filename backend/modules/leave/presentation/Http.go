package presentation

import (
	"os"
	"strconv"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/helper"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/leave/application/DeleteCuti"
	"hrportal_backend/modules/leave/application/GetAllCuti"
	"hrportal_backend/modules/leave/application/GetCuti"
	"hrportal_backend/modules/leave/application/SubmitCuti"
	"hrportal_backend/modules/leave/application/UpdateCuti"
	"hrportal_backend/modules/leave/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleLeave(app *fiber.App) {
	group := app.Group("/api/leave", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/submit", func(c *fiber.Ctx) error {
		jenisCutiID, _ := strconv.Atoi(c.FormValue("jenis_cuti_id"))
		jumlahHari, _ := strconv.Atoi(c.FormValue("jumlah_hari"))

		var nipAtasan *string
		nipAtasanStr := c.FormValue("nip_atasan")
		if nipAtasanStr != "" {
			nipAtasan = &nipAtasanStr
		}

		var fileLampiran *string
		file, err := c.FormFile("file_lampiran")
		if err == nil && file != nil {
			_ = os.MkdirAll("./uploads", os.ModePerm)
			savePath := "./uploads/" + file.Filename
			_ = c.SaveFile(file, savePath)
			fileLampiran = &savePath
		} else {
			fileVal := c.FormValue("file_lampiran")
			if fileVal != "" {
				fileLampiran = &fileVal
			}
		}

		command := SubmitCuti.SubmitCutiCommand{
			Nidn:           c.FormValue("nidn"),
			Nip:            c.FormValue("nip"),
			JenisCutiID:    uint(jenisCutiID),
			TanggalMulai:   c.FormValue("tanggal_mulai"),
			TanggalSelesai: c.FormValue("tanggal_selesai"),
			JumlahHari:     jumlahHari,
			Alasan:         c.FormValue("alasan"),
			NipAtasan:      nipAtasan,
			FileLampiran:   fileLampiran,
		}

		res, err := mediatr.Send[*SubmitCuti.SubmitCutiCommand, common.ResultValue[*domain.Cuti]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		// Trigger FCM Notification for Submit Cuti
		if res.Value != nil {
			cutiData := res.Value
			if cutiData.NipAtasan != nil && *cutiData.NipAtasan != "" {
				targets := []string{*cutiData.NipAtasan}
				title := "Pengajuan Cuti Baru"
				body := "Pegawai NIP " + cutiData.Nip + " mengajukan Cuti baru. Mohon verifikasi."
				payload := map[string]string{"type": "cuti", "id": strconv.Itoa(int(cutiData.ID)), "status": cutiData.Status}
				helper.GlobalFcmManager.DispatchNotification(targets, title, body, "cuti", payload)
			}
		}

		return c.JSON(res.Value)
	})

	group.Put("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))
		jenisCutiID, _ := strconv.Atoi(c.FormValue("jenis_cuti_id"))
		if jenisCutiID == 0 {
			jenisCutiID, _ = strconv.Atoi(c.FormValue("id_jenis_izin"))
		}
		jumlahHari, _ := strconv.Atoi(c.FormValue("jumlah_hari"))

		var fileLampiran *string
		file, err := c.FormFile("file_lampiran")
		if err == nil && file != nil {
			_ = os.MkdirAll("./uploads", os.ModePerm)
			savePath := "./uploads/" + file.Filename
			_ = c.SaveFile(file, savePath)
			fileLampiran = &savePath
		} else {
			fileVal := c.FormValue("file_lampiran")
			if fileVal != "" {
				fileLampiran = &fileVal
			}
		}

		var catatanAtasan *string
		catatan := c.FormValue("catatan_atasan")
		if catatan != "" {
			catatanAtasan = &catatan
		}

		command := UpdateCuti.UpdateCutiCommand{
			ID:             uint(id),
			JenisCutiID:    uint(jenisCutiID),
			TanggalMulai:   c.FormValue("tanggal_mulai"),
			TanggalSelesai: c.FormValue("tanggal_selesai"),
			JumlahHari:     jumlahHari,
			Alasan:         c.FormValue("alasan"),
			FileLampiran:   fileLampiran,
			Status:         c.FormValue("status"),
			CatatanAtasan:  catatanAtasan,
		}

		res, err := mediatr.Send[*UpdateCuti.UpdateCutiCommand, common.ResultValue[*domain.Cuti]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		// Trigger FCM Notification for Update/Verify Cuti
		if res.Value != nil {
			cutiData := res.Value
			status := cutiData.Status

			atasanNip := ""
			if cutiData.Verifikasi != nil && *cutiData.Verifikasi != "" {
				atasanNip = *cutiData.Verifikasi
			} else if cutiData.NipAtasan != nil && *cutiData.NipAtasan != "" {
				atasanNip = *cutiData.NipAtasan
			}

			switch status {
			case "terima atasan":
				helper.GlobalFcmManager.DispatchNotification([]string{cutiData.Nip}, "Pengajuan Cuti Disetujui Atasan", "Pengajuan Cuti Anda telah disetujui Atasan. Menunggu verifikasi SDM.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})
				helper.GlobalFcmManager.DispatchNotification([]string{"SDM_BROADCAST"}, "Verifikasi SDM Cuti", "Pengajuan Cuti NIP "+cutiData.Nip+" telah disetujui Atasan. Mohon verifikasi final SDM.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})

			case "tolak atasan":
				helper.GlobalFcmManager.DispatchNotification([]string{cutiData.Nip}, "Pengajuan Cuti Ditolak Atasan", "Pengajuan Cuti Anda ditolak oleh Atasan.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})

			case "terima sdm":
				helper.GlobalFcmManager.DispatchNotification([]string{cutiData.Nip}, "Pengajuan Cuti Disetujui SDM", "Selamat! Pengajuan Cuti Anda telah disetujui oleh SDM.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})
				if atasanNip != "" && atasanNip != cutiData.Nip {
					helper.GlobalFcmManager.DispatchNotification([]string{atasanNip}, "Status Final Cuti", "Pengajuan Cuti NIP "+cutiData.Nip+" telah disetujui oleh SDM.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})
				}

			case "tolak sdm":
				helper.GlobalFcmManager.DispatchNotification([]string{cutiData.Nip}, "Pengajuan Cuti Ditolak SDM", "Pengajuan Cuti Anda ditolak oleh SDM.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})
				if atasanNip != "" && atasanNip != cutiData.Nip {
					helper.GlobalFcmManager.DispatchNotification([]string{atasanNip}, "Status Final Cuti", "Pengajuan Cuti NIP "+cutiData.Nip+" ditolak oleh SDM.", "cuti", map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status})
				}
			}
		}

		return c.JSON(res.Value)
	})

	group.Delete("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		command := DeleteCuti.DeleteCutiCommand{
			ID: uint(id),
		}

		res, err := mediatr.Send[*DeleteCuti.DeleteCutiCommand, common.ResultValue[bool]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{"success": res.Value})
	})

	group.Get("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))

		query := GetCuti.GetCutiQuery{
			ID: uint(id),
		}

		res, err := mediatr.Send[*GetCuti.GetCutiQuery, common.ResultValue[*domain.Cuti]](c.UserContext(), &query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})

	group.Get("/", func(c *fiber.Ctx) error {
		nip := c.FormValue("nip")
		nidn := c.FormValue("nidn")
		isSdm := c.FormValue("role") == "sdm"

		query := &GetAllCuti.GetAllCutiQuery{
			Nip:          nip,
			Nidn:         nidn,
			Verifikasi:   c.Query("verifikasi") == "haxor",
			IsSdm:        isSdm,
			TanggalMulai: helper.StrPtr(c.Query("tanggal_mulai")),
			TanggalAkhir: helper.StrPtr(c.Query("tanggal_akhir")),
		}

		res, err := mediatr.Send[*GetAllCuti.GetAllCutiQuery, common.ResultValue[[]domain.Cuti]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Cuti]{}

		return sseAdapter.Send(c, pagedData)
	})
}
