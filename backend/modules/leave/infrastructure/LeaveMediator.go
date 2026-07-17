package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/leave/application/DeleteCuti"
	"hrportal_backend/modules/leave/application/GetAllCuti"
	"hrportal_backend/modules/leave/application/GetCuti"
	"hrportal_backend/modules/leave/application/SubmitCuti"
	"hrportal_backend/modules/leave/application/UpdateCuti"
	"hrportal_backend/modules/leave/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleLeave(db *gorm.DB) error {
	repo := NewLeaveRepository(db)

	submitHandler := SubmitCuti.NewSubmitCutiCommandHandler(repo)
	err := mediatr.RegisterRequestHandler[*SubmitCuti.SubmitCutiCommand, common.ResultValue[*domain.Cuti]](submitHandler)
	if err != nil {
		return err
	}

	allCutiHandler := GetAllCuti.NewGetAllCutiQueryHandler(repo)
	err = mediatr.RegisterRequestHandler[*GetAllCuti.GetAllCutiQuery, common.ResultValue[[]domain.Cuti]](allCutiHandler)
	if err != nil {
		return err
	}

	updateHandler := UpdateCuti.NewUpdateCutiCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*UpdateCuti.UpdateCutiCommand, common.ResultValue[*domain.Cuti]](updateHandler)
	if err != nil {
		return err
	}

	deleteHandler := DeleteCuti.NewDeleteCutiCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*DeleteCuti.DeleteCutiCommand, common.ResultValue[bool]](deleteHandler)
	if err != nil {
		return err
	}

	getHandler := GetCuti.NewGetCutiQueryHandler(repo)
	err = mediatr.RegisterRequestHandler[*GetCuti.GetCutiQuery, common.ResultValue[*domain.Cuti]](getHandler)
	if err != nil {
		return err
	}

	return nil
}
