import 'package:flutter/material.dart';
import '../../../../core/mediator/mediator.dart';
import '../application/get_leaves/get_leaves_query.dart';
import '../application/get_supervisors/get_supervisors_query.dart';
import '../application/get_verification_leaves/get_verification_leaves_query.dart';
import '../application/submit_leave/submit_leave_command.dart';
import '../application/update_leave_status/update_leave_status_command.dart';
import '../domain/leave.dart';

import '../../../../core/api_client.dart';

class LeaveBloc extends ChangeNotifier {
  final Mediator _mediator = Mediator();

  List<LeaveRequest> _leaves = [];
  List<LeaveRequest> get leaves => _leaves;

  List<LeaveRequest> _verificationLeaves = [];
  List<LeaveRequest> get verificationLeaves => _verificationLeaves;

  List<Supervisor> _supervisors = [];
  List<Supervisor> get supervisors => _supervisors;

  List<CutiTypeSummary> _cutiTypeSummaries = [];
  List<CutiTypeSummary> get cutiTypeSummaries => _cutiTypeSummaries;

  int _sisaCuti = 12;
  int get sisaCuti => _sisaCuti;

  int _cutiDiambil = 4;
  int get cutiDiambil => _cutiDiambil;

  int _cutiPending = 1;
  int get cutiPending => _cutiPending;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> _calculateCutiStats() async {
    int totalDiambil = 0;
    int totalPending = 0;
    final currentYear = DateTime.now().year;

    // 1. Fetch masterdata jenis-cuti from API
    List<Map<String, dynamic>> jenisCutiList = [];
    try {
      final res = await ApiClient.get(
        Uri.parse("${ApiClient.baseUrl}/api/masterdata/jenis-cuti"),
      );
      if (res is List) {
        jenisCutiList = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    if (jenisCutiList.isEmpty) {
      jenisCutiList = [
        {"id": 1, "name": "Tahunan", "quota": 12},
        {"id": 2, "name": "Sakit", "quota": 30},
        {"id": 3, "name": "Melahirkan", "quota": 90},
        {"id": 4, "name": "Menunaikan Ibadah Haji", "quota": 40},
        {"id": 5, "name": "Menunaikan Ibadah Umroh", "quota": 12},
        {"id": 6, "name": "Diluar Tanggungan", "quota": 0},
        {"id": 7, "name": "Alasan Penting (Pernikahan)", "quota": 3},
        {"id": 8, "name": "Alasan Penting (Keluarga Meninggal Dunia)", "quota": 3},
        {"id": 9, "name": "Alasan Penting (Menikahkan Anak)", "quota": 2},
        {"id": 10, "name": "Alasan Penting (Mengkhitan / Baptis Anak)", "quota": 2},
        {"id": 11, "name": "Alasan Penting (Istri Melahirkan)", "quota": 2},
      ];
    }

    final List<CutiTypeSummary> summaries = [];

    for (var jc in jenisCutiList) {
      final id = jc['id'] is int ? jc['id'] as int : int.tryParse(jc['id'].toString()) ?? 1;
      final name = (jc['name'] ?? jc['nama'] ?? 'Cuti').toString();
      int defaultQuota = jc['quota'] is int ? jc['quota'] as int : (id == 1 ? 12 : 0);

      int diambil = 0;
      int pending = 0;

      for (var leave in _leaves) {
        if (leave.startDate.year != currentYear) continue;

        final isCuti = leave.type.toLowerCase().contains("cuti");
        if (!isCuti) continue;

        final leaveTypeLower = leave.type.toLowerCase();
        final nameLower = name.toLowerCase();

        bool isMatch = false;
        if (id == 1 && (leaveTypeLower.contains("tahunan") || leaveTypeLower == "cuti")) {
          isMatch = true;
        } else if (leaveTypeLower.contains(nameLower)) {
          isMatch = true;
        }

        if (isMatch) {
          final days = leave.endDate.difference(leave.startDate).inDays + 1;
          final statusLower = leave.status.toLowerCase();
          if (statusLower == "acc" ||
              statusLower == "disetujui" ||
              statusLower == "approved" ||
              statusLower.contains("acc") ||
              statusLower.contains("terima")) {
            diambil += days;
          } else if (statusLower == "menunggu" ||
              statusLower == "pengajuan" ||
              statusLower == "pending") {
            pending += 1;
          }
        }
      }

      int sisa = defaultQuota > 0 ? (defaultQuota - diambil) : 0;
      if (sisa < 0) sisa = 0;

      if (id == 1) {
        totalDiambil = diambil;
        totalPending = pending;
      }

      summaries.add(CutiTypeSummary(
        id: id,
        name: name,
        sisa: sisa,
        diambil: diambil,
        pending: pending,
        quota: defaultQuota,
      ));
    }

    _cutiTypeSummaries = summaries;
    _cutiDiambil = totalDiambil;
    _cutiPending = totalPending;
    _sisaCuti = 12 - totalDiambil;
    if (_sisaCuti < 0) _sisaCuti = 0;
  }

  Future<void> fetchLeaves({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      final res = await _mediator.send(GetLeavesQuery());
      _leaves = List.from(res);
      await _calculateCutiStats();
      await fetchVerificationLeaves();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!isRefresh) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchVerificationLeaves() async {
    try {
      final res = await _mediator.send(GetVerificationLeavesQuery());
      _verificationLeaves = List.from(res);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateStatus(String id, String status, {String? note}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _mediator.send(
        UpdateLeaveStatusCommand(id: id, status: status, note: note),
      );
      if (success) {
        await fetchLeaves(isRefresh: true);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchSupervisors() async {
    try {
      final res = await _mediator.send(GetSupervisorsQuery());
      _supervisors = List.from(res);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submitLeaveForm({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String supervisorId,
    required String supervisorName,
    String? attachmentPath,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final rangeStr = startDate.day == endDate.day
          ? "${startDate.day} ${_getMonthNameShort(startDate.month)} ${startDate.year}"
          : "${startDate.day} - ${endDate.day} ${_getMonthNameShort(startDate.month)} ${startDate.year}";

      final newReq = LeaveRequest(
        id: "req_${DateTime.now().millisecondsSinceEpoch}",
        type: type,
        status: "Pengajuan",
        dateRange: rangeStr,
        details: reason,
        note: "Menunggu verifikasi: $supervisorName",
        startDate: startDate,
        endDate: endDate,
      );

      final success = await _mediator.send(
        SubmitLeaveCommand(
          request: newReq,
          supervisorId: supervisorId,
          attachmentPath: attachmentPath,
        ),
      );

      if (success) {
        await fetchLeaves(isRefresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  String _getMonthNameShort(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    if (month < 1 || month > 12) return "";
    return months[month - 1];
  }
}
