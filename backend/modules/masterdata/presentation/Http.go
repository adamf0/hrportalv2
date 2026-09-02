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
			type UnitResult struct {
				NamaUnit string `json:"nama_unit"`
				Nama     string `json:"nama"`
				KodeUnit string `json:"kode_unit"`
			}
			var fallbackUnits []UnitResult
			errFallback := db.Table("connect_payroll_m_pegawai").
				Select("DISTINCT unit as nama_unit, unit as nama, unit as kode_unit").
				Where("unit IS NOT NULL AND unit != ''").
				Scan(&fallbackUnits).Error

			if errFallback == nil && len(fallbackUnits) > 0 {
				return c.JSON(fallbackUnits)
			}

			defaultUnits := []fiber.Map{
				{"id": 1, "kode_unit": "FT", "nama_unit": "Fakultas Teknik", "nama": "Fakultas Teknik", "unit": "Fakultas Teknik"},
				{"id": 2, "kode_unit": "FEB", "nama_unit": "Fakultas Ekonomi & Bisnis", "nama": "Fakultas Ekonomi & Bisnis", "unit": "Fakultas Ekonomi & Bisnis"},
				{"id": 3, "kode_unit": "FKIP", "nama_unit": "Fakultas Keguruan & Ilmu Pendidikan", "nama": "Fakultas Keguruan & Ilmu Pendidikan", "unit": "Fakultas Keguruan & Ilmu Pendidikan"},
				{"id": 4, "kode_unit": "FH", "nama_unit": "Fakultas Hukum", "nama": "Fakultas Hukum", "unit": "Fakultas Hukum"},
				{"id": 5, "kode_unit": "FMIPA", "nama_unit": "Fakultas MIPA", "nama": "Fakultas MIPA", "unit": "Fakultas MIPA"},
				{"id": 6, "kode_unit": "FISIB", "nama_unit": "Fakultas Ilmu Sosial & Ilmu Budaya", "nama": "Fakultas Ilmu Sosial & Ilmu Budaya", "unit": "Fakultas Ilmu Sosial & Ilmu Budaya"},
				{"id": 7, "kode_unit": "SV", "nama_unit": "Sekolah Vokasi", "nama": "Sekolah Vokasi", "unit": "Sekolah Vokasi"},
				{"id": 8, "kode_unit": "SPS", "nama_unit": "Sekolah Pascasarjana", "nama": "Sekolah Pascasarjana", "unit": "Sekolah Pascasarjana"},
				{"id": 9, "kode_unit": "SDM", "nama_unit": "Biro SDM & Kepegawaian", "nama": "Biro SDM & Kepegawaian", "unit": "Biro SDM & Kepegawaian"},
			}
			return c.JSON(defaultUnits)
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
		q := &query.GetAllVerifikatorQuery{Type: c.Query("type")}
		res, err := mediatr.Send[*query.GetAllVerifikatorQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/supervisors", func(c *fiber.Ctx) error {
		q := &query.GetAllVerifikatorQuery{Type: c.Query("type")}
		res, err := mediatr.Send[*query.GetAllVerifikatorQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/atasan", func(c *fiber.Ctx) error {
		q := &query.GetAllVerifikatorQuery{Type: c.Query("type")}
		res, err := mediatr.Send[*query.GetAllVerifikatorQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
		if err != nil {
			return infrastructure.HandleError(c, err)
		}
		if !res.IsSuccess {
			return infrastructure.HandleError(c, res.Error)
		}
		return c.JSON(res.Value)
	})

	group.Get("/people", func(c *fiber.Ctx) error {
		q := &query.GetAllVerifikatorQuery{Type: c.Query("type")}
		res, err := mediatr.Send[*query.GetAllVerifikatorQuery, common.ResultValue[[]domain.Verifikator]](c.UserContext(), q)
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
