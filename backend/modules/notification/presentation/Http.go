package presentation

import (
	"github.com/gofiber/fiber/v2"
	"hrportal_backend/common/helper"
)

func RegisterFcmTokenHandler(c *fiber.Ctx) error {
	nip := c.FormValue("nip")
	fcmToken := c.FormValue("fcm_token")
	if fcmToken == "" {
		fcmToken = c.FormValue("token")
	}

	if nip != "" && fcmToken != "" {
		helper.GlobalFcmManager.RegisterToken(nip, fcmToken)
		if c.FormValue("is_sdm") == "true" || c.FormValue("role") == "sdm" || c.FormValue("level") == "sdm" {
			helper.GlobalFcmManager.RegisterSdmNip(nip)
		}
		return c.JSON(fiber.Map{"status": "ok", "message": "FCM Token registered successfully", "nip": nip})
	}
	return c.Status(400).JSON(fiber.Map{"error": "Missing nip or fcm_token"})
}

func GetNotificationsHandler(c *fiber.Ctx) error {
	nip := c.Query("nip")
	if nip == "" {
		nip = c.FormValue("nip")
	}
	isSdm := c.Query("is_sdm") == "true" || c.Query("role") == "sdm" || c.Query("level") == "sdm" || c.FormValue("is_sdm") == "true" || c.FormValue("role") == "sdm" || c.FormValue("level") == "sdm"

	items := helper.GlobalFcmManager.GetNotificationsWithSdmCheck(nip, isSdm)
	return c.JSON(fiber.Map{"data": items, "count": len(items)})
}

func ModuleNotification(app *fiber.App) {
	app.Post("/api/account/fcm-token", RegisterFcmTokenHandler)
	app.Get("/api/account/notifications", GetNotificationsHandler)
	app.Post("/api/notification/fcm-token", RegisterFcmTokenHandler)
	app.Get("/api/notification/notifications", GetNotificationsHandler)
}
