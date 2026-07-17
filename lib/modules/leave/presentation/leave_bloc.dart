import 'package:flutter/material.dart';
import '../../../../core/mediator/mediator.dart';
import '../application/get_leaves/get_leaves_query.dart';
import '../application/get_supervisors/get_supervisors_query.dart';
import '../application/submit_leave/submit_leave_command.dart';
import '../domain/leave.dart';

class LeaveBloc extends ChangeNotifier {
  final Mediator _mediator = Mediator();

  List<LeaveRequest> _leaves = [];
  List<LeaveRequest> get leaves => _leaves;

  List<Supervisor> _supervisors = [];
  List<Supervisor> get supervisors => _supervisors;

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

  void _calculateCutiStats() {
    int diambil = 0;
    int pending = 0;
    final currentYear = DateTime.now().year;

    for (var leave in _leaves) {
      if (leave.startDate.year != currentYear) {
        continue;
      }

      final isCuti = leave.type.toLowerCase().contains("cuti");
      final days = leave.endDate.difference(leave.startDate).inDays + 1;
      
      final statusLower = leave.status.toLowerCase();
      if (statusLower == "acc" || statusLower == "disetujui" || statusLower == "approved" || statusLower.contains("acc")) {
        if (isCuti) {
          diambil += days;
        }
      } else if (statusLower == "menunggu" || statusLower == "pengajuan" || statusLower == "pending") {
        pending += 1;
      }
    }
    _cutiDiambil = diambil;
    _cutiPending = pending;
    _sisaCuti = 12 - diambil;
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
      _calculateCutiStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!isRefresh) {
        _isLoading = false;
      }
      notifyListeners();
    }
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
        _leaves.insert(0, newReq);
        _calculateCutiStats();
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
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
    ];
    if (month < 1 || month > 12) return "";
    return months[month - 1];
  }
}
