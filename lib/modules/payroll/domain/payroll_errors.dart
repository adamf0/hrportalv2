import 'package:hrportalv2/common/domain/domain_error.dart';

abstract class PayrollError extends DomainError {
  const PayrollError(super.message);
}

class PayrollNotFoundError extends PayrollError {
  const PayrollNotFoundError()
      : super('Data gaji tidak ditemukan untuk periode yang dipilih.');
}

class InvalidPayrollPeriodError extends PayrollError {
  const InvalidPayrollPeriodError()
      : super('Periode tahun atau bulan slip gaji yang dipilih tidak valid.');
}

class InvalidEmployeeNipError extends PayrollError {
  const InvalidEmployeeNipError()
      : super('Format Nomor Induk Pegawai (NIP) tidak sah.');
}

class PayrollGenericError extends PayrollError {
  const PayrollGenericError(super.message);
}
