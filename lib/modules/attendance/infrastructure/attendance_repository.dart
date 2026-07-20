import 'package:flutter/foundation.dart';
import '../../../core/location_wifi_helper.dart';
import '../../../core/api_client.dart';
import '../../../core/sso_helper.dart';
import '../domain/i_attendance_repository.dart';
import '../domain/attendance.dart';

class AttendanceRepository implements IAttendanceRepository {
  @override
  Future<bool> checkIn(
      double lat, double lon, String ip, bool isUpacara, String note) async {
    final insideCampus = await isWithinCampusPolygon(lat, lon);
    if (!insideCampus) return false;

    final validWifi = await isPakuanWifi(ip);
    if (!validWifi) return false;

    try {
      final session = await SsoHelper.getSession();
      if (session == null) return false;
      final nip = session['nip'] ?? '';
      final role = session['role'] ?? '';
      final nidn = role == 'Dosen' ? nip : '';

      final endpoint = isUpacara
          ? "/api/attendance/check-in-upacara"
          : "/api/attendance/check-in";

      final responseData = await ApiClient.post(
        Uri.parse("${ApiClient.baseUrl}$endpoint"),
        body: {
          "nip": nip,
          "nidn": nidn,
          "latitude": lat.toString(),
          "longitude": lon.toString(),
          "note": note,
        },
      );

      return responseData != null;
    } catch (e, stackTrace) {
      debugPrint('[AttendanceRepository checkIn error]: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> checkOut(double lat, double lon, String ip) async {
    final insideCampus = await isWithinCampusPolygon(lat, lon);
    if (!insideCampus) return false;

    try {
      final session = await SsoHelper.getSession();
      if (session == null) return false;
      final nip = session['nip'] ?? '';
      final role = session['role'] ?? '';
      final nidn = role == 'Dosen' ? nip : '';

      final responseData = await ApiClient.post(
        Uri.parse("${ApiClient.baseUrl}/api/attendance/check-out"),
        body: {
          "nip": nip,
          "nidn": nidn,
        },
      );

      return responseData != null;
    } catch (e, stackTrace) {
      debugPrint('[AttendanceRepository checkOut error]: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> isWithinCampusPolygon(double lat, double lon) async {
    final insidePoly1 = LocationWifiHelper.isPointInPolygon(
        lat, lon, LocationWifiHelper.polygon1);
    final insidePoly2 = LocationWifiHelper.isPointInPolygon(
        lat, lon, LocationWifiHelper.polygon2);
    return insidePoly1 || insidePoly2;
  }

  @override
  Future<bool> isPakuanWifi(String ip) async {
    return LocationWifiHelper.isPakuanIp(ip);
  }

  @override
  Future<AttendanceHistoryResult> fetchHistory() async {
    try {
      final responseData = await ApiClient.get(
        Uri.parse("${ApiClient.baseUrl}/api/attendance/history"),
      );

      if (responseData is List) {
        final List<ActivityLogItem> activities = [];
        String? todayCheckIn;
        String? todayCheckOut;

        final now = DateTime.now();
        final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        for (var json in responseData) {
          final tanggalStr = json['tanggal'] as String? ?? '';
          final masukStr = json['absen_masuk'] as String?;
          final keluarStr = json['absen_keluar'] as String?;

          final isToday = tanggalStr == todayStr;

          if (masukStr != null) {
            final dt = DateTime.tryParse(masukStr);
            if (dt != null) {
              // Convert to local time because the database stores in UTC
              final localDt = dt.toLocal();
              activities.add(ActivityLogItem(
                title: 'Absen Masuk Berhasil',
                time: '$tanggalStr • ${_formatTime(localDt)} AM',
                isSuccess: true,
              ));
              if (isToday) {
                todayCheckIn = _formatTime(localDt);
              }
            }
          }

          if (keluarStr != null) {
            final dt = DateTime.tryParse(keluarStr);
            if (dt != null) {
              // Convert to local time because the database stores in UTC
              final localDt = dt.toLocal();
              activities.add(ActivityLogItem(
                title: 'Absen Keluar Berhasil',
                time: '$tanggalStr • ${_formatTime(localDt)} PM',
                isSuccess: true,
              ));
              if (isToday) {
                todayCheckOut = _formatTime(localDt);
              }
            }
          }
        }
        return AttendanceHistoryResult(
          activities: activities,
          todayCheckInTime: todayCheckIn,
          todayCheckOutTime: todayCheckOut,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AttendanceRepository fetchHistory error]: $e\n$stackTrace');
    }
    return AttendanceHistoryResult(activities: []);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }
}
