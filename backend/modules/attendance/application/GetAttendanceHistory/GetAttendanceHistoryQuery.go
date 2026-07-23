package GetAttendanceHistory

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/attendance/domain"
)

type GetAttendanceHistoryQuery struct {
	Nidn         string
	Nip          string
	TanggalMulai *string
	TanggalAkhir *string
}

type GetAttendanceHistoryQueryHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewGetAttendanceHistoryQueryHandler(attendanceRepo domain.IAttendanceRepository) *GetAttendanceHistoryQueryHandler {
	return &GetAttendanceHistoryQueryHandler{attendanceRepo: attendanceRepo}
}

func (h *GetAttendanceHistoryQueryHandler) Handle(ctx context.Context, query *GetAttendanceHistoryQuery) (common.ResultValue[[]domain.Absen], error) {
	list, err := h.attendanceRepo.GetHistoryByNip(ctx, query.Nip, query.Nidn, query.TanggalMulai, query.TanggalAkhir)
	if err != nil {
		return common.FailureValue[[]domain.Absen](domain.AttendanceNotFound()), err
	}
	return common.SuccessValue(list), nil
}
