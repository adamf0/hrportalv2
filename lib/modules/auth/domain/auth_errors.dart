import 'package:hrportalv2/common/domain/domain_error.dart';

abstract class AuthError extends DomainError {
  const AuthError(super.message);
}

class EmptyCredentialsError extends AuthError {
  const EmptyCredentialsError()
      : super('Nama pengguna dan kata sandi tidak boleh kosong.');
}

class InvalidCredentialsError extends AuthError {
  const InvalidCredentialsError()
      : super('Nama pengguna atau kata sandi yang Anda masukkan tidak valid.');
}

class NetworkError extends AuthError {
  const NetworkError()
      : super('Kesalahan jaringan. Harap coba lagi nanti.');
}

class SessionExpiredError extends AuthError {
  const SessionExpiredError()
      : super('Sesi otentikasi telah kedaluwarsa. Silakan masuk kembali.');
}

class UnauthorizedError extends AuthError {
  const UnauthorizedError()
      : super('Akses tidak diizinkan. Silakan masuk kembali.');
}

class PermissionDeniedError extends AuthError {
  PermissionDeniedError(String permissionName)
      : super('Izin $permissionName ditolak.');
}
