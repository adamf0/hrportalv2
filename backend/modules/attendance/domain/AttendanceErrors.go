package domain

import "hrportal_backend/common/domain"

func AttendanceNotFound() domain.Error {
	return domain.NotFoundError("Attendance.NotFound", "Data presensi tidak ditemukan")
}

func AlreadyCheckedIn() domain.Error {
	return domain.ConflictError("Attendance.AlreadyCheckedIn", "Anda sudah melakukan absen masuk hari ini")
}

func LocationOutsideCampus() domain.Error {
	return domain.FailureError("Attendance.LocationOutsideCampus", "Koordinat GPS Anda berada di luar radius kampus Pakuan")
}
