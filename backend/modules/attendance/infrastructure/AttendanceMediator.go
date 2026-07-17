package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/attendance/application/CheckIn"
	"hrportal_backend/modules/attendance/application/CheckInUpacara"
	"hrportal_backend/modules/attendance/application/CheckOut"
	"hrportal_backend/modules/attendance/application/DeleteEmptyAttendance"
	"hrportal_backend/modules/attendance/application/GetAttendanceHistory"
	"hrportal_backend/modules/attendance/domain"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleAttendance(db *gorm.DB) error {
	repo := NewAttendanceRepository(db)

	checkInHandler := CheckIn.NewCheckInCommandHandler(repo)
	err := mediatr.RegisterRequestHandler[*CheckIn.CheckInCommand, common.ResultValue[*domain.Absen]](checkInHandler)
	if err != nil {
		return err
	}

	checkOutHandler := CheckOut.NewCheckOutCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*CheckOut.CheckOutCommand, common.ResultValue[*domain.Absen]](checkOutHandler)
	if err != nil {
		return err
	}

	historyHandler := GetAttendanceHistory.NewGetAttendanceHistoryQueryHandler(repo)
	err = mediatr.RegisterRequestHandler[*GetAttendanceHistory.GetAttendanceHistoryQuery, common.ResultValue[common.Paged[domain.Absen]]](historyHandler)
	if err != nil {
		return err
	}

	checkInUpacaraHandler := CheckInUpacara.NewCheckInUpacaraCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*CheckInUpacara.CheckInUpacaraCommand, common.ResultValue[*domain.AbsenUpacara]](checkInUpacaraHandler)
	if err != nil {
		return err
	}

	deleteEmptyHandler := DeleteEmptyAttendance.NewDeleteEmptyAttendanceCommandHandler(repo)
	err = mediatr.RegisterRequestHandler[*DeleteEmptyAttendance.DeleteEmptyAttendanceCommand, common.ResultValue[int64]](deleteEmptyHandler)
	if err != nil {
		return err
	}

	return nil
}
