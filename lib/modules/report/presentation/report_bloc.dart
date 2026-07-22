import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/report_domain.dart';
import '../domain/i_report_repository.dart';
import '../infrastructure/report_repository.dart';

class ReportBloc extends ChangeNotifier {
  final IReportRepository _repository;

  ReportBloc({IReportRepository? repository})
      : _repository = repository ?? ReportRepository() {
    _initDefaultFilter();
  }

  late ReportPeriodFilter _filter;
  ReportPeriodFilter get filter => _filter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<PegawaiReportItem> _employees = [];
  List<PegawaiReportItem> get employees => _employees;

  Map<String, Map<String, ReportCellData>> _matrix = {};
  Map<String, Map<String, ReportCellData>> get matrix => _matrix;

  Map<String, int> _totalPresensi = {};
  Map<String, int> get totalPresensi => _totalPresensi;

  Set<String> _holidays = {};
  Set<String> get holidays => _holidays;

  StreamSubscription? _streamSub;

  void _initDefaultFilter() {
    final now = DateTime.now();
    _filter = ReportPeriodFilter(
      month: now.month,
      year: now.year,
      periodType: ReportPeriodType.calendar,
    );
  }

  void setMonth(int month) {
    if (_filter.month == month) return;
    _filter = ReportPeriodFilter(
      month: month,
      year: _filter.year,
      periodType: _filter.periodType,
    );
    notifyListeners();
    fetchReportData();
  }

  void setYear(int year) {
    if (_filter.year == year) return;
    _filter = ReportPeriodFilter(
      month: _filter.month,
      year: year,
      periodType: _filter.periodType,
    );
    notifyListeners();
    fetchReportData();
  }

  void setPeriodType(ReportPeriodType type) {
    if (_filter.periodType == type) return;
    _filter = ReportPeriodFilter(
      month: _filter.month,
      year: _filter.year,
      periodType: type,
    );
    notifyListeners();
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    await _streamSub?.cancel();
    _isLoading = true;
    _isStreaming = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final snapshotData = await _repository.fetchLaporanMatrix(_filter);
      _updateDataFromMap(snapshotData);
      _isLoading = false;
      _isStreaming = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  void _updateDataFromMap(Map<String, dynamic> dataMap) {
    if (dataMap['employees'] is List<PegawaiReportItem>) {
      _employees = dataMap['employees'] as List<PegawaiReportItem>;
    }
    if (dataMap['matrix'] is Map<String, Map<String, ReportCellData>>) {
      _matrix = dataMap['matrix'] as Map<String, Map<String, ReportCellData>>;
    }
    if (dataMap['totalPresensi'] is Map<String, int>) {
      _totalPresensi = dataMap['totalPresensi'] as Map<String, int>;
    }
    if (dataMap['holidays'] is Set<String>) {
      _holidays = dataMap['holidays'] as Set<String>;
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
