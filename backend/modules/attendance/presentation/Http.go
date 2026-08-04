package presentation

import (
	"context"
	"strconv"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/helper"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/modules/attendance/application/CheckIn"
	"hrportal_backend/modules/attendance/application/CheckOut"
	"hrportal_backend/modules/attendance/application/DeleteEmptyAttendance"
	"hrportal_backend/modules/attendance/application/GetAttendanceHistory"
	"hrportal_backend/modules/attendance/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/websocket/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleAttendance(app *fiber.App) {
	// WebSocket Endpoint for Real-time Attendance Stream (Initial State Snapshot + Live Broadcast Delta)
	app.Get("/ws/attendance", websocket.New(func(c *websocket.Conn) {
		nip := c.Query("nip")
		nidn := c.Query("nidn")
		if nip == "" && nidn == "" {
			return
		}

		userKey := nip
		if userKey == "" {
			userKey = nidn
		}

		GlobalAttendanceWsHub.Register(userKey, c)
		defer GlobalAttendanceWsHub.Unregister(userKey)

		// Send initial state snapshot for active shift
		query := &GetAttendanceHistory.GetAttendanceHistoryQuery{
			Nip:  nip,
			Nidn: nidn,
		}
		res, err := mediatr.Send[*GetAttendanceHistory.GetAttendanceHistoryQuery, common.ResultValue[[]domain.Absen]](context.Background(), query)
		if err == nil && res.IsSuccess && len(res.Value) > 0 {
			now := time.Now()
			todayStr := now.Format("2006-01-02")
			var selectedRecord *domain.Absen

			for i := range res.Value {
				if res.Value[i].Tanggal == todayStr {
					selectedRecord = &res.Value[i]
					break
				}
			}

			if selectedRecord == nil && len(res.Value) > 0 {
				selectedRecord = &res.Value[0]
			}

			if selectedRecord != nil {
				masukStr := ""
				if selectedRecord.AbsenMasuk != nil {
					masukStr = selectedRecord.AbsenMasuk.Format("2006-01-02 15:04:05")
				}
				keluarStr := ""
				if selectedRecord.AbsenKeluar != nil {
					keluarStr = selectedRecord.AbsenKeluar.Format("2006-01-02 15:04:05")
				}

				_ = c.WriteJSON(RealtimeAttendancePayload{
					Type:        "initial_state",
					Nip:         nip,
					Nidn:        nidn,
					Tanggal:     selectedRecord.Tanggal,
					AbsenMasuk:  masukStr,
					AbsenKeluar: keluarStr,
				})
			}
		}

		// Keep connection alive
		for {
			if _, _, err := c.ReadMessage(); err != nil {
				break
			}
		}
	}))

	group := app.Group("/api/attendance", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Post("/check-in", func(c *fiber.Ctx) error {
		lat, _ := strconv.ParseFloat(c.FormValue("latitude"), 64)
		lon, _ := strconv.ParseFloat(c.FormValue("longitude"), 64)

		command := CheckIn.CheckInCommand{
			Nip:         c.FormValue("nip"),
			Nidn:        c.FormValue("nidn"),
			NamaPegawai: c.FormValue("nama"),
			Unit:        c.FormValue("unit"),
			Fakultas:    c.FormValue("fakultas"),
			Prodi:       c.FormValue("prodi"),
			Latitude:    lat,
			Longitude:   lon,
			Note:        c.FormValue("note"),
		}

		res, err := mediatr.Send[*CheckIn.CheckInCommand, common.ResultValue[*domain.Absen]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		// Trigger FCM Notification & WebSocket Broadcast for Check-In Success
		if res.Value != nil {
			absenData := res.Value
			helper.GlobalFcmManager.DispatchNotification(
				[]string{absenData.Nip},
				"Presensi Otomatis Berhasil",
				"Sistem sudah melakukan absensi otomatis",
				"attendance",
				map[string]string{"type": "check-in", "id": strconv.Itoa(int(absenData.ID))},
			)

			masukStr := ""
			if absenData.AbsenMasuk != nil {
				masukStr = absenData.AbsenMasuk.Format("2006-01-02 15:04:05")
			}
			GlobalAttendanceWsHub.BroadcastToUser(absenData.Nip, absenData.Nidn, RealtimeAttendancePayload{
				Type:       "check_in",
				Nip:        absenData.Nip,
				Nidn:       absenData.Nidn,
				Tanggal:    absenData.Tanggal,
				AbsenMasuk: masukStr,
			})
		}

		return c.JSON(res.Value)
	})

	group.Post("/check-out", func(c *fiber.Ctx) error {
		command := CheckOut.CheckOutCommand{
			Nip:  c.FormValue("nip"),
			Nidn: c.FormValue("nidn"),
		}

		res, err := mediatr.Send[*CheckOut.CheckOutCommand, common.ResultValue[*domain.Absen]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		if res.Value != nil {
			absenData := res.Value
			helper.GlobalFcmManager.DispatchNotification(
				[]string{absenData.Nip},
				"Presensi Pulang Berhasil",
				"Sistem sudah mencatat jam pulang presensi Anda.",
				"attendance",
				map[string]string{"type": "check-out", "id": strconv.Itoa(int(absenData.ID))},
			)

			keluarStr := ""
			if absenData.AbsenKeluar != nil {
				keluarStr = absenData.AbsenKeluar.Format("2006-01-02 15:04:05")
			}
			GlobalAttendanceWsHub.BroadcastToUser(absenData.Nip, absenData.Nidn, RealtimeAttendancePayload{
				Type:        "check_out",
				Nip:         absenData.Nip,
				Nidn:        absenData.Nidn,
				Tanggal:     absenData.Tanggal,
				AbsenKeluar: keluarStr,
			})
		}

		return c.JSON(res.Value)
	})

	group.Post("/notify-fail", func(c *fiber.Ctx) error {
		nip := c.FormValue("nip")
		reason := c.FormValue("reason")
		if reason == "" {
			reason = "sistem gagal melakukan absensi otomatis karena anda berada di luar radius kampus / tidak terkoneksi jaringan, butuh presensi manual"
		}

		if nip != "" {
			helper.GlobalFcmManager.DispatchNotification(
				[]string{nip},
				"Presensi Otomatis Gagal",
				reason,
				"attendance_fail",
				map[string]string{"type": "fail"},
			)
			return c.JSON(fiber.Map{"status": "ok", "message": "Notification dispatched"})
		}
		return c.Status(400).JSON(fiber.Map{"error": "Missing nip"})
	})

	group.Get("/history", func(c *fiber.Ctx) error {
		query := &GetAttendanceHistory.GetAttendanceHistoryQuery{
			Nidn:         c.Query("nidn"),
			Nip:          c.Query("nip"),
			TanggalMulai: helper.StrPtr(c.Query("tanggal_mulai")),
			TanggalAkhir: helper.StrPtr(c.Query("tanggal_akhir")),
		}

		res, err := mediatr.Send[*GetAttendanceHistory.GetAttendanceHistoryQuery, common.ResultValue[[]domain.Absen]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		pagedData := common.NewPaged(res.Value, int64(len(res.Value)), 1, len(res.Value))
		sseAdapter := &commonpresentation.SSEAdapter[domain.Absen]{}

		return sseAdapter.Send(c, pagedData)
	})

	group.Delete("/empty-masuk", func(c *fiber.Ctx) error {
		command := DeleteEmptyAttendance.DeleteEmptyAttendanceCommand{}

		res, err := mediatr.Send[*DeleteEmptyAttendance.DeleteEmptyAttendanceCommand, common.ResultValue[int64]](c.UserContext(), &command)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(fiber.Map{
			"status":        "success",
			"message":       "Data absen dengan absen_masuk kosong berhasil dihapus",
			"deleted_count": res.Value,
		})
	})
}
