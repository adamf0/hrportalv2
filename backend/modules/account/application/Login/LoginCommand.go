package Login

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/account/domain"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type LoginResult struct {
	Sid      string `json:"sid"`
	Source   string `json:"source"`
	Fakultas string `json:"fakultas"`
	Prodi    string `json:"prodi"`
	Unit     string `json:"unit"`
	Level    string `json:"level"`
	Name     string `json:"name"`
	Email    string `json:"email"`
	Nip      string `json:"nip"`
	Nidn     string `json:"nidn"`
}

type LoginCommand struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func (c LoginCommand) Validate() error {
	return validation.ValidateStruct(&c,
		validation.Field(&c.Username, validation.Required),
		validation.Field(&c.Password, validation.Required), // Poin 3: Password sebaiknya mandatory saat login
	)
}

type LoginCommandHandler struct {
	repoLocal  domain.ILocalRepository
	repoSimak  domain.ISimakRepository
	repoSimpeg domain.ISimpegRepository
}

func NewLoginCommandHandler(
	repoLocal domain.ILocalRepository,
	repoSimak domain.ISimakRepository,
	repoSimpeg domain.ISimpegRepository,
) *LoginCommandHandler {
	return &LoginCommandHandler{
		repoLocal:  repoLocal,
		repoSimak:  repoSimak,
		repoSimpeg: repoSimpeg,
	}
}

func (h *LoginCommandHandler) Handle(ctx context.Context, cmd *LoginCommand) (common.ResultValue[LoginResult], error) {
	// Poin 1: Validasi command di awal handler
	if err := cmd.Validate(); err != nil {
		return common.FailureValue[LoginResult](common.FailureError("Account.InvalidInput", err.Error())), nil
	}

	// 1. Coba Local Auth
	if res, err := h.repoLocal.Authenticate(ctx, cmd.Username, cmd.Password); err == nil && res != nil {
		if info, errInfo := h.repoLocal.GetInfo(ctx, res.Sid); errInfo == nil && info != nil {
			res.Name = info.Name
			res.Email = info.Email
			res.Nip = info.Nip
			res.Nidn = info.Nidn
			res.Fakultas = info.Fakultas
			res.Prodi = info.Prodi
			res.Unit = info.Unit
			res.Level = info.Level
		}
		return h.buildResult(res)
	}

	// 2. Fallback ke SIMAK Auth jika Local gagal
	if res, err := h.repoSimak.Authenticate(ctx, cmd.Username, cmd.Password); err == nil && res != nil {
		if info, errInfo := h.repoSimak.GetInfo(ctx, res.Sid); errInfo == nil && info != nil {
			res.Name = info.Name
			res.Email = info.Email
			res.Nip = info.Nip
			res.Nidn = info.Nidn
			res.Fakultas = info.Fakultas
			res.Prodi = info.Prodi
			res.Unit = info.Unit
			res.Level = info.Level
		}
		return h.buildResult(res)
	}

	// 3. Fallback ke SIMPEG Auth jika SIMAK gagal
	if res, err := h.repoSimpeg.Authenticate(ctx, cmd.Username, cmd.Password); err == nil && res != nil {
		if info, errInfo := h.repoSimpeg.GetInfo(ctx, res.Sid); errInfo == nil && info != nil {
			res.Name = info.Name
			res.Email = info.Email
			res.Nip = info.Nip
			res.Nidn = info.Nidn
			res.Fakultas = info.Fakultas
			res.Prodi = info.Prodi
			res.Unit = info.Unit
			res.Level = info.Level
		}
		return h.buildResult(res)
	}

	// Poin 2: Jika semua provider gagal, kembalikan generic error
	return common.FailureValue[LoginResult](common.FailureError("Account.InvalidCredentials", "username atau password salah")), nil
}

func (h *LoginCommandHandler) buildResult(res *domain.AuthResult) (common.ResultValue[LoginResult], error) {
	result := LoginResult{
		Sid:      res.Sid,
		Source:   res.Source,
		Fakultas: res.Fakultas,
		Prodi:    res.Prodi,
		Unit:     res.Unit,
		Level:    res.Level,
		Name:     res.Name,
		Email:    res.Email,
		Nip:      res.Nip,
		Nidn:     res.Nidn,
	}
	return common.SuccessValue(result), nil
}
