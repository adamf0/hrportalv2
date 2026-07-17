package presentation

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	query "hrportal_backend/modules/masterdata/application/GetAllMasterData"
	"hrportal_backend/modules/masterdata/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
)

func ModuleMasterData(app *fiber.App) {
	group := app.Group("/api/masterdata", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())

	group.Get("/fakultas", func(c *fiber.Ctx) error {
		q := &query.GetAllFakultasQuery{}
		res, err := mediatr.Send[*query.GetAllFakultasQuery, common.ResultValue[[]domain.Fakultas]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/prodi", func(c *fiber.Ctx) error {
		q := &query.GetAllProdiQuery{}
		res, err := mediatr.Send[*query.GetAllProdiQuery, common.ResultValue[[]domain.Prodi]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/jenis-cuti", func(c *fiber.Ctx) error {
		q := &query.GetAllJenisCutiQuery{}
		res, err := mediatr.Send[*query.GetAllJenisCutiQuery, common.ResultValue[[]domain.JenisCuti]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/jenis-izin", func(c *fiber.Ctx) error {
		q := &query.GetAllJenisIzinQuery{}
		res, err := mediatr.Send[*query.GetAllJenisIzinQuery, common.ResultValue[[]domain.JenisIzin]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/jenis-sppd", func(c *fiber.Ctx) error {
		q := &query.GetAllJenisSppdQuery{}
		res, err := mediatr.Send[*query.GetAllJenisSppdQuery, common.ResultValue[[]domain.JenisSppd]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})
}
