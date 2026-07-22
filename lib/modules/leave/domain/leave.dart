import 'leave_errors.dart';

class LeaveRequest {
  final String id;
  final String type;
  final String status; // 'Pengajuan', 'Di ACC Atasan', 'ACC SDM', 'Tolak Atasan', 'Tolak SDM'
  final String dateRange;
  final String details;
  final String note;
  final DateTime startDate;
  final DateTime endDate;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.dateRange,
    required this.details,
    required this.note,
    required this.startDate,
    required this.endDate,
  });

  /// Domain Invariant Rule Validation (Domain Business Rules)
  void validateBusinessRules({
    required int remainingQuota,
    String? supervisorId,
  }) {
    if (endDate.isBefore(startDate)) {
      throw const InvalidLeavePeriodError();
    }
    if (details.trim().isEmpty) {
      throw const EmptyLeaveReasonError();
    }
    if (supervisorId == null || supervisorId.trim().isEmpty) {
      throw const SupervisorNotAssignedError();
    }
    final requestedDays = endDate.difference(startDate).inDays + 1;
    if (type.toLowerCase().contains("cuti") && requestedDays > remainingQuota) {
      throw ExceededLeaveQuotaError(requestedDays, remainingQuota);
    }
  }
}

class Supervisor {
  final String id;
  final String name;
  final String role;

  Supervisor({
    required this.id,
    required this.name,
    required this.role,
  });
}

class CutiTypeSummary {
  final int id;
  final String name;
  final int sisa;
  final int diambil;
  final int pending;
  final int quota;

  CutiTypeSummary({
    required this.id,
    required this.name,
    required this.sisa,
    required this.diambil,
    required this.pending,
    required this.quota,
  });
}
