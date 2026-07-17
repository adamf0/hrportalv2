package presentation

import (
	"os"
	"strconv"

	common "hrportal_backend/common/domain"
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

		return c.JSON(res.Value)
	})

	group.Put("/:id", func(c *fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))
		jenisCutiID, _ := strconv.Atoi(c.FormValue("jenis_cuti_id"))
		if jenisCutiID == 0 {
			jenisCutiID, _ = strconv.Atoi(c.FormValue("jenis_izin_id"))
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

		query := &GetAllCuti.GetAllCutiQuery{
			Nip:  nip,
			Nidn: nidn,
		}

		res, err := mediatr.Send[*GetAllCuti.GetAllCutiQuery, common.ResultValue[[]domain.Cuti]](c.UserContext(), query)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}

		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}

		return c.JSON(res.Value)
	})
}
