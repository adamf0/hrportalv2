package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/sppd/application/CreateSppd"
	"hrportal_backend/modules/sppd/application/DeleteSppd"
	"hrportal_backend/modules/sppd/application/GetSppd"
	"hrportal_backend/modules/sppd/application/GetSppdHistory"
	"hrportal_backend/modules/sppd/application/UpdateSppd"
	"hrportal_backend/modules/sppd/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleSppd(db *gorm.DB) error {
	repo := NewSppdRepository(db)

	createHandler := CreateSppd.NewCreateSppdCommandHandler(repo)
	err := mediatr.RegisterRequestHandler[*CreateSppd.CreateSppdCommand, common.ResultValue[*domain.Sppd]](createHandler)
	if err != nil {
		return err
	}

	historyHandler := GetSppdHistory.NewGetSppdHistoryQueryHandler(repo)
	err = mediatr.RegisterRequestHandler[*GetSppdHistory.GetSppdHistoryQuery, common.ResultValue[[]domain.Sppd]](historyHandler)
	if err != nil {
		return err
	}

	updateHandler := UpdateSppd.NewUpdateSppdCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*UpdateSppd.UpdateSppdCommand, common.ResultValue[*domain.Sppd]](updateHandler)
	if err != nil {
		return err
	}

	deleteHandler := DeleteSppd.NewDeleteSppdCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*DeleteSppd.DeleteSppdCommand, common.ResultValue[bool]](deleteHandler)
	if err != nil {
		return err
	}

	getHandler := GetSppd.NewGetSppdQueryHandler(repo)
	err = mediatr.RegisterRequestHandler[*GetSppd.GetSppdQuery, common.ResultValue[*domain.Sppd]](getHandler)
	if err != nil {
		return err
	}

	return nil
}
