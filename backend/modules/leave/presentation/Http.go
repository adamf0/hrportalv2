package presentation

import (
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
	"hrportal_backend/modules/notification/application/CreateNotification"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func registerLeaveRoutes(group fiber.Router) {

	group.Post("/submit", func(c *fiber.Ctx) error {
		jenisCutiID, _ := strconv.Atoi(c.FormValue("jenis_cuti_id"))
		if jenisCutiID == 0 {
			jenisCutiID, _ = strconv.Atoi(c.FormValue("id_jenis_cuti"))
		}
		if jenisCutiID == 0 {
			jenisCutiID, _ = strconv.Atoi(c.FormValue("jenis_cuti"))
		}

		jumlahHari, _ := strconv.Atoi(c.FormValue("jumlah_hari"))
		if jumlahHari == 0 {
			jumlahHari, _ = strconv.Atoi(c.FormValue("lama_cuti"))
		}

		tanggalMulai := c.FormValue("tanggal_mulai")
		if tanggalMulai == "" {
			tanggalMulai = c.FormValue("tanggal_pengajuan")
		}

		tanggalSelesai := c.FormValue("tanggal_selesai")
		if tanggalSelesai == "" {
			tanggalSelesai = c.FormValue("tanggal_akhir")
		}

		var nipAtasan *string
		nipAtasanStr := c.FormValue("nip_atasan")
		if nipAtasanStr == "" {
			nipAtasanStr = c.FormValue("verifikasi")
		}
		if nipAtasanStr != "" {
			nipAtasan = &nipAtasanStr
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

		command := SubmitCuti.SubmitCutiCommand{
			Nidn:           c.FormValue("nidn"),
			Nip:            c.FormValue("nip"),
			NamaPemohon:    c.FormValue("nama"),
			Unit:           c.FormValue("unit"),
			Fakultas:       c.FormValue("fakultas"),
			Prodi:          c.FormValue("prodi"),
			JenisCutiID:    uint(jenisCutiID),
			TanggalMulai:   tanggalMulai,
			TanggalSelesai: tanggalSelesai,
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

		// Trigger Notification for Submit Cuti
		if res.Value != nil {
			cutiData := res.Value
			helper.GlobalSdmWsHub.Broadcast(fiber.Map{"event": "cuti_updated", "module": "leave", "data": cutiData})

			// 1. Notify Atasan (Verifikator)
			if cutiData.Verifikasi != nil && *cutiData.Verifikasi != "" {
				targets := []string{*cutiData.Verifikasi}
				title := "Pengajuan Cuti Baru"
				body := "Pegawai NIP " + cutiData.Nip + " NIDN " + cutiData.Nidn + " mengajukan Cuti baru. Mohon verifikasi."
				payload := map[string]string{"type": "cuti", "id": strconv.Itoa(int(cutiData.ID)), "status": cutiData.Status}
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: targets,
					Title:      title,
					Body:       body,
					Type:       "cuti",
					Payload:    payload,
				})
			}

			// 2. Notify Pemohon Cuti (Applicant)
			if cutiData.Nip != "" && (cutiData.Verifikasi == nil || *cutiData.Verifikasi != cutiData.Nip) {
				titleApp := "Pengajuan Cuti Berhasil Dikirim"
				bodyApp := "Pengajuan Cuti Anda (ID: " + strconv.Itoa(int(cutiData.ID)) + ") telah berhasil dikirim dan menunggu verifikasi Atasan."
				payloadApp := map[string]string{"type": "cuti", "id": strconv.Itoa(int(cutiData.ID)), "status": cutiData.Status}
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: []string{cutiData.Nip},
					Title:      titleApp,
					Body:       bodyApp,
					Type:       "cuti",
					Payload:    payloadApp,
				})
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
		fStr := c.FormValue("file_lampiran")
		if fStr == "" {
			fStr = c.FormValue("file")
		}
		if fStr != "" {
			fileLampiran = &fStr
		}

		var catatanAtasan *string
		catatan := c.FormValue("catatan_atasan")
		if catatan != "" {
			catatanAtasan = &catatan
		}

		command := UpdateCuti.UpdateCutiCommand{
			ID:             uint(id),
			NamaPemohon:    c.FormValue("nama"),
			Unit:           c.FormValue("unit"),
			Fakultas:       c.FormValue("fakultas"),
			Prodi:          c.FormValue("prodi"),
			JenisCutiID:    uint(jenisCutiID),
			TanggalMulai:   c.FormValue("tanggal_mulai"),
			TanggalSelesai: c.FormValue("tanggal_selesai"),
			JumlahHari:     jumlahHari,
			Alasan:         c.FormValue("alasan"),
			FileLampiran:   fileLampiran,
			Status:         c.FormValue("status"),
			CatatanAtasan:  catatanAtasan,
			IsSdm:          c.FormValue("role") == "sdm",
		}

		res, err := mediatr.Send[*UpdateCuti.UpdateCutiCommand, common.ResultValue[*domain.Cuti]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		// Trigger Notification for Update/Verify Cuti
		if res.Value != nil {
			cutiData := res.Value
			status := cutiData.Status

			atasanNip := ""
			if cutiData.Verifikasi != nil && *cutiData.Verifikasi != "" {
				atasanNip = *cutiData.Verifikasi
			}

			switch status {
			case "terima atasan":
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: []string{cutiData.Nip},
					Title:      "Pengajuan Cuti Disetujui Atasan",
					Body:       "Pengajuan Cuti Anda telah disetujui Atasan. Menunggu verifikasi SDM.",
					Type:       "cuti",
					Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
				})
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: []string{"SDM_BROADCAST"},
					Title:      "Verifikasi SDM Cuti",
					Body:       "Pengajuan Cuti NIP " + cutiData.Nip + " telah disetujui Atasan. Mohon verifikasi final SDM.",
					Type:       "cuti",
					Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
				})

			case "tolak atasan":
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: []string{cutiData.Nip},
					Title:      "Pengajuan Cuti Ditolak Atasan",
					Body:       "Pengajuan Cuti Anda ditolak oleh Atasan.",
					Type:       "cuti",
					Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
				})

			case "terima sdm":
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: []string{cutiData.Nip},
					Title:      "Pengajuan Cuti Disetujui SDM",
					Body:       "Selamat! Pengajuan Cuti Anda telah disetujui oleh SDM.",
					Type:       "cuti",
					Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
				})
				if atasanNip != "" && atasanNip != cutiData.Nip {
					_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
						TargetNips: []string{atasanNip},
						Title:      "Status Final Cuti",
						Body:       "Pengajuan Cuti NIP " + cutiData.Nip + " telah disetujui oleh SDM.",
						Type:       "cuti",
						Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
					})
				}

			case "tolak sdm":
				_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
					TargetNips: []string{cutiData.Nip},
					Title:      "Pengajuan Cuti Ditolak SDM",
					Body:       "Pengajuan Cuti Anda ditolak oleh SDM.",
					Type:       "cuti",
					Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
				})
				if atasanNip != "" && atasanNip != cutiData.Nip {
					_, _ = mediatr.Send[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](c.UserContext(), &CreateNotification.CreateNotificationCommand{
						TargetNips: []string{atasanNip},
						Title:      "Status Final Cuti",
						Body:       "Pengajuan Cuti NIP " + cutiData.Nip + " ditolak oleh SDM.",
						Type:       "cuti",
						Payload:    map[string]string{"id": strconv.Itoa(int(cutiData.ID)), "status": status},
					})
				}
			}

			helper.GlobalSdmWsHub.Broadcast(fiber.Map{"event": "cuti_updated", "module": "leave", "data": cutiData})
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

	getLeaveList := func(c *fiber.Ctx, forceVerif bool) error {
		nip := c.FormValue("nip")
		nidn := c.FormValue("nidn")
		role := c.FormValue("role")
		if role == "" {
			role = string(c.Request().PostArgs().Peek("role"))
		}
		isSdm := (role == "sdm" || role == "baum" || c.Query("role") == "sdm" || c.Query("role") == "baum")

		isVerif := forceVerif || c.Query("verifikasi") == "haxor" || c.Query("verifikasi") == "true"

		query := &GetAllCuti.GetAllCutiQuery{
			Nip:          nip,
			Nidn:         nidn,
			Verifikasi:   isVerif,
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
	}

	group.Get("/verifikasi", func(c *fiber.Ctx) error {
		return getLeaveList(c, true)
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
		return getLeaveList(c, false)
	})
}

func ModuleLeave(app *fiber.App) {
	groupV2 := app.Group("/api/v2/leave", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerLeaveRoutes(groupV2)

	groupV1 := app.Group("/api/leave", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerLeaveRoutes(groupV1)
}
