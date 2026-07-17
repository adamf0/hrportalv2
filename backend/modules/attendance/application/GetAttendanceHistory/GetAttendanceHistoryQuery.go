package GetAttendanceHistory

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/attendance/domain"
)

type GetAttendanceHistoryQuery struct {
	Nidn     string
	Nip      string
	Page     int
	PageSize int
}

type GetAttendanceHistoryQueryHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewGetAttendanceHistoryQueryHandler(attendanceRepo domain.IAttendanceRepository) *GetAttendanceHistoryQueryHandler {
	return &GetAttendanceHistoryQueryHandler{attendanceRepo: attendanceRepo}
}

func (h *GetAttendanceHistoryQueryHandler) Handle(ctx context.Context, query *GetAttendanceHistoryQuery) (common.ResultValue[common.Paged[domain.Absen]], error) {
	paged, err := h.attendanceRepo.GetHistoryByNip(ctx, query.Nip, query.Nidn, query.Page, query.PageSize)
	if err != nil {
		return common.FailureValue[common.Paged[domain.Absen]](domain.AttendanceNotFound()), err
	}
	return common.SuccessValue(paged), nil
}
