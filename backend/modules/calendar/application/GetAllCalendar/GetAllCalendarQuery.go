package GetAllCalendar

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/calendar/domain"
)

type GetAllCalendarQuery struct {
	Nip       string `json:"nip"`
	Nidn      string `json:"nidn"`
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
}

type GetAllCalendarQueryHandler struct {
	repo domain.ICalendarRepository
}

func NewGetAllCalendarQueryHandler(repo domain.ICalendarRepository) *GetAllCalendarQueryHandler {
	return &GetAllCalendarQueryHandler{repo: repo}
}

func (h *GetAllCalendarQueryHandler) Handle(ctx context.Context, query *GetAllCalendarQuery) (common.ResultValue[[]domain.CalendarItem], error) {
	events, err := h.repo.GetCalendarEvents(ctx, query.Nip, query.Nidn, query.StartDate, query.EndDate)
	if err != nil {
		return common.FailureValue[[]domain.CalendarItem](common.FailureError("Calendar.FetchFailed", err.Error())), nil
	}

	return common.SuccessValue(events), nil
}
