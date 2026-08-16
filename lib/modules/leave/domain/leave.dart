import 'leave_errors.dart';

/// LeaveRequest Domain Entity

class LeaveRequest {
  final String id;
  final String type; // Category/Type, e.g. 'Cuti', 'Izin', 'SPPD' or specific name
  final int? idJenisCuti;
  final int? idJenisIzin;
  final int? idJenisSppd;
  final String status; // 'Pengajuan', 'Di ACC Atasan', 'Terima SDM', 'Tolak Atasan', 'Tolak SDM'
  final String dateRange;
  final String details;
  final String note;
  final DateTime startDate;
  final DateTime endDate;
  final String? applicantName;
  final String? applicantNip;
  final String? applicantNidn;
  final String? supervisorId;
  final String? attachmentPath;
  final List<Supervisor>? members;
  final List<SppdMember>? sppdMembers;

  LeaveRequest({
    required this.id,
    required this.type,
    this.idJenisCuti,
    this.idJenisIzin,
    this.idJenisSppd,
    required this.status,
    required this.dateRange,
    required this.details,
    required this.note,
    required this.startDate,
    required this.endDate,
    this.applicantName,
    this.applicantNip,
    this.applicantNidn,
    this.supervisorId,
    this.attachmentPath,
    this.members,
    this.sppdMembers,
  });

  // Backward compatibility getters for snake_case field names
  // ignore: non_constant_identifier_names
  int? get id_jenis_cuti => idJenisCuti;
  // ignore: non_constant_identifier_names
  int? get id_jenis_izin => idJenisIzin;
  // ignore: non_constant_identifier_names
  int? get id_jenis_sppd => idJenisSppd;

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

class SppdMember {
  final String nip;
  final String nidn;
  final String nama;
  final String unit;
  final String fakultas;
  final String prodi;

  SppdMember({
    this.nip = '',
    this.nidn = '',
    required this.nama,
    this.unit = '',
    this.fakultas = '',
    this.prodi = '',
  });

  factory SppdMember.fromJson(Map<String, dynamic> json) {
    return SppdMember(
      nip: json['nip']?.toString() ?? json['id']?.toString() ?? '',
      nidn: json['nidn']?.toString() ?? '',
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? json['role']?.toString() ?? '',
      fakultas: json['fakultas']?.toString() ?? '',
      prodi: json['prodi']?.toString() ?? '',
    );
  }

  factory SppdMember.fromSupervisor(Supervisor s) {
    final idStr = s.id.trim();
    String nip = '';
    String nidn = '';
    if (idStr.length >= 9) {
      nip = idStr;
    } else if (idStr.isNotEmpty) {
      nidn = idStr;
    }
    return SppdMember(
      nip: nip,
      nidn: nidn,
      nama: s.name,
      unit: s.role,
    );
  }
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
