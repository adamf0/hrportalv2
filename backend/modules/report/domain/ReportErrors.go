package domain

import "hrportal_backend/common/domain"

func ReportNotFound() domain.Error {
	return domain.NotFoundError("Report.NotFound", "Data laporan tidak ditemukan")
}
