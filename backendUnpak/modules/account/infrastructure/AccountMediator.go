package infrastructure

import (
	commondomain "hrportal_backend_unpak/common/domain"
	login "hrportal_backend_unpak/modules/account/application/Login"
	who "hrportal_backend_unpak/modules/account/application/Whoami"
	domain "hrportal_backend_unpak/modules/account/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

var (
	GlobalRepoLocal  domain.ILocalRepository
	GlobalRepoSimak  domain.ISimakRepository
	GlobalRepoSimpeg domain.ISimpegRepository
)

func init() {
	GlobalRepoLocal = NewLocalRepository(nil)
	GlobalRepoSimak = NewSimakRepository(nil, nil)
	GlobalRepoSimpeg = NewSimpegRepository(nil)

	_ = mediatr.RegisterRequestHandler[
		*who.WhoamiQuery,
		commondomain.ResultValue[*domain.UserInfo],
	](who.NewWhoamiQueryHandler(GlobalRepoLocal, GlobalRepoSimak, GlobalRepoSimpeg))

	_ = mediatr.RegisterRequestHandler[
		*login.LoginCommand,
		commondomain.ResultValue[login.LoginResult],
	](login.NewLoginCommandHandler(GlobalRepoLocal, GlobalRepoSimak, GlobalRepoSimpeg))
}

func RegisterModuleAccount(db *gorm.DB, dbSimak *gorm.DB, dbSimpeg *gorm.DB) error {
	GlobalRepoLocal = NewLocalRepository(db)
	GlobalRepoSimak = NewSimakRepository(dbSimak, dbSimpeg)
	GlobalRepoSimpeg = NewSimpegRepository(dbSimpeg)

	// Do not clear mediatr registrations for other modules

	_ = mediatr.RegisterRequestHandler[
		*who.WhoamiQuery,
		commondomain.ResultValue[*domain.UserInfo],
	](who.NewWhoamiQueryHandler(GlobalRepoLocal, GlobalRepoSimak, GlobalRepoSimpeg))

	_ = mediatr.RegisterRequestHandler[
		*login.LoginCommand,
		commondomain.ResultValue[login.LoginResult],
	](login.NewLoginCommandHandler(GlobalRepoLocal, GlobalRepoSimak, GlobalRepoSimpeg))

	return nil
}
