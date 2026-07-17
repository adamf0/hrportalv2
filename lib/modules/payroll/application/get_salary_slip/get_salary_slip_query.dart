import '../../../../core/mediator/mediator.dart';
import '../../domain/payroll.dart';

class GetSalarySlipQuery extends IQuery<PayrollData?> {
  final String nip;
  final String year;
  final String month;

  GetSalarySlipQuery({
    required this.nip,
    required this.year,
    required this.month,
  });
}
