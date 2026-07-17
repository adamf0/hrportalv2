package domain

import "hrportal_backend/common/domain"

func AccountNotFound() domain.Error {
	return domain.NotFoundError("Account.NotFound", "Akun atau data pegawai tidak ditemukan")
}

func InvalidCredentials() domain.Error {
	return domain.FailureError("Account.InvalidCredentials", "NIP/NIDN atau password salah")
}
