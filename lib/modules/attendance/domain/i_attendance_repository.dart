import 'attendance.dart';

abstract class IAttendanceRepository {
  Future<bool> checkIn(double lat, double lon, String ip, bool isUpacara, String note);
  Future<bool> checkOut(double lat, double lon, String ip);
  Future<bool> isWithinCampusPolygon(double lat, double lon);
  Future<bool> isPakuanWifi(String ip);
  Future<AttendanceHistoryResult> fetchHistory();
}
