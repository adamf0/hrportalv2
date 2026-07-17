import 'payroll.dart';

abstract class IPayrollRepository {
  Future<PayrollData?> fetchPayroll(String nip, String year, String month);
}
