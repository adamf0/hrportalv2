import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import '../../../../core/location_wifi_helper.dart';
import '../../../../core/mediator/mediator.dart';
import '../../../../core/sso_helper.dart';
import '../../../../core/api_client.dart';
import '../application/check_in/check_in_command.dart';
import '../application/check_out/check_out_command.dart';
import '../application/get_history/get_history_query.dart';
import '../domain/attendance.dart';

import '../../../../core/auto_attendance_service.dart';
import '../../../../core/attendance_realtime_service.dart';

class AttendanceBloc extends ChangeNotifier {
  final Mediator _mediator = Mediator();

  bool _isCheckedIn = false;
  bool get isCheckedIn => _isCheckedIn;

  bool _isCheckedOut = false;
  bool get isCheckedOut => _isCheckedOut;

  String _checkInTime = '--:--';
  String get checkInTime => _checkInTime;

  String _checkOutTime = '--:--';
  String get checkOutTime => _checkOutTime;

  StreamSubscription? _realtimeWsSubscription;

  void initRealtimeWsListener(String nip, String nidn) {
    if (nip.isEmpty && nidn.isEmpty) return;
    AttendanceRealtimeService().connect(nip, nidn);

    _realtimeWsSubscription?.cancel();
    _realtimeWsSubscription =
        AttendanceRealtimeService().stream.listen((payload) {
      final type = payload['type'] as String?;

      String parseTime(String? timeStr) {
        if (timeStr == null || timeStr.isEmpty) return '--:--';
        try {
          final dt = DateTime.tryParse(timeStr);
          if (dt != null) {
            final localDt = dt.toLocal();
            return "${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}";
          }
          final parts = timeStr.split(' ');
          if (parts.length > 1) {
            final sub = parts[1].split(':');
            if (sub.length >= 2) return "${sub[0]}:${sub[1]}";
          } else {
            final sub = timeStr.split(':');
            if (sub.length >= 2) return "${sub[0]}:${sub[1]}";
          }
        } catch (_) {}
        return '--:--';
      }

      if (type == 'initial_state') {
        final tanggalStr = payload['tanggal'] as String? ?? '';
        final now = DateTime.now();
        final todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr =
            "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

        final isTargetDate = tanggalStr == todayStr ||
            (now.hour < 5 && tanggalStr == yesterdayStr);

        if (isTargetDate) {
          final masukStr = payload['absen_masuk'] as String?;
          if (masukStr != null && masukStr.isNotEmpty) {
            final formatted = parseTime(masukStr);
            if (formatted != '--:--') {
              _checkInTime = formatted;
              _isCheckedIn = true;
            }
          } else {
            _checkInTime = '--:--';
            _isCheckedIn = false;
          }

          final keluarStr = payload['absen_keluar'] as String?;
          if (keluarStr != null && keluarStr.isNotEmpty) {
            final formatted = parseTime(keluarStr);
            if (formatted != '--:--') {
              _checkOutTime = formatted;
              _isCheckedOut = true;
            }
          } else {
            _checkOutTime = '--:--';
            _isCheckedOut = false;
          }
        } else {
          _checkInTime = '--:--';
          _isCheckedIn = false;
          _checkOutTime = '--:--';
          _isCheckedOut = false;
        }
        notifyListeners();
      } else if (type == 'check_in') {
        final masukStr = payload['absen_masuk'] as String?;
        final formatted = parseTime(masukStr);
        if (formatted != '--:--') {
          _checkInTime = formatted;
          _isCheckedIn = true;
          notifyListeners();
        }
      } else if (type == 'check_out') {
        final keluarStr = payload['absen_keluar'] as String?;
        final formatted = parseTime(keluarStr);
        if (formatted != '--:--') {
          _checkOutTime = formatted;
          _isCheckedOut = true;
          notifyListeners();
        }
      }
    });
  }

  bool _isUpacaraCheckedIn = false;
  bool get isUpacaraCheckedIn => _isUpacaraCheckedIn;

  String _upacaraTime = '--:--';
  String get upacaraTime => _upacaraTime;

  bool _isUpacaraCheckInIntent = false;
  bool get isUpacaraCheckInIntent => _isUpacaraCheckInIntent;
  set isUpacaraCheckInIntent(bool val) {
    _isUpacaraCheckInIntent = val;
    notifyListeners();
  }

  LocationValidationStrategy _locationStrategy = PolygonValidationStrategy();
  LocationValidationStrategy get locationStrategy => _locationStrategy;

  bool _useRealNetworkAndGps = true;
  bool get useRealNetworkAndGps => _useRealNetworkAndGps;

  String _simulatedIp = '103.169.23.10';
  String get simulatedIp => _simulatedIp;

  double _simulatedLatitude = -6.600109;
  double get simulatedLatitude => _simulatedLatitude;

  double _simulatedLongitude = 106.814324;
  double get simulatedLongitude => _simulatedLongitude;

  String _realIp = 'Mendeteksi...';
  String get realIp => _realIp;

  String _realIpLocal = '127.0.0.1';
  String get realIpLocal => _realIpLocal;

  double _realLatitude = -6.2088;
  double get realLatitude => _realLatitude;

  double _realLongitude = 106.8456;
  double get realLongitude => _realLongitude;

  bool _isAutoCheckInEvaluating = true;
  bool get isAutoCheckInEvaluating => _isAutoCheckInEvaluating;

  final List<ActivityLogItem> _activities = [];
  List<ActivityLogItem> get activities => _activities;

  final List<AbsenUpacaraData> _ceremonyAttendances = [];
  List<AbsenUpacaraData> get ceremonyAttendances => _ceremonyAttendances;

  bool _isCeremonyLoading = false;
  bool get isCeremonyLoading => _isCeremonyLoading;

  StreamSubscription<Position>? _gpsSubscription;
  Timer? _ipCheckTimer;
  Timer? _gpsTimer;
  bool _isFakeGps = false;
  bool get isFakeGps => _isFakeGps;

  bool _isVpnActive = false;
  bool get isVpnActive => _isVpnActive;

  bool get isVpn => _useRealNetworkAndGps
      ? (LocationWifiHelper.isPakuanIp(_realIp) &&
          !(_realIpLocal.startsWith('10.200.') ||
              _realIpLocal.startsWith('10.201.') ||
              _realIpLocal.startsWith('10.202.') ||
              _realIpLocal.startsWith('10.203.') ||
              _realIpLocal.startsWith('10.204.') ||
              _realIpLocal.startsWith('10.205.')))
      : (LocationWifiHelper.isPakuanIp(_simulatedIp) &&
          !_locationStrategy.isWithinCampus(
              _simulatedLatitude, _simulatedLongitude));

  bool _isLoggedIn = false;
  bool _hasAttemptedAutoCheckIn = false;

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void markCheckedInToday([String? time]) {
    _isCheckedIn = true;
    _hasAttemptedAutoCheckIn = true;
    fetchAttendanceHistory();
  }

  AttendanceBloc() {
    _initRealTimeIpAndGpsTracking();
    AutoAttendanceService.onAttendanceUpdated = () {
      fetchAttendanceHistory();
    };
  }

  Timer? _autoCheckInRetryTimer;

  void _scheduleNextMinuteAutoCheckInRetry() {
    _autoCheckInRetryTimer?.cancel();
    _autoCheckInRetryTimer = Timer(const Duration(minutes: 1), () async {
      if (!_isCheckedIn) {
        debugPrint("[Auto Check-In Retry] Retrying auto check-in evaluation next minute...");
        _isAutoCheckInEvaluating = true;
        _hasAttemptedAutoCheckIn = false;
        notifyListeners();
        final success = await evaluateAndTriggerAutoCheckIn();
        if (!success && !_isCheckedIn) {
          _scheduleNextMinuteAutoCheckInRetry();
        }
      }
    });
  }

  void updateLoginState(bool loggedIn) {
    _isLoggedIn = loggedIn;
    if (loggedIn) {
      fetchAttendanceHistory().then((_) {
        if (!_isCheckedIn) {
          _isAutoCheckInEvaluating = true;
          notifyListeners();
          evaluateAndTriggerAutoCheckIn().then((success) {
            if (!success && !_isCheckedIn) {
              _scheduleNextMinuteAutoCheckInRetry();
            }
          });
        }
      });
    } else {
      _hasAttemptedAutoCheckIn = false;
      _isAutoCheckInEvaluating = true;
      notifyListeners();
      _scheduleNextMinuteAutoCheckInRetry();
    }
  }

  Future<void> refreshAttendanceState() async {
    _isAutoCheckInEvaluating = true;
    _hasAttemptedAutoCheckIn = false;
    notifyListeners();

    final session = await SsoHelper.getSession();
    if (session != null) {
      final nip = session['nip'] as String? ?? '';
      final role = session['role'] as String? ?? '';
      final nidn = role == 'Dosen' ? nip : '';
      if (nip.isNotEmpty || nidn.isNotEmpty) {
        AttendanceRealtimeService().forceReconnect(nip, nidn);
      }
    }
    await fetchAttendanceHistory();
    if (!_isCheckedIn) {
      final success = await evaluateAndTriggerAutoCheckIn();
      if (!success && !_isCheckedIn) {
        _scheduleNextMinuteAutoCheckInRetry();
      }
    }
  }

  Future<void> fetchAttendanceHistory() async {
    try {
      final session = await SsoHelper.getSession();
      if (session == null) return;

      final nip = session['nip'] as String? ?? '';
      var nidn = session['nidn'] as String? ?? '';
      if (nidn.isEmpty) {
        nidn = session['sid'] as String? ??
            (session['role'] == 'Dosen' ? nip : '');
      }
      if (nip.isNotEmpty || nidn.isNotEmpty) {
        initRealtimeWsListener(nip, nidn);
      }

      final history = await _mediator.send(GetAttendanceHistoryQuery());
      _activities.clear();
      _activities.addAll(history.activities);

      if (history.todayCheckInTime != null) {
        _checkInTime = history.todayCheckInTime!;
        _isCheckedIn = true;
        _hasAttemptedAutoCheckIn = true;
      } else {
        _checkInTime = '--:--';
        _isCheckedIn = false;
      }

      if (history.todayCheckOutTime != null) {
        _checkOutTime = history.todayCheckOutTime!;
        _isCheckedOut = true;
      } else {
        _checkOutTime = '--:--';
        _isCheckedOut = false;
      }

      notifyListeners();
      await fetchCeremonyAttendances();
    } catch (e, stackTrace) {
      debugPrint(
          '[AttendanceBloc fetchAttendanceHistory error]: $e\n$stackTrace');
    }
  }

  Future<void> fetchCeremonyAttendances() async {
    _isCeremonyLoading = true;
    notifyListeners();
    try {
      final responseData = await ApiClient.get(
        Uri.parse("${ApiClient.baseUrl}/api/ceremony-attendance"),
      );

      if (responseData is List) {
        _ceremonyAttendances.clear();
        final now = DateTime.now();
        final String todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        bool upacaraToday = false;
        String upacaraTimeStr = '--:--';

        for (var json in responseData) {
          final record = AbsenUpacaraData.fromJson(json);
          _ceremonyAttendances.add(record);
          final cleanTanggal = record.tanggal.split('T')[0].trim();
          final isTodayRecord = cleanTanggal == todayStr ||
              (record.createdAt.isNotEmpty && record.createdAt.startsWith(todayStr));

          if (isTodayRecord) {
            upacaraToday = true;
            if (record.createdAt.isNotEmpty) {
              try {
                final dt = DateTime.parse(record.createdAt).toLocal();
                upacaraTimeStr =
                    "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              } catch (_) {}
            }
          }
        }
        _isUpacaraCheckedIn = upacaraToday;
        _upacaraTime = upacaraTimeStr;
      }
    } catch (e) {
      debugPrint('[AttendanceBloc fetchCeremonyAttendances error]: $e');
    } finally {
      _isCeremonyLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _ipCheckTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  void setLocationStrategy(LocationValidationStrategy strategy) {
    _locationStrategy = strategy;
    notifyListeners();
    evaluateAndTriggerAutoCheckIn();
  }

  void setSimulationConfig({
    required bool useReal,
    required String ip,
    required double lat,
    required double lon,
  }) {
    _useRealNetworkAndGps = useReal;
    _simulatedIp = ip;
    _simulatedLatitude = lat;
    _simulatedLongitude = lon;
    notifyListeners();
    evaluateAndTriggerAutoCheckIn();
  }

  void resetAttendanceStateForDemo() {
    _isCheckedIn = false;
    _checkInTime = '--:--';
    _isCheckedOut = false;
    _checkOutTime = '--:--';
    _hasAttemptedAutoCheckIn = false;
    notifyListeners();
  }

  void addActivity(String title, String time, bool isSuccess) {
    _activities.insert(
      0,
      ActivityLogItem(
        title: title,
        time: time,
        isSuccess: isSuccess,
      ),
    );
    notifyListeners();
  }

  bool isUpacaraEligible() {
    final now = DateTime.now();
    // if (now.day != 17) return false;

    double lat = _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    double lon = _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;

    bool insidePoly1 = LocationWifiHelper.isPointInPolygon(
        lat, lon, LocationWifiHelper.polygon1);
    bool insidePoly2 = LocationWifiHelper.isPointInPolygon(
        lat, lon, LocationWifiHelper.polygon2);
    bool insidePoly3 = LocationWifiHelper.isPointInPolygon(
        lat, lon, LocationWifiHelper.polygon3);

    bool timeMatch = now.hour >= 8 && now.hour < 9;

    return insidePoly1 || (insidePoly2 && timeMatch && insidePoly3);
  }

  Future<void> doCheckIn(String time) async {
    if (_isCheckedIn) {
      debugPrint(
          '[AttendanceBloc] User is ALREADY checked in today. Skipping duplicate doCheckIn.');
      return;
    }

    final lat = _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    final lon = _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;
    final ip = _useRealNetworkAndGps ? _realIp : _simulatedIp;

    final noteList = <String>[];
    if (isFakeGps) noteList.add("G");
    if (isVpn) noteList.add("V");
    final noteStr = noteList.join(",");

    bool success = false;
    try {
      success = await _mediator.send(
        CheckInCommand(
          latitude: lat,
          longitude: lon,
          ipAddress: ip,
          isUpacara: false,
          note: noteStr,
        ),
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sudah') && errStr.contains('absen')) {
        success = true;
      }
    }

    if (success) {
      _isCheckedIn = true;
      bool isInside = _locationStrategy.isWithinCampus(lat, lon);
      String noteLabel = isInside ? 'Di Dalam Kampus' : 'Di Luar Radius Kampus';

      _activities.insert(
        0,
        ActivityLogItem(
          title: 'Absen Masuk Berhasil ($noteLabel)',
          time: 'Hari ini • $time AM',
          isSuccess: true,
        ),
      );
      notifyListeners();
    }
    await fetchAttendanceHistory();
  }

  Future<void> doCheckOut(String time) async {
    final now = DateTime.now();
    final actualTime = (time.isNotEmpty && time != '--:--')
        ? time
        : "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final lat = _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    final lon = _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;
    final ip = _useRealNetworkAndGps ? _realIp : _simulatedIp;

    bool success = false;
    try {
      success = await _mediator.send(
        CheckOutCommand(latitude: lat, longitude: lon, ipAddress: ip),
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sudah') || errStr.contains('keluar')) {
        success = true;
      }
    }

    if (success) {
      _isCheckedOut = true;
      _checkOutTime = actualTime;

      _activities.insert(
        0,
        ActivityLogItem(
          title: 'Absen Keluar Berhasil',
          time: 'Hari ini • $actualTime PM',
          isSuccess: true,
        ),
      );
      notifyListeners();
    }
    await fetchAttendanceHistory();
  }

  Future<void> doUpacaraCheckIn(String time) async {
    final lat = _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    final lon = _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;
    final ip = _useRealNetworkAndGps ? _realIp : _simulatedIp;

    final noteList = <String>[];
    if (isFakeGps) noteList.add("G");
    if (isVpn) noteList.add("V");
    final noteStr = noteList.join(",");

    final success = await _mediator.send(
      CheckInCommand(
        latitude: lat,
        longitude: lon,
        ipAddress: ip,
        isUpacara: true,
        note: noteStr,
      ),
    );

    if (success) {
      _isUpacaraCheckedIn = true;
      _upacaraTime = time;

      _activities.insert(
        0,
        ActivityLogItem(
          title: 'Presensi Upacara Berhasil',
          time: 'Hari ini • $time AM',
          isSuccess: true,
        ),
      );
      notifyListeners();
      await fetchAttendanceHistory();
    }
  }

  Future<bool> evaluateAndTriggerAutoCheckIn() async {
    _isAutoCheckInEvaluating = true;
    notifyListeners();

    if (!_isLoggedIn) {
      _isAutoCheckInEvaluating = false;
      notifyListeners();
      _scheduleNextMinuteAutoCheckInRetry();
      return false;
    }
    await fetchAttendanceHistory();
    if (_isCheckedIn) {
      _isAutoCheckInEvaluating = false;
      notifyListeners();
      return false;
    }

    String currentIp = _useRealNetworkAndGps ? _realIp : _simulatedIp;
    double currentLat =
        _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    double currentLon =
        _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;

    bool matchesWifi = LocationWifiHelper.isPakuanIp(currentIp);
    bool matchesLocation =
        _locationStrategy.isWithinCampus(currentLat, currentLon);

    if (isUpacaraEligible() && !_isUpacaraCheckedIn) {
      final now = DateTime.now();
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      await doUpacaraCheckIn(timeStr);
      debugPrint("Auto Presensi Upacara Triggered successfully!");
    }

    debugPrint("========== AUTO ATTENDANCE CHECK-IN LOG ==========");
    debugPrint("Active Detected IP Address: $currentIp");
    debugPrint("Rule Wi-Fi Campus: (IP matches '103.169' || '2001:df0:3140')");
    debugPrint("Matches Campus Wi-Fi IP Rule: $matchesWifi");
    debugPrint("Active Detected GPS Location: $currentLat, $currentLon");
    debugPrint("Active Strategy in Use: ${_locationStrategy.name}");
    debugPrint("Matches Campus Location Rule: $matchesLocation");
    debugPrint(
        "Final Automatic Check-in Decision: ${matchesWifi || matchesLocation ? 'SUCCESS (Auto Check-In Eligible)' : 'FAILED (Criteria Not Met)'}");
    debugPrint("==================================================");

    if ((matchesWifi || matchesLocation) &&
        !_isCheckedIn &&
        !_hasAttemptedAutoCheckIn) {
      _hasAttemptedAutoCheckIn = true;
      final now = DateTime.now();
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      await doCheckIn(timeStr);
      _isAutoCheckInEvaluating = false;
      notifyListeners();
      return true;
    }

    _scheduleNextMinuteAutoCheckInRetry();
    _isAutoCheckInEvaluating = false;
    notifyListeners();
    return false;
  }

  void _initRealTimeIpAndGpsTracking() async {
    _ipCheckTimer?.cancel();
    int syncTicks = 0;
    _ipCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        syncTicks++;
        if (!_isCheckedIn && _isLoggedIn && syncTicks % 3 == 0) {
          fetchAttendanceHistory();
        }
        final ip = await LocationWifiHelper.getActiveDeviceIp();
        final localIp = await LocationWifiHelper.getLocalInterfaceIp();
        final vpn = await LocationWifiHelper.checkVpnActive();
        bool changed = false;
        if (ip != _realIp) {
          _realIp = ip;
          if (_useRealNetworkAndGps) {
            _simulatedIp = ip;
          }
          changed = true;
        }
        if (localIp != _realIpLocal) {
          _realIpLocal = localIp;
          changed = true;
        }
        if (vpn != _isVpnActive) {
          _isVpnActive = vpn;
          changed = true;
        }
        if (changed) {
          notifyListeners();
        }
      } catch (_) {}
    });

    try {
      int retryCount = 0;
      String resolvedIp = '127.0.0.1';
      while (retryCount < 3) {
        resolvedIp = await LocationWifiHelper.getPublicIpWithTimeoutFallback();
        if (resolvedIp != '127.0.0.1' &&
            resolvedIp != '10.0.2.16' &&
            resolvedIp != '10.0.2.15') {
          break;
        }
        retryCount++;
        await Future.delayed(const Duration(milliseconds: 800));
      }
      _realIp = resolvedIp;
      if (_useRealNetworkAndGps) {
        _simulatedIp = _realIp;
      }
      _realIpLocal = await LocationWifiHelper.getLocalInterfaceIp();
      _isVpnActive = await LocationWifiHelper.checkVpnActive();
      notifyListeners();
    } catch (_) {}

    _gpsSubscription?.cancel();
    _gpsTimer?.cancel();
    try {
      final pos = await LocationWifiHelper.getCurrentLocation();
      if (pos != null) {
        _realLatitude = pos.latitude;
        _realLongitude = pos.longitude;
        _isFakeGps = await DetectFakeLocation().detectFakeLocation();
        if (_useRealNetworkAndGps) {
          _simulatedLatitude = pos.latitude;
          _simulatedLongitude = pos.longitude;
        }
        notifyListeners();
      }

      if (_isAutoCheckInEvaluating) {
        _isAutoCheckInEvaluating = false;
        notifyListeners();
      }

      void updateLocationState(double newLat, double newLon, bool newFakeGps) {
        bool changed = false;
        if ((newLat - _realLatitude).abs() > 0.00005) {
          _realLatitude = newLat;
          if (_useRealNetworkAndGps) _simulatedLatitude = newLat;
          changed = true;
        }
        if ((newLon - _realLongitude).abs() > 0.00005) {
          _realLongitude = newLon;
          if (_useRealNetworkAndGps) _simulatedLongitude = newLon;
          changed = true;
        }
        if (newFakeGps != _isFakeGps) {
          _isFakeGps = newFakeGps;
          changed = true;
        }
        if (changed) {
          notifyListeners();
        }
      }

      // Periodic timer every 5 seconds (instead of 1s) to check GPS
      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          final p = await LocationWifiHelper.getCurrentLocation();
          if (p != null) {
            final fake = await DetectFakeLocation().detectFakeLocation();
            updateLocationState(p.latitude, p.longitude, fake);
          }
        } catch (_) {}
      });

      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
        ),
      ).listen((Position position) async {
        final fake = await DetectFakeLocation().detectFakeLocation();
        updateLocationState(position.latitude, position.longitude, fake);
      }, onError: (err) {
        debugPrint("Realtime GPS Stream Error: $err");
      });
    } catch (e) {
      debugPrint("Failed to initialize GPS subscription: $e");
      if (_isAutoCheckInEvaluating) {
        _isAutoCheckInEvaluating = false;
        notifyListeners();
      }
    }
  }
}
