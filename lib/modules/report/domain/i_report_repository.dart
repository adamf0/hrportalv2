import 'report_domain.dart';

abstract class IReportRepository {
  Future<Map<String, dynamic>> fetchLaporanMatrix(ReportPeriodFilter filter);
  Stream<Map<String, dynamic>> streamLaporanMatrix(ReportPeriodFilter filter);
}
