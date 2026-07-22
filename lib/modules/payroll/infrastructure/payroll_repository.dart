import 'package:flutter/foundation.dart';
import 'package:hrportalv2/core/api_client.dart';
import '../domain/payroll.dart';
import '../domain/payroll_errors.dart';
import '../domain/i_payroll_repository.dart';

class PayrollRepository implements IPayrollRepository {
  final Map<String, PayrollData?> _mockDatabase = {
    "Jan-2026": PayrollData.mock("Januari", "2026"),
    "Feb-2026": PayrollData.mock("Februari", "2026"),
    "Mar-2026": PayrollData.mock("Maret", "2026"),
    "Apr-2026": PayrollData.mock("April", "2026"),
    "Mei-2026": PayrollData.mock("Mei", "2026"),
    "Jun-2026": PayrollData.mock("Juni", "2026"),
  };

  @override
  Future<PayrollData?> fetchPayroll(
      String nip, String year, String month) async {
    final yearInt = int.tryParse(year);
    if (yearInt == null || yearInt < 2000 || yearInt > 2050) {
      throw const InvalidPayrollPeriodError();
    }

    final Map<String, String> monthMap = {
      "Jan": "01",
      "Feb": "02",
      "Mar": "03",
      "Apr": "04",
      "Mei": "05",
      "Jun": "06",
      "Jul": "07",
      "Agu": "08",
      "Sep": "09",
      "Okt": "10",
      "Nov": "11",
      "Des": "12",
    };

    final numericMonth = monthMap[month] ?? "06";
    final targetNip = nip.isNotEmpty ? nip : "";

    try {
      final responseData = await ApiClient.post(
        Uri.parse("https://hrportal.unpak.ac.id/api/slip_gaji"),
        body: {
          "nip": targetNip,
          "tahun": year,
          "bulan": numericMonth,
        },
      );

      if (responseData is Map<String, dynamic> &&
          responseData['data'] != null) {
        return PayrollData.fromJson(responseData['data']);
      } else {
        throw const PayrollNotFoundError();
      }
    } on ApiException catch (e, stackTrace) {
      debugPrint(
          '[PayrollRepository API Exception]: ${e.message}\n$stackTrace');

      final key = "$month-$year";
      if (_mockDatabase.containsKey(key)) {
        return _mockDatabase[key];
      }
      throw PayrollGenericError(e.message);
    } catch (e, stackTrace) {
      debugPrint('[PayrollRepository Unhandled Error]: $e\n$stackTrace');
      if (e is PayrollError) rethrow;

      final key = "$month-$year";
      if (_mockDatabase.containsKey(key)) {
        return _mockDatabase[key];
      }
      throw const PayrollNotFoundError();
    }
  }
}
