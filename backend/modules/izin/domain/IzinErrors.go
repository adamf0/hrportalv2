package domain

import "hrportal_backend/common/domain"

func EmptyData() domain.Error {
	return domain.NotFoundError("Izin.EmptyData", "data is not found")
}
func IzinNotFound() domain.Error {
	return domain.NotFoundError("Izin.NotFound", "Data permohonan izin tidak ditemukan")
}
