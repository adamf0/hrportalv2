import '../../../../core/mediator/mediator.dart';
import '../../domain/payroll.dart';
import '../../domain/i_payroll_repository.dart';
import 'get_salary_slip_query.dart';

class GetSalarySlipQueryHandler extends IQueryHandler<GetSalarySlipQuery, PayrollData?> {
  final IPayrollRepository repository;

  GetSalarySlipQueryHandler(this.repository);

  @override
  Future<PayrollData?> handle(GetSalarySlipQuery query) async {
    return await repository.fetchPayroll(query.nip, query.year, query.month);
  }
}
