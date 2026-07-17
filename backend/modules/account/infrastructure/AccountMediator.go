package infrastructure

import (
	commondomain "hrportal_backend/common/domain"
	login "hrportal_backend/modules/account/application/Login"
	who "hrportal_backend/modules/account/application/Whoami"
	domain "hrportal_backend/modules/account/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleAccount(db *gorm.DB, dbSimak *gorm.DB, dbSimpeg *gorm.DB) error {
	repoLocal := NewLocalRepository(db)
	repoSimak := NewSimakRepository(dbSimak, dbSimpeg)
	repoSimpeg := NewSimpegRepository(dbSimpeg)

	mediatr.RegisterRequestHandler[
		*who.WhoamiQuery,
		commondomain.ResultValue[*domain.UserInfo],
	](who.NewWhoamiQueryHandler(repoLocal, repoSimak, repoSimpeg))

	mediatr.RegisterRequestHandler[
		*login.LoginCommand,
		commondomain.ResultValue[login.LoginResult],
	](login.NewLoginCommandHandler(repoLocal, repoSimak, repoSimpeg))

	// commoninfra.RegisterValidation(login.LoginCommandValidation, "Account.Login.Validation")

	return nil
}
