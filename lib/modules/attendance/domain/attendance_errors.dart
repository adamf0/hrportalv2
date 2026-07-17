import 'package:hrportalv2/common/domain/domain_error.dart';

abstract class AttendanceError extends DomainError {
  const AttendanceError(super.message);
}

class AlreadyCheckedInError extends AttendanceError {
  const AlreadyCheckedInError()
      : super('Pengguna telah melakukan presensi masuk (check-in) untuk hari ini.');
}

class NotCheckedInYetError extends AttendanceError {
  const NotCheckedInYetError()
      : super('Presensi keluar tidak dapat dilakukan sebelum presensi masuk (check-in).');
}

class InvalidAttendanceTimeOrderError extends AttendanceError {
  const InvalidAttendanceTimeOrderError()
      : super('Waktu presensi keluar (check-out) tidak boleh lebih awal dari waktu presensi masuk (check-in).');
}

class AlreadyCheckedOutError extends AttendanceError {
  const AlreadyCheckedOutError()
      : super('Pengguna telah menyelesaikan presensi keluar (check-out) untuk hari ini.');
}
