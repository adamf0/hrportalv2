import 'attendance_errors.dart';

class AttendanceRecord {
  final bool isCheckedIn;
  final String checkInTime;
  final bool isCheckedOut;
  final String checkOutTime;
  final String statusNote;
  final bool isUpacaraCheckedIn;
  final String upacaraTime;

  AttendanceRecord({
    required this.isCheckedIn,
    required this.checkInTime,
    required this.isCheckedOut,
    required this.checkOutTime,
    required this.statusNote,
    required this.isUpacaraCheckedIn,
    required this.upacaraTime,
  });

  factory AttendanceRecord.empty() {
    return AttendanceRecord(
      isCheckedIn: false,
      checkInTime: '--:--',
      isCheckedOut: false,
      checkOutTime: '--:--',
      statusNote: 'Belum Presensi',
      isUpacaraCheckedIn: false,
      upacaraTime: '--:--',
    );
  }

  /// Domain Invariant Validation: Validate if check-in business rules permit operation
  void validateCheckInAllowed() {
    if (isCheckedIn) {
      throw const AlreadyCheckedInError();
    }
  }

  /// Domain Invariant Validation: Validate if check-out business rules permit operation
  void validateCheckOutAllowed() {
    if (!isCheckedIn) {
      throw const NotCheckedInYetError();
    }
    if (isCheckedOut) {
      throw const AlreadyCheckedOutError();
    }
  }

  /// Domain Invariant Validation: Check-in and Check-out datetime ordering
  static void validateTimeOrder(DateTime checkInDateTime, DateTime checkOutDateTime) {
    if (checkOutDateTime.isBefore(checkInDateTime)) {
      throw const InvalidAttendanceTimeOrderError();
    }
  }

  AttendanceRecord copyWith({
    bool? isCheckedIn,
    String? checkInTime,
    bool? isCheckedOut,
    String? checkOutTime,
    String? statusNote,
    bool? isUpacaraCheckedIn,
    String? upacaraTime,
  }) {
    return AttendanceRecord(
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      isCheckedOut: isCheckedOut ?? this.isCheckedOut,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      statusNote: statusNote ?? this.statusNote,
      isUpacaraCheckedIn: isUpacaraCheckedIn ?? this.isUpacaraCheckedIn,
      upacaraTime: upacaraTime ?? this.upacaraTime,
    );
  }
}

class ActivityLogItem {
  final String title;
  final String time;
  final bool isSuccess;

  ActivityLogItem({
    required this.title,
    required this.time,
    required this.isSuccess,
  });
}

class AbsenUpacaraData {
  final int id;
  final String nip;
  final String nidn;
  final String tanggal;
  final String createdAt;

  AbsenUpacaraData({
    required this.id,
    required this.nip,
    required this.nidn,
    required this.tanggal,
    required this.createdAt,
  });

  factory AbsenUpacaraData.fromJson(Map<String, dynamic> json) {
    return AbsenUpacaraData(
      id: json['id'] as int? ?? 0,
      nip: json['nip'] as String? ?? '',
      nidn: json['nidn'] as String? ?? '',
      tanggal: json['tanggal'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
