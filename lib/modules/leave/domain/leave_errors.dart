import 'package:hrportalv2/common/domain/domain_error.dart';

abstract class LeaveError extends DomainError {
  const LeaveError(super.message);
}

class InvalidLeavePeriodError extends LeaveError {
  const InvalidLeavePeriodError()
      : super('Tanggal berakhir pengajuan tidak boleh mendahului tanggal mulai.');
}

class ExceededLeaveQuotaError extends LeaveError {
  final int requestedDays;
  final int remainingQuota;

  ExceededLeaveQuotaError(this.requestedDays, this.remainingQuota)
      : super(
            'Jumlah pengajuan ($requestedDays hari) melebihi sisa kuota cuti tahunan ($remainingQuota hari).');
}

class HolidaySelectedError extends LeaveError {
  const HolidaySelectedError()
      : super('Pengajuan cuti/izin tidak dapat dilakukan pada hari libur nasional atau akhir pekan.');
}

class EmptyLeaveReasonError extends LeaveError {
  const EmptyLeaveReasonError()
      : super('Alasan pengajuan wajib diisi secara jelas.');
}

class SupervisorNotAssignedError extends LeaveError {
  const SupervisorNotAssignedError()
      : super('Atasan verifikator wajib dipilih untuk memproses verifikasi pengajuan.');
}
