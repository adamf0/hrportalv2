package GetAbsenUpacara

import (
	"context"
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/ceremony_attendance/domain"
)

type GetAbsenUpacaraQuery struct {
	ID uint `json:"id"`
}

type GetAbsenUpacaraQueryHandler struct {
	repo domain.ICeremonyAttendanceRepository
}

func NewGetAbsenUpacaraQueryHandler(repo domain.ICeremonyAttendanceRepository) *GetAbsenUpacaraQueryHandler {
	return &GetAbsenUpacaraQueryHandler{repo: repo}
}

func (h *GetAbsenUpacaraQueryHandler) Handle(ctx context.Context, query *GetAbsenUpacaraQuery) (common.ResultValue[*domain.AbsenUpacara], error) {
	upacara, err := h.repo.GetByID(ctx, query.ID)
	if err != nil {
		return common.FailureValue[*domain.AbsenUpacara](domain.UpacaraNotFound()), nil
	}

	return common.SuccessValue(upacara), nil
}
