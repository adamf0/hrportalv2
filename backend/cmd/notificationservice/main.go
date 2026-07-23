package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"

	notificationPresentation "hrportal_backend/modules/notification/presentation"
)

func main() {
	log.Println("[Notification Service] Starting standalone FCM Notification Service microservice binary...")

	app := fiber.New(fiber.Config{
		AppName: "Unpak HRPortal Notification Service",
	})

	app.Use(cors.New())
	app.Use(recover.New())

	notificationPresentation.ModuleNotification(app)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "service": "Unpak HRPortal Notification Service"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3001"
	}

	log.Printf("[Notification Service] Running on port :%s", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("[Notification Service] Failed to start server: %v", err)
	}
}
