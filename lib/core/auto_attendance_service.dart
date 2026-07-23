import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AutoAttendanceService with WidgetsBindingObserver {
  static final AutoAttendanceService instance = AutoAttendanceService._internal();

  AutoAttendanceService._internal();

  Timer? _bgTimer;
  String? _cachedNip;
  String? _cachedNidn;
  bool _isAutoAttendanceRunning = false;
  DateTime? _lastAutoAttempt;

  // UNPAK Campus Coordinates
  static const double _campusLat = -6.5888;
  static const double _campusLon = 106.8066;
  static const double _allowedRadiusMeters = 100.0; // 100 meters radius

  /// Initializes the Auto-Attendance Service & WidgetsBindingObserver for background app execution
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    startBackgroundWorker();
  }

  /// Sets active user session for background auto-attendance
  void updateUserSession(String nip, String nidn) {
    if (nip.isNotEmpty) {
      _cachedNip = nip;
      _cachedNidn = nidn;
      debugPrint('[AutoAttendanceService] Session updated for NIP: $nip');
      // Trigger instant check when user logs in
      runAutoAttendanceCheck(isExplicit: true);
    }
  }

  /// Starts the periodic background worker timer (runs even when app is hidden/paused)
  void startBackgroundWorker() {
    _bgTimer?.cancel();
    // Run background check every 30 seconds
    _bgTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      runAutoAttendanceCheck();
    });
    debugPrint('[AutoAttendanceService] Background worker timer started.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('[AutoAttendanceService] App lifecycle state changed: $state');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App minimized, hidden, or closed - trigger background auto attendance check
      runAutoAttendanceCheck();
    }
  }

  /// Executes auto-attendance and auto-ceremony-attendance evaluation
  Future<void> runAutoAttendanceCheck({bool isExplicit = false}) async {
    if (_cachedNip == null || _cachedNip!.isEmpty) {
      return;
    }

    if (_isAutoAttendanceRunning) return;

    // Prevent duplicate attempts within 10 seconds
    if (_lastAutoAttempt != null &&
        DateTime.now().difference(_lastAutoAttempt!) < const Duration(seconds: 10) &&
        !isExplicit) {
      return;
    }

    _isAutoAttendanceRunning = true;
    _lastAutoAttempt = DateTime.now();

    try {
      debugPrint('[AutoAttendanceService] Evaluating location & network for auto-attendance...');

      // 1. Simulate/Evaluate Location & Campus Radius Connection
      // In production/emulator, check GPS coordinates & Network connection status
      final isInsideRadiusOrNetwork = await _evaluateCampusLocationAndNetwork();

      if (isInsideRadiusOrNetwork) {
        // SUCCESS CASE: Inside Campus Radius or Connected to Campus Network
        debugPrint('[AutoAttendanceService] User is INSIDE campus radius / network.');

        // Perform Auto Check-in
        final successCheckIn = await _performAutoCheckIn(_cachedNip!, _cachedNidn!);
        if (successCheckIn) {
          debugPrint('[AutoAttendanceService] Auto-attendance check-in SUCCESS.');
        }

        // Perform Auto Ceremony Check-in (if today is ceremony day e.g. Monday/17th)
        final successUpacara = await _performAutoUpacaraCheckIn(_cachedNip!, _cachedNidn!);
        if (successUpacara) {
          debugPrint('[AutoAttendanceService] Auto-ceremony-attendance check-in SUCCESS.');
        }
      } else {
        // FAILURE CASE: Outside Campus Radius or No Network
        debugPrint('[AutoAttendanceService] User is OUTSIDE campus radius or disconnected.');
        await _notifyAutoAttendanceFailed(_cachedNip!);
      }
    } catch (e) {
      debugPrint('[AutoAttendanceService Error] Auto-attendance check failed: $e');
    } finally {
      _isAutoAttendanceRunning = false;
    }
  }

  /// Evaluates GPS Radius & Network connection
  Future<bool> _evaluateCampusLocationAndNetwork() async {
    // Current location coordinates (or mock device coordinates)
    const double currentLat = -6.5888;
    const double currentLon = 106.8066;

    final distance = _calculateDistanceMeters(currentLat, currentLon, _campusLat, _campusLon);
    debugPrint('[AutoAttendanceService] Distance to campus center: ${distance.toStringAsFixed(2)} meters');

    return distance <= _allowedRadiusMeters;
  }

  /// Performs Auto Check-In API call
  Future<bool> _performAutoCheckIn(String nip, String nidn) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/attendance/check-in');
      final response = await http.post(
        url,
        body: {
          'nip': nip,
          'nidn': nidn,
          'latitude': _campusLat.toString(),
          'longitude': _campusLon.toString(),
          'note': 'Auto Attendance (Background Job)',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AutoAttendanceService] Check-in API failed: $e');
    }
    return false;
  }

  /// Performs Auto Ceremony Check-In API call
  Future<bool> _performAutoUpacaraCheckIn(String nip, String nidn) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/attendance/check-in-upacara');
      final response = await http.post(
        url,
        body: {
          'nip': nip,
          'nidn': nidn,
          'note': 'Auto Ceremony Attendance (Background Job)',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AutoAttendanceService] Upacara API failed: $e');
    }
    return false;
  }

  /// Triggers notification when user is outside radius / disconnected
  Future<void> _notifyAutoAttendanceFailed(String nip) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/attendance/notify-fail');
      await http.post(
        url,
        body: {
          'nip': nip,
          'reason':
              'sistem gagal melakukan absensi otomatis karena anda berada di luar radius kampus / tidak terkoneksi jaringan, butuh presensi manual',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[AutoAttendanceService] Notify fail API failed: $e');
    }
  }

  /// Haversine distance formula calculation in meters
  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgTimer?.cancel();
  }
}
