import 'package:flutter/material.dart';
import '../../../../core/mediator/mediator.dart';
import '../application/get_salary_slip/get_salary_slip_query.dart';
import '../domain/payroll.dart';

class PayrollBloc extends ChangeNotifier {
  final Mediator _mediator = Mediator();

  PayrollData? _currentPayrollData;
  PayrollData? get currentPayrollData => _currentPayrollData;

  String _selectedPayrollMonth = 'Jun';
  String get selectedPayrollMonth => _selectedPayrollMonth;

  String _selectedPayrollYear = '2026';
  String get selectedPayrollYear => _selectedPayrollYear;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> fetchPayroll(String nip) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final res = await _mediator.send(
        GetSalarySlipQuery(
          nip: nip,
          year: _selectedPayrollYear,
          month: _selectedPayrollMonth,
        ),
      );
      _currentPayrollData = res;
    } catch (e) {
      _errorMessage = e.toString();
      _currentPayrollData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedMonth(String month, String nip) {
    _selectedPayrollMonth = month;
    notifyListeners();
    fetchPayroll(nip);
  }

  void setSelectedYear(String year, String nip) {
    _selectedPayrollYear = year;
    notifyListeners();
    fetchPayroll(nip);
  }
}
