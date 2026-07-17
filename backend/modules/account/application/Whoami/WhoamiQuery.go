package Whoami

import (
	"context"
	"strings"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/account/domain"
)

type WhoamiQuery struct {
	Sid    string
	Source string
}

type WhoamiQueryHandler struct {
	repoLocal  domain.ILocalRepository
	repoSimak  domain.ISimakRepository
	repoSimpeg domain.ISimpegRepository
}

func NewWhoamiQueryHandler(
	repoLocal domain.ILocalRepository,
	repoSimak domain.ISimakRepository,
	repoSimpeg domain.ISimpegRepository,
) *WhoamiQueryHandler {
	return &WhoamiQueryHandler{
		repoLocal:  repoLocal,
		repoSimak:  repoSimak,
		repoSimpeg: repoSimpeg,
	}
}

func (h *WhoamiQueryHandler) Handle(ctx context.Context, query *WhoamiQuery) (common.ResultValue[*domain.UserInfo], error) {
	var info *domain.UserInfo
	var err error

	switch strings.ToLower(query.Source) {
	case "local":
		info, err = h.repoLocal.GetInfo(ctx, query.Sid)
	case "simak":
		info, err = h.repoSimak.GetInfo(ctx, query.Sid)
	case "simpeg":
		info, err = h.repoSimpeg.GetInfo(ctx, query.Sid)
	default:
		return common.FailureValue[*domain.UserInfo](domain.AccountNotFound()), nil
	}

	if err != nil || info == nil {
		return common.FailureValue[*domain.UserInfo](domain.AccountNotFound()), nil
	}

	return common.SuccessValue(info), nil
}
