package presentation

import (
	"strings"

	common "hrportal_backend/common/domain"
	"hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	query "hrportal_backend/modules/masterdata/application/GetAllMasterData"
	"hrportal_backend/modules/masterdata/domain"

	"github.com/gofiber/fiber/v2"
	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

type MasterUnit struct {
	ID       int64  `gorm:"primaryKey;column:id" json:"id"`
	KodeUnit string `gorm:"column:kode_unit" json:"kode_unit"`
	NamaUnit string `gorm:"column:nama_unit" json:"nama_unit"`
	Nama     string `gorm:"column:nama" json:"nama"`
	Unit     string `gorm:"column:unit" json:"unit"`
}

func (MasterUnit) TableName() string {
	return "master_units"
}

func registerMasterDataRoutes(group fiber.Router, db *gorm.DB, dbSimpegNew *gorm.DB) {
	group.Get("/fakultas", func(c *fiber.Ctx) error {
		q := &query.GetAllFakultasQuery{}
		res, err := mediatr.Send[*query.GetAllFakultasQuery, common.ResultValue[[]domain.Fakultas]](c.UserContext(), q)
		if err != nil || !res.IsSuccess {
			var list []domain.Fakultas
			targetDB := db
			if dbSimpegNew != nil {
				targetDB = dbSimpegNew
			}
			if errFind := targetDB.Table("connect_m_fakultas").Find(&list).Error; errFind == nil && len(list) > 0 {
				for i := range list {
					list[i].ID = list[i].KodeFakultas
					list[i].Kode = list[i].KodeFakultas
					list[i].Nama = list[i].NamaFakultas
				}
				return c.JSON(list)
			}
			if err != nil {
				return infrastructure.HandleError(c, err)
			}
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/prodi", func(c *fiber.Ctx) error {
		q := &query.GetAllProdiQuery{}
		res, err := mediatr.Send[*query.GetAllProdiQuery, common.ResultValue[[]domain.Prodi]](c.UserContext(), q)
		if err == nil && res.IsSuccess {
			var filtered []domain.Prodi
			for _, p := range res.Value {
				namaLower := strings.ToLower(p.NamaProdi)
				if !strings.Contains(namaLower, "isi nama ps") {
					filtered = append(filtered, p)
				}
			}
			return c.JSON(filtered)
		}

		// Fallback direct query
		var rawList []domain.Prodi
		targetDB := db
		if dbSimpegNew != nil {
			targetDB = dbSimpegNew
		}
		if errFind := targetDB.Table("connect_r_prodi").Where("LOWER(nama_prodi) NOT LIKE '%isi nama ps%'").Find(&rawList).Error; errFind == nil && len(rawList) > 0 {
			var list []domain.Prodi
			for i := range rawList {
				namaLower := strings.ToLower(rawList[i].NamaProdi)
				if strings.Contains(namaLower, "isi nama ps") {
					continue
				}
				rawList[i].ID = rawList[i].KodeProdi
				rawList[i].FakultasID = rawList[i].KodeFakultas
				rawList[i].Kode = rawList[i].KodeProdi
				rawList[i].Nama = rawList[i].NamaProdi
				list = append(list, rawList[i])
			}
			return c.JSON(list)
		}

		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		return infrastructure.HandleError(c, res.Error)
	})

	// GET /unit fetching data from unpak_newsimpeg.master_units database
	group.Get("/unit", func(c *fiber.Ctx) error {
		targetDB := db
		if dbSimpegNew != nil {
			targetDB = dbSimpegNew
		}

		var units []MasterUnit
		err := targetDB.Table("master_units").Find(&units).Error
		if err != nil || len(units) == 0 {
			return c.JSON(units)
		}

		for i := range units {
			if units[i].NamaUnit == "" {
				units[i].NamaUnit = units[i].Nama
			}
			if units[i].Nama == "" {
				units[i].Nama = units[i].NamaUnit
			}
			if units[i].Unit == "" {
				units[i].Unit = units[i].NamaUnit
			}
		}

		return c.JSON(units)
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

	group.Get("/verifikator", func(c *fiber.Ctx) error {
		q := &query.GetAllVerifikatorQuery{}
		res, err := mediatr.Send[*query.GetAllVerifikatorQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	// group.Get("/atasan", func(c *fiber.Ctx) error {
	// 	q := &query.GetAllVerifikatorQuery{}
	// 	res, err := mediatr.Send[*query.GetAllVerifikatorQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
	// 	if err != nil {
	// 		return infrastructure.HandleError(c, err)
	// 	}
	// 	if !res.IsSuccess {
	// 		return infrastructure.HandleError(c, res.Error)
	// 	}
	// 	return c.JSON(res.Value)
	// })

	group.Get("/people", func(c *fiber.Ctx) error {
		q := &query.GetAllPeopleQuery{}
		res, err := mediatr.Send[*query.GetAllPeopleQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})
}

func ModuleMasterData(app *fiber.App, db *gorm.DB, dbSimpegNew *gorm.DB) {
	groupV2 := app.Group("/api/v2/masterdata", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerMasterDataRoutes(groupV2, db, dbSimpegNew)

	groupV1 := app.Group("/api/masterdata", commonpresentation.JWTMiddleware(), commonpresentation.RBACMiddleware())
	registerMasterDataRoutes(groupV1, db, dbSimpegNew)
}
