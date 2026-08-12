package GetHolidays

import (
	"context"
	commondomain "hrportal_backend/common/domain"
	"hrportal_backend/modules/holiday/domain"
)

type GetHolidaysQuery struct {
	Year int
}

type GetHolidaysQueryHandler struct {
	Repo domain.IHolidayRepository
}

func NewGetHolidaysQueryHandler(repo domain.IHolidayRepository) *GetHolidaysQueryHandler {
	return &GetHolidaysQueryHandler{Repo: repo}
}

func (h *GetHolidaysQueryHandler) Handle(ctx context.Context, query *GetHolidaysQuery) (commondomain.ResultValue[[]domain.MasterLibur], error) {
	list, err := h.Repo.GetHolidays(ctx, query.Year)
	if err != nil {
		return commondomain.FailureValue[[]domain.MasterLibur](commondomain.FailureError("Holiday.FetchFailed", err.Error())), nil
	}
	return commondomain.SuccessValue(list), nil
}
