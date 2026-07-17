package infrastructure

import (
	common "hrportal_backend/common/domain"
	query "hrportal_backend/modules/masterdata/application/GetAllMasterData"
	"hrportal_backend/modules/masterdata/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleMasterData(db *gorm.DB) error {
	repo := NewMasterDataRepository(db)

	err := mediatr.RegisterRequestHandler[*query.GetAllFakultasQuery, common.ResultValue[[]domain.Fakultas]](
		query.NewGetAllFakultasQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*query.GetAllProdiQuery, common.ResultValue[[]domain.Prodi]](
		query.NewGetAllProdiQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*query.GetAllJenisCutiQuery, common.ResultValue[[]domain.JenisCuti]](
		query.NewGetAllJenisCutiQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*query.GetAllJenisIzinQuery, common.ResultValue[[]domain.JenisIzin]](
		query.NewGetAllJenisIzinQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*query.GetAllJenisSppdQuery, common.ResultValue[[]domain.JenisSppd]](
		query.NewGetAllJenisSppdQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	return nil
}
