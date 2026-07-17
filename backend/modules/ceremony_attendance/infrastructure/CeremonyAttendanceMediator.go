package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/ceremony_attendance/application/CreateAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/application/DeleteAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/application/GetAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/application/GetAllAbsenUpacaras"
	"hrportal_backend/modules/ceremony_attendance/application/UpdateAbsenUpacara"
	"hrportal_backend/modules/ceremony_attendance/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleCeremonyAttendance(db *gorm.DB) error {
	repo := NewCeremonyAttendanceRepository(db)

	err := mediatr.RegisterRequestHandler[*CreateAbsenUpacara.CreateAbsenUpacaraCommand, common.ResultValue[*domain.AbsenUpacara]](
		CreateAbsenUpacara.NewCreateAbsenUpacaraCommandHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*UpdateAbsenUpacara.UpdateAbsenUpacaraCommand, common.ResultValue[*domain.AbsenUpacara]](
		UpdateAbsenUpacara.NewUpdateAbsenUpacaraCommandHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*DeleteAbsenUpacara.DeleteAbsenUpacaraCommand, common.ResultValue[bool]](
		DeleteAbsenUpacara.NewDeleteAbsenUpacaraCommandHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*GetAbsenUpacara.GetAbsenUpacaraQuery, common.ResultValue[*domain.AbsenUpacara]](
		GetAbsenUpacara.NewGetAbsenUpacaraQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	err = mediatr.RegisterRequestHandler[*GetAllAbsenUpacaras.GetAllAbsenUpacarasQuery, common.ResultValue[[]domain.AbsenUpacara]](
		GetAllAbsenUpacaras.NewGetAllAbsenUpacarasQueryHandler(repo),
	)
	if err != nil {
		return err
	}

	return nil
}
