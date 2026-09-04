package presentation

import (
	"fmt"
	"path/filepath"
	"time"

	commonpresentation "hrportal_backend/common/presentation"
	"hrportal_backend/common/storage"

	"github.com/gofiber/fiber/v2"
)

func registerStorageRoutes(group fiber.Router, storageSvc storage.IStorageService) {

	// 1. Generate Presigned PUT URL for uploading file from Flutter/Web
	group.All("/presign-upload", func(c *fiber.Ctx) error {
		storageType := c.Query("type")
		if storageType == "" {
			storageType = c.FormValue("type")
		}
		if storageType == "" {
			storageType = "cuti"
		}

		filename := c.Query("filename")
		if filename == "" {
			filename = c.FormValue("filename")
		}
		if filename == "" {
			filename = "dokumen.pdf"
		}

		contentType := c.Query("content_type")
		if contentType == "" {
			contentType = c.FormValue("content_type")
		}
		if contentType == "" {
			contentType = "application/octet-stream"
		}

		uploadURL, objectKey, err := storageSvc.GeneratePresignedUploadURL(c.Context(), storageType, filename, contentType)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error":   "Failed to generate presigned upload URL",
				"details": err.Error(),
			})
		}

		bucket := storage.GetBucketName(storageType)

		return c.JSON(fiber.Map{
			"upload_url":   uploadURL,
			"object_key":   objectKey,
			"bucket":       bucket,
			"type":         storageType,
			"file_path":    objectKey,
			"content_type": contentType,
			"expires_in":   1800, // 30 mins
		})
	})

	// 2. Generate Presigned GET URL for reading private file
	group.Get("/presign-read", func(c *fiber.Ctx) error {
		storageType := c.Query("type")
		if storageType == "" {
			storageType = "cuti"
		}

		objectKey := c.Query("object")
		if objectKey == "" {
			objectKey = c.Query("file")
		}
		if objectKey == "" {
			objectKey = c.Query("path")
		}

		if objectKey == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Param 'object' or 'file' is required",
			})
		}

		readURL, err := storageSvc.GeneratePresignedReadURL(c.Context(), storageType, objectKey, 2*time.Hour)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error":   "Failed to generate presigned read URL",
				"details": err.Error(),
			})
		}

		bucket := storage.GetBucketName(storageType)

		return c.JSON(fiber.Map{
			"read_url":           readURL,
			"url":                readURL,
			"object_key":         objectKey,
			"bucket":             bucket,
			"type":               storageType,
			"expires_in_seconds": 7200,
		})
	})

	// 3. Stream private file directly via backend (Secure Stream Proxy)
	group.Get("/file", func(c *fiber.Ctx) error {
		storageType := c.Query("type")
		if storageType == "" {
			storageType = "cuti"
		}

		objectKey := c.Query("object")
		if objectKey == "" {
			objectKey = c.Query("file")
		}
		if objectKey == "" {
			objectKey = c.Query("path")
		}

		if objectKey == "" {
			return c.Status(fiber.StatusBadRequest).SendString("Param 'object' is required")
		}

		stream, contentType, err := storageSvc.GetObjectStream(c.Context(), storageType, objectKey)
		if err != nil {
			return c.Status(fiber.StatusNotFound).SendString("File not found in storage: " + err.Error())
		}
		defer stream.Close()

		filename := filepath.Base(objectKey)
		c.Set("Content-Type", contentType)
		c.Set("Content-Disposition", fmt.Sprintf("inline; filename=\"%s\"", filename))

		return c.SendStream(stream)
	})

	// 4. Mock Upload Endpoint (Used by storageSvcMoq)
	group.All("/mock-upload", func(c *fiber.Ctx) error {
		storageType := c.Query("type")
		if storageType == "" {
			storageType = "cuti"
		}

		objectKey := c.Query("object")
		if objectKey == "" {
			objectKey = "mock_file.pdf"
		}

		contentType := c.Get("Content-Type", "application/octet-stream")
		bodyBytes := c.Body()

		_ = storageSvc.SaveMockObject(storageType, objectKey, contentType, bodyBytes)

		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status":     "uploaded_to_mock",
			"object_key": objectKey,
			"type":       storageType,
			"bytes":      len(bodyBytes),
		})
	})
}

func ModuleStorage(app *fiber.App) {
	storageSvc := storage.InitStorageService()

	groupV2 := app.Group("/api/v2/storage", commonpresentation.JWTMiddleware())
	registerStorageRoutes(groupV2, storageSvc)

	groupV1 := app.Group("/api/storage", commonpresentation.JWTMiddleware())
	registerStorageRoutes(groupV1, storageSvc)
}
