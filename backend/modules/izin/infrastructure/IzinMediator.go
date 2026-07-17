package infrastructure

import (
	commondomain "hrportal_backend/common/domain"
	create "hrportal_backend/modules/izin/application/CreateIzin"
	delete "hrportal_backend/modules/izin/application/DeleteIzin"
	getAll "hrportal_backend/modules/izin/application/GetAllIzins"
	get "hrportal_backend/modules/izin/application/GetIzin"
	update "hrportal_backend/modules/izin/application/UpdateIzin"
	domain "hrportal_backend/modules/izin/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleIzin(db *gorm.DB) error {
	repoIzin := NewIzinRepository(db)

	mediatr.RegisterRequestHandler[
		*create.CreateIzinCommand,
		commondomain.ResultValue[*domain.Izin],
	](create.NewCreateIzinCommandHandler(repoIzin))

	mediatr.RegisterRequestHandler[
		*update.UpdateIzinCommand,
		commondomain.ResultValue[*domain.Izin],
	](update.NewUpdateIzinCommandHandler(repoIzin))

	mediatr.RegisterRequestHandler[
		*delete.DeleteIzinCommand,
		commondomain.ResultValue[bool],
	](delete.NewDeleteIzinCommandHandler(repoIzin))

	mediatr.RegisterRequestHandler[
		*get.GetIzinQuery,
		commondomain.ResultValue[*domain.Izin],
	](get.NewGetIzinQueryHandler(repoIzin))

	mediatr.RegisterRequestHandler[
		*getAll.GetAllIzinsQuery,
		commondomain.ResultValue[[]domain.Izin],
	](getAll.NewGetAllIzinsQueryHandler(repoIzin))

	return nil
}
