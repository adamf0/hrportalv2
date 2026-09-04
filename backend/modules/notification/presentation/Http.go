package presentation

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"

	"hrportal_backend/modules/notification/domain"
	reportInfra "hrportal_backend/modules/report/infrastructure"
)

func RegisterFcmTokenHandler(c *fiber.Ctx) error {
	nip := c.FormValue("nip")
	nidn := c.FormValue("nidn")
	fcmToken := c.FormValue("fcm_token")
	if fcmToken == "" {
		fcmToken = c.FormValue("token")
	}

	if fcmToken != "" && (nip != "" || nidn != "") {
		db, _ := c.Locals("db").(*gorm.DB)
		if db == nil {
			if repo := reportInfra.GetReportRepository(); repo != nil {
				db = repo.GetDB()
			}
		}
		isSdm := c.FormValue("is_sdm") == "true" || c.FormValue("role") == "sdm" || c.FormValue("level") == "sdm"
		if db != nil {
			var tokenModel domain.FcmTokenModel
			query := db.Model(&domain.FcmTokenModel{})
			if nip != "" && nidn != "" {
				query = query.Where("nip = ? OR nidn = ?", nip, nidn)
			} else if nip != "" {
				query = query.Where("nip = ?", nip)
			} else {
				query = query.Where("nidn = ?", nidn)
			}

			if err := query.Order("updated_at desc").First(&tokenModel).Error; err == nil {
				db.Model(&tokenModel).Updates(map[string]interface{}{
					"nip":        nip,
					"nidn":       nidn,
					"fcm_token":  fcmToken,
					"is_sdm":     isSdm || tokenModel.IsSdm,
					"updated_at": time.Now(),
				})
			} else {
				db.Create(&domain.FcmTokenModel{
					Nip:       nip,
					Nidn:      nidn,
					FcmToken:  fcmToken,
					IsSdm:     isSdm,
					UpdatedAt: time.Now(),
				})
			}
		}
		return c.JSON(fiber.Map{"status": "ok", "message": "FCM Token registered successfully", "nip": nip, "nidn": nidn})
	}
	return c.Status(400).JSON(fiber.Map{"error": "Missing nip or fcm_token"})
}

func GetNotificationsHandler(c *fiber.Ctx) error {
	nip := c.Query("nip")
	if nip == "" {
		nip = c.FormValue("nip")
	}
	nidn := c.Query("nidn")
	if nidn == "" {
		nidn = c.FormValue("nidn")
	}

	isSdm := c.Query("is_sdm") == "true" || c.Query("role") == "sdm" || c.Query("level") == "sdm" || c.FormValue("is_sdm") == "true" || c.FormValue("role") == "sdm" || c.FormValue("level") == "sdm"

	db, _ := c.Locals("db").(*gorm.DB)
	targets := []string{}
	if nip != "" {
		targets = append(targets, nip)
	}
	if nidn != "" {
		targets = append(targets, nidn)
	}
	if isSdm {
		targets = append(targets, "SDM_BROADCAST")
	}

	var items []domain.NotificationModel
	if db != nil && len(targets) > 0 {
		_ = db.Where("target_nip IN ? or target_nidn IN ?", targets, targets).Order("created_at desc").Limit(50).Find(&items)
	}

	return c.JSON(fiber.Map{"data": items, "count": len(items)})
}

func MarkNotificationDoneHandler(c *fiber.Ctx) error {
	id := c.FormValue("id")
	if id == "" {
		id = c.Query("id")
	}
	if id != "" {
		db, _ := c.Locals("db").(*gorm.DB)
		if db != nil {
			db.Model(&domain.NotificationModel{}).Where("notification_id = ?", id).Updates(map[string]interface{}{
				"status":     "done",
				"updated_at": time.Now(),
			})
		}
		return c.JSON(fiber.Map{"status": "ok", "message": "Notification marked as done"})
	}
	return c.Status(400).JSON(fiber.Map{"error": "Missing notification id"})
}

func ModuleNotification(app *fiber.App) {
	app.Post("/api/account/fcm-token", RegisterFcmTokenHandler)
	app.Post("/api/v2/account/fcm-token", RegisterFcmTokenHandler)
	app.Get("/api/account/notifications", GetNotificationsHandler)
	app.Get("/api/v2/account/notifications", GetNotificationsHandler)
	app.Post("/api/account/notifications/mark-done", MarkNotificationDoneHandler)
	app.Post("/api/v2/account/notifications/mark-done", MarkNotificationDoneHandler)

	app.Post("/api/notification/fcm-token", RegisterFcmTokenHandler)
	app.Post("/api/v2/notification/fcm-token", RegisterFcmTokenHandler)
	app.Get("/api/notification/notifications", GetNotificationsHandler)
	app.Get("/api/v2/notification/notifications", GetNotificationsHandler)
	app.Post("/api/notification/mark-done", MarkNotificationDoneHandler)
	app.Post("/api/v2/notification/mark-done", MarkNotificationDoneHandler)
}
