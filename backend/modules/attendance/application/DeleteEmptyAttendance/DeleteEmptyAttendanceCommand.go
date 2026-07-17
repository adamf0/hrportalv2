package DeleteEmptyAttendance

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/attendance/domain"
)

type DeleteEmptyAttendanceCommand struct{}

type DeleteEmptyAttendanceCommandHandler struct {
	attendanceRepo domain.IAttendanceRepository
}

func NewDeleteEmptyAttendanceCommandHandler(attendanceRepo domain.IAttendanceRepository) *DeleteEmptyAttendanceCommandHandler {
	return &DeleteEmptyAttendanceCommandHandler{attendanceRepo: attendanceRepo}
}

func (h *DeleteEmptyAttendanceCommandHandler) Handle(ctx context.Context, cmd *DeleteEmptyAttendanceCommand) (common.ResultValue[int64], error) {
	rowsAffected, err := h.attendanceRepo.DeleteEmptyAbsen(ctx)
	if err != nil {
		return common.FailureValue[int64](domain.AttendanceNotFound()), err
	}

	return common.SuccessValue(rowsAffected), nil
}
