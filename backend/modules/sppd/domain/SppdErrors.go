package domain

import "hrportal_backend/common/domain"

func SppdNotFound() domain.Error {
	return domain.NotFoundError("Sppd.NotFound", "Data permohonan SPPD tidak ditemukan")
}
