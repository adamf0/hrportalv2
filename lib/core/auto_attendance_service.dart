import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../modules/attendance/infrastructure/attendance_repository.dart';
import 'location_wifi_helper.dart';
import 'sso_helper.dart';
import 'api_client.dart';
import 'fcm_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint(
        '[WorkManager Background Task] Executing background attendance check for killed app: $task');
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await AutoAttendanceService.instance
          .runAutoAttendanceCheck(isExplicit: true, isWorkmanager: true);
      return Future.value(true);
    } catch (e) {
      debugPrint('[WorkManager Background Task Error]: $e');
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FcmService.initLocalNotifications();
  } catch (_) {}

  if (service is AndroidServiceInstance) {
    try {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: "HR Portal • Presensi Latar Belakang Active",
        content: "Memuat status IP & GPS...",
      );
    } catch (_) {}

    service.on('setAsForeground').listen((event) {
      try {
        service.setAsForegroundService();
      } catch (_) {}
    });

    service.on('setAsBackground').listen((event) {
      try {
        service.setAsForegroundService();
      } catch (_) {}
    });
  }

  service.on('stopService').listen((event) {
    try {
      service.stopSelf();
    } catch (_) {}
  });

  // Periodic Foreground Service Timer (Runs continuously even across app kills)
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      final hasPermission =
          await LocationWifiHelper.checkLocationPermissionSafe();
      if (!hasPermission) return;

      final ip = await LocationWifiHelper.getActiveDeviceIp();
      final pos = await LocationWifiHelper.getCurrentLocation();
      bool matchesLocation = false;

      if (pos != null) {
        final insidePoly1 = LocationWifiHelper.isPointInPolygon(
            pos.latitude, pos.longitude, LocationWifiHelper.polygon1);
        final insidePoly2 = LocationWifiHelper.isPointInPolygon(
            pos.latitude, pos.longitude, LocationWifiHelper.polygon2);
        matchesLocation = insidePoly1 || insidePoly2;
      }

      final shortCampusStatus =
          matchesLocation ? 'Kampus' : 'Luar Kampus';
      final latStr = pos != null ? pos.latitude.toStringAsFixed(5) : 'Unknown';
      final lonStr = pos != null ? pos.longitude.toStringAsFixed(5) : 'Unknown';

      final checkInTimeStr =
          await AutoAttendanceService.instance.getTodayCheckInTimeFormatted();

      if (service is AndroidServiceInstance) {
        try {
          if (await service.isForegroundService()) {
            service.setForegroundNotificationInfo(
              title: "HR Portal • Presensi Active",
              content:
                  "Masuk: $checkInTimeStr | IP: $ip\nGPS: $latStr, $lonStr ($shortCampusStatus)",
            );
          }
        } catch (_) {}
      }

      // Auto Renew Token Check (Manual & Keycloak SSO)
      try {
        final token = await SsoHelper.getValidToken();
        if (token != null && token.isNotEmpty) {
          final refreshTimeStr = SsoHelper.lastTokenRefreshTime;
          await FcmService.showSilentSessionNotification(
            title: "HR Portal • Sesi Active",
            content:
                "Refresh Sesi: $refreshTimeStr\nStatus Sesi: Aktif (Auto Renew)",
          );
        }
      } catch (e) {
        debugPrint('[ForegroundService Token Renew Error]: $e');
      }

      // Perform background auto attendance check
      await AutoAttendanceService.instance
          .runAutoAttendanceCheck(isExplicit: true);
    } catch (e) {
      debugPrint('[ForegroundService Timer Error]: $e');
    }
  });
}

class AutoAttendanceService with WidgetsBindingObserver {
  static final AutoAttendanceService instance =
      AutoAttendanceService._internal();

  static Function()? onAttendanceUpdated;

  AutoAttendanceService._internal();

  Timer? _bgTimer;
  String? _cachedNip;
  String? _cachedNidn;
  bool _isAutoAttendanceRunning = false;
  bool _hasNotifiedSuccessToday = false;
  bool _hasNotifiedFailToday = false;
  String? _lastNotifiedDate;
  DateTime? _lastAutoAttempt;

  Future<String> getTodayCheckInTimeFormatted() async {
    try {
      final repository = AttendanceRepository();
      final history = await repository.fetchHistory();
      final todayTime = history.todayCheckInTime;
      if (todayTime != null && todayTime.isNotEmpty) {
        final now = DateTime.now();
        final String todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        if (!todayTime.contains('-') && !todayTime.contains('/')) {
          return "$todayStr $todayTime";
        }
        final clean = todayTime.replaceAll('/', '-');
        if (clean.length >= 16) {
          return clean.substring(0, 16);
        }
        return clean;
      }
      return 'Belum Absen';
    } catch (_) {
      return 'Belum Absen';
    }
  }

  Future<bool> _isAlreadyCheckedInToday() async {
    try {
      final repository = AttendanceRepository();
      final history = await repository.fetchHistory();
      return history.todayCheckInTime != null;
    } catch (_) {
      return false;
    }
  }

  void markAlreadyCheckedInInitial() {
    _hasNotifiedSuccessToday = true;
    debugPrint(
        '[AutoAttendanceService] Initial state already checked in today. Success notification suppressed.');
  }

  Future<void> triggerSuccessNotificationIfInitialNull() async {
    if (!_hasNotifiedSuccessToday) {
      _hasNotifiedSuccessToday = true;
    }
  }

  /// Initializes the Auto-Attendance Service, Native Foreground Service, and WorkManager safely without app crash
  void initialize() {
    try {
      WidgetsBinding.instance.addObserver(this);
      startBackgroundWorker();
      initWorkmanager();
      initForegroundService();
    } catch (e, stack) {
      debugPrint('[AutoAttendanceService initialize safe catch]: $e\n$stack');
    }
  }

  /// Configures & starts native Android/iOS Foreground Service
  Future<void> initForegroundService() async {
    try {
      await FcmService.initLocalNotifications();
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          autoStartOnBoot: true,
          isForegroundMode: true,
          notificationChannelId: 'hrportal_ongoing_channel',
          initialNotificationTitle: 'HR Portal • Presensi Active',
          initialNotificationContent: 'Memuat status IP & GPS...',
          foregroundServiceNotificationId: 9999,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      await service.startService();
      await FcmService.showSilentSessionNotification(
        title: "HR Portal • Sesi Active",
        content: "Refresh Sesi: ${SsoHelper.lastTokenRefreshTime}\nStatus Sesi: Aktif (Auto Renew)",
      );
      debugPrint('[AutoAttendanceService] Native Foreground Service started & configured to run continuously.');
    } catch (e) {
      debugPrint('[AutoAttendanceService Foreground Service Error]: $e');
    }
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    try {
      WidgetsFlutterBinding.ensureInitialized();
    } catch (_) {}
    return true;
  }

  /// Registers native Android/iOS WorkManager periodic & one-off tasks safely
  void initWorkmanager() {
    try {
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      Workmanager().registerPeriodicTask(
        "auto_attendance_killed_task",
        "autoAttendanceKilledTask",
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      scheduleImmediateKilledTask();
      debugPrint(
          '[AutoAttendanceService] Native WorkManager registered for killed app execution (15m interval + immediate oneoff).');
    } catch (e) {
      debugPrint('[AutoAttendanceService Workmanager Registration Error]: $e');
    }
  }

  /// Schedules an immediate one-off WorkManager background task safely
  void scheduleImmediateKilledTask() {
    try {
      Workmanager().registerOneOffTask(
        "auto_attendance_oneoff_${DateTime.now().millisecondsSinceEpoch}",
        "autoAttendanceTask",
        initialDelay: const Duration(seconds: 5),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      debugPrint(
          '[AutoAttendanceService] Immediate OneOff WorkManager task scheduled for killed app state.');
    } catch (e) {
      debugPrint('[AutoAttendanceService Schedule OneOff Error]: $e');
    }
  }

  /// Sets active user session for background auto-attendance
  void updateUserSession(String nip, String nidn) {
    try {
      if (nip.isNotEmpty) {
        _cachedNip = nip;
        _cachedNidn = nidn;
        debugPrint('[AutoAttendanceService] Session updated for NIP: $nip');
        runAutoAttendanceCheck(isExplicit: true);
      }
    } catch (e) {
      debugPrint('[AutoAttendanceService updateUserSession Error]: $e');
    }
  }

  /// Starts the periodic active timer (15s interval)
  void startBackgroundWorker() {
    try {
      _bgTimer?.cancel();
      _bgTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        runAutoAttendanceCheck();
      });
      debugPrint(
          '[AutoAttendanceService] Background worker timer started (15s interval).');
    } catch (e) {
      debugPrint('[AutoAttendanceService startBackgroundWorker Error]: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      super.didChangeAppLifecycleState(state);
      debugPrint('[AutoAttendanceService] App lifecycle state changed: $state');
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.resumed) {
        runAutoAttendanceCheck();
      } else if (state == AppLifecycleState.detached) {
        scheduleImmediateKilledTask();
      }
    } catch (e) {
      debugPrint(
          '[AutoAttendanceService didChangeAppLifecycleState Error]: $e');
    }
  }

  /// Executes auto-attendance and auto-ceremony-attendance evaluation
  Future<void> runAutoAttendanceCheck(
      {bool isExplicit = false, bool isWorkmanager = false}) async {
    try {
      // Check location permission safely before attempting auto-attendance
      final hasLocPermission =
          await LocationWifiHelper.checkLocationPermissionSafe();
      if (!hasLocPermission) {
        debugPrint(
            '[AutoAttendanceService] Location permission not granted yet. Skipping auto-check safely.');
        return;
      }

      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      if (_lastNotifiedDate != todayStr) {
        _lastNotifiedDate = todayStr;
        _hasNotifiedSuccessToday = false;
        _hasNotifiedFailToday = false;
      }

      if (_cachedNip == null || _cachedNip!.isEmpty) {
        final session = await SsoHelper.getSession();
        if (session != null && session['nip'] != null) {
          _cachedNip = session['nip'] as String?;
          _cachedNidn = session['role'] == 'Dosen' ? _cachedNip : '';
        }
      }

      if (_cachedNip == null || _cachedNip!.isEmpty) {
        return;
      }

      if (_isAutoAttendanceRunning) return;

      if (_lastAutoAttempt != null &&
          DateTime.now().difference(_lastAutoAttempt!) <
              const Duration(seconds: 10) &&
          !isExplicit) {
        return;
      }

      _isAutoAttendanceRunning = true;
      _lastAutoAttempt = DateTime.now();

      if (await _isAlreadyCheckedInToday()) {
        debugPrint(
            '[AutoAttendanceService] User has ALREADY checked in today. Skipping auto check-in request.');
        _hasNotifiedSuccessToday = true;
        onAttendanceUpdated?.call();
        return;
      }

      debugPrint(
          '[AutoAttendanceService] Evaluating location & network for auto-attendance...');

      final isInsideRadiusOrNetwork = await _evaluateCampusLocationAndNetwork();

      if (isInsideRadiusOrNetwork) {
        debugPrint(
            '[AutoAttendanceService] User is INSIDE campus radius / network.');

        final successCheckIn =
            await _performAutoCheckIn(_cachedNip!, _cachedNidn!);
        if (successCheckIn || isWorkmanager) {
          debugPrint(
              '[AutoAttendanceService] Auto-attendance check-in SUCCESS.');
          onAttendanceUpdated?.call();
        }
      } else {
        debugPrint(
            '[AutoAttendanceService] User is OUTSIDE campus radius or disconnected.');
        if (isWorkmanager || !_hasNotifiedFailToday) {
          _hasNotifiedFailToday = true;
          await _notifyAutoAttendanceFailed(_cachedNip!);
        }
      }
    } catch (e) {
      debugPrint(
          '[AutoAttendanceService Error] Auto-attendance check failed: $e');
    } finally {
      _isAutoAttendanceRunning = false;
    }
  }

  /// Evaluates GPS Radius & Network connection
  Future<bool> _evaluateCampusLocationAndNetwork() async {
    try {
      final ip = await LocationWifiHelper.getActiveDeviceIp();
      final pos = await LocationWifiHelper.getCurrentLocation();

      final matchesWifi = LocationWifiHelper.isPakuanIp(ip);
      bool matchesLocation = false;

      if (pos != null) {
        final insidePoly1 = LocationWifiHelper.isPointInPolygon(
            pos.latitude, pos.longitude, LocationWifiHelper.polygon1);
        final insidePoly2 = LocationWifiHelper.isPointInPolygon(
            pos.latitude, pos.longitude, LocationWifiHelper.polygon2);
        matchesLocation = insidePoly1 || insidePoly2;
      }

      debugPrint(
          '[AutoAttendanceService] Evaluation -> IP: $ip (WifiMatch: $matchesWifi), GPS: ${pos?.latitude}, ${pos?.longitude} (LocationMatch: $matchesLocation)');

      try {
        await FcmService.showOngoingStatusNotification(
          ip: ip,
          lat: pos?.latitude ?? 0.0,
          lon: pos?.longitude ?? 0.0,
          isInsideCampus: matchesLocation,
          isPakuanWifi: matchesWifi,
        );
      } catch (_) {}

      return matchesWifi || matchesLocation;
    } catch (e) {
      debugPrint('[AutoAttendanceService Evaluation Error]: $e');
      return false;
    }
  }

  /// Performs Auto Check-In API call
  Future<bool> _performAutoCheckIn(String nip, String nidn) async {
    try {
      final pos = await LocationWifiHelper.getCurrentLocation();
      final lat = pos?.latitude ?? -6.5989;
      final lon = pos?.longitude ?? 106.8106;
      final ip = await LocationWifiHelper.getActiveDeviceIp();

      final repository = AttendanceRepository();
      final success = await repository.checkIn(
        lat,
        lon,
        ip,
        false,
        'AutoBG',
      );

      return success;
    } catch (e) {
      debugPrint('[AutoAttendanceService] Check-in API failed: $e');
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

  /// Stops background timer, Foreground Service, and cancels WorkManager background tasks upon user logout
  Future<void> stopServiceAndCancelWorkmanager() async {
    try {
      _bgTimer?.cancel();
      _cachedNip = null;
      _cachedNidn = null;
      await FcmService.cancelOngoingNotification();
      try {
        final service = FlutterBackgroundService();
        service.invoke('stopService');
      } catch (_) {}
      try {
        await Workmanager().cancelAll();
        debugPrint(
            '[AutoAttendanceService] All WorkManager tasks and Foreground Service stopped upon logout.');
      } catch (e) {
        debugPrint('[AutoAttendanceService Logout Error]: $e');
      }
    } catch (e) {
      debugPrint('[AutoAttendanceService stopService Error]: $e');
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      _bgTimer?.cancel();
    } catch (_) {}
  }
}
