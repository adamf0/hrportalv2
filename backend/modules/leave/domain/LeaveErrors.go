package domain

import "hrportal_backend/common/domain"

func LeaveNotFound() domain.Error {
	return domain.NotFoundError("Leave.NotFound", "Data permohonan cuti tidak ditemukan")
}

func InsufficientLeaveBalance() domain.Error {
	return domain.FailureError("Leave.InsufficientBalance", "Sisa jatah cuti tahunan Anda tidak mencukupi")
}

func InvalidLeaveDateRange() domain.Error {
	return domain.FailureError("Leave.InvalidDateRange", "Tanggal akhir cuti harus setelah atau sama dengan tanggal awal")
}
