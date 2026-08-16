import 'dart:convert';

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
    try {
      final session = await SsoHelper.getSession();
      if (session == null) return false;
      final nip = session['nip'] ?? '';
      final role = session['role'] ?? '';
      final nidn = role == 'Dosen' ? nip : '';

      final endpoint =
          isUpacara ? "/api/ceremony-attendance" : "/api/attendance/check-in";

      if (!isUpacara) {
        final currentHistory = await fetchHistory();
        if (currentHistory.todayCheckInTime != null) {
          debugPrint(
              '[AttendanceRepository] User is ALREADY checked in today in DB. Returning true without re-requesting API.');
          return true;
        }
      }

      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final safeNote = note.length > 10 ? note.substring(0, 10) : note;

      final name = session['name'] ?? session['nama'] ?? '';
      final unit = session['unit'] ?? '';
      final fakultas = session['fakultas'] ?? '';
      final prodi = session['prodi'] ?? '';

      final Map<String, String> bodyData = {
        "nip": nip,
        "nidn": nidn,
        "nama": name,
        "unit": unit,
        "fakultas": fakultas,
        "prodi": prodi,
        "latitude": lat.toString(),
        "longitude": lon.toString(),
        "note": safeNote,
      };
      if (isUpacara) {
        bodyData["tanggal"] = todayStr;
      }

      final responseData = await ApiClient.post(
        Uri.parse("${ApiClient.baseUrl}$endpoint"),
        body: bodyData,
      );

      return responseData != null;
    } catch (e, stackTrace) {
      debugPrint('[AttendanceRepository checkIn error]: $e\n$stackTrace');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sudah') && errStr.contains('absen')) {
        return true;
      }
      return false;
    }
  }

  @override
  Future<bool> checkOut(double lat, double lon, String ip) async {
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
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sudah') || errStr.contains('keluar')) {
        return true;
      }
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
      final session = await SsoHelper.getSession();
      final nip = session?['nip'] as String? ?? '';
      var nidn = session?['nidn'] as String? ?? '';
      if (nidn.isEmpty) {
        nidn = session?['sid'] as String? ??
            (session?['role'] == 'Dosen' ? nip : '');
      }

      final responseData = await ApiClient.get(
        Uri.parse("${ApiClient.baseUrl}/api/attendance/history"),
      );

      debugPrint("responseData: $responseData");
      List items = [];
      if (responseData is List) {
        items = responseData;
      } else if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        items = responseData['data'] as List;
      } else if (responseData is String) {
        try {
          final lines = responseData.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr.isNotEmpty) {
                final map = jsonDecode(jsonStr);
                if (map is Map<String, dynamic>) {
                  items.add(map);
                }
              }
            }
          }
        } catch (_) {}
      }

      if (items.isNotEmpty || responseData != null) {
        final List<ActivityLogItem> activities = [];
        String? todayCheckIn;
        String? todayCheckOut;

        final now = DateTime.now();
        final String todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final nowYesterday = now.subtract(const Duration(days: 1));
        final String yesterdayStr =
            "${nowYesterday.year}-${nowYesterday.month.toString().padLeft(2, '0')}-${nowYesterday.day.toString().padLeft(2, '0')}";

        // Check if user checked in yesterday (for night shift check-out resolution)
        bool yesterdayHasCheckIn = false;
        if (now.hour < 5) {
          for (var item in items) {
            final tStr = item['tanggal'] as String? ?? '';
            final mStr = item['absen_masuk'] as String?;
            if (tStr.contains(yesterdayStr) && mStr != null && mStr.isNotEmpty) {
              yesterdayHasCheckIn = true;
              break;
            }
          }
        }

        // Determine target date for today's active shift:
        // Case 1 (Under 05:00 AM & yesterday check-in exists): target yesterday (absen malam).
        // Case 2 (>= 05:00 AM or no yesterday check-in): target today.
        final String targetDateStr = (now.hour < 5 && yesterdayHasCheckIn)
            ? yesterdayStr
            : todayStr;

        for (var json in items) {
          final tanggalStr = json['tanggal'] as String? ?? '';
          final masukStr = json['absen_masuk'] as String?;
          final keluarStr = json['absen_keluar'] as String?;

          final bool isTargetShift = tanggalStr.contains(targetDateStr);

          // Format with actual record date for activity log
          final displayDateStr = tanggalStr.isNotEmpty ? tanggalStr : todayStr;

          if (masukStr != null && masukStr.isNotEmpty) {
            final dt = DateTime.tryParse(masukStr);
            if (dt != null) {
              final localDt = dt.toLocal();
              activities.add(ActivityLogItem(
                title: 'Absen Masuk Berhasil',
                time: '$displayDateStr • ${_formatTime(localDt)} AM',
                isSuccess: true,
              ));
              if (isTargetShift) {
                todayCheckIn = _formatTime(localDt);
              }
            }
          }

          if (keluarStr != null && keluarStr.isNotEmpty) {
            final dt = DateTime.tryParse(keluarStr);
            if (dt != null) {
              final localDt = dt.toLocal();
              activities.add(ActivityLogItem(
                title: 'Absen Keluar Berhasil',
                time: '$displayDateStr • ${_formatTime(localDt)} PM',
                isSuccess: true,
              ));
              if (isTargetShift) {
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
