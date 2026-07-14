import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/sso_helper.dart';
import '../core/location_wifi_helper.dart';
import 'package:geolocator/geolocator.dart';

class LeaveRequest {
  final String id;
  final String type;
  final String status; // 'Menunggu', 'Disetujui', 'Ditolak'
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
}

class ActivityItem {
  final String title;
  final String time;
  final bool isSuccess; // true for green check, false for pending/warning

  ActivityItem({
    required this.title,
    required this.time,
    required this.isSuccess,
  });
}

class PayrollData {
  final int idpublish;
  final String nip;
  final String noMesin;
  final String nama;
  final String prodi;
  final String status; // e.g. "DOSEN", "PEGAWAI"
  final String jafung;
  final double gajiPokok;
  final double tkeluarga;
  final double tanak;
  final double tpangan;
  final double tstruktural;
  final double tfungsional;
  final double mengajar;
  final double nonregular;
  final double d3regular;
  final double d3nonregular;
  final double pascasarjana;
  final double transpot;
  final double tkhusus;
  final double bpjs;
  final double astekY;
  final double dplkY;
  final double gajikotor;
  final double astekP;
  final double dplkP;
  final double pkoperasi;
  final double pyayasan;
  final double pzakat;
  final double gajibersih;
  final String bulan;
  final String tahun;

  PayrollData({
    required this.idpublish,
    required this.nip,
    required this.noMesin,
    required this.nama,
    required this.prodi,
    required this.status,
    required this.jafung,
    required this.gajiPokok,
    required this.tkeluarga,
    required this.tanak,
    required this.tpangan,
    required this.tstruktural,
    required this.tfungsional,
    required this.mengajar,
    required this.nonregular,
    required this.d3regular,
    required this.d3nonregular,
    required this.pascasarjana,
    required this.transpot,
    required this.tkhusus,
    required this.bpjs,
    required this.astekY,
    required this.dplkY,
    required this.gajikotor,
    required this.astekP,
    required this.dplkP,
    required this.pkoperasi,
    required this.pyayasan,
    required this.pzakat,
    required this.gajibersih,
    required this.bulan,
    required this.tahun,
  });

  factory PayrollData.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PayrollData(
      idpublish: json['idpublish'] ?? 0,
      nip: json['nip'] ?? '',
      noMesin: json['no_mesin'] ?? '',
      nama: json['nama'] ?? '',
      prodi: json['prodi'] ?? '',
      status: json['status'] ?? '',
      jafung: json['jafung'] ?? '',
      gajiPokok: toDouble(json['gaji_pokok']),
      tkeluarga: toDouble(json['tkeluarga']),
      tanak: toDouble(json['tanak']),
      tpangan: toDouble(json['tpangan']),
      tstruktural: toDouble(json['tstruktural']),
      tfungsional: toDouble(json['tfungsional']),
      mengajar: toDouble(json['mengajar']),
      nonregular: toDouble(json['nonregular']),
      d3regular: toDouble(json['D3regular']),
      d3nonregular: toDouble(json['D3nonregular']),
      pascasarjana: toDouble(json['pascasarjana']),
      transpot: toDouble(json['transpot']),
      tkhusus: toDouble(json['tkhusus']),
      bpjs: toDouble(json['bpjs']),
      astekY: toDouble(json['astekY']),
      dplkY: toDouble(json['dplkY']),
      gajikotor: toDouble(json['gajikotor']),
      astekP: toDouble(json['astekP']),
      dplkP: toDouble(json['dplkP']),
      pkoperasi: toDouble(json['pkoperasi']),
      pyayasan: toDouble(json['pyayasan']),
      pzakat: toDouble(json['pzakat']),
      gajibersih: toDouble(json['gajibersih']),
      bulan: json['bulan'] ?? '',
      tahun: json['tahun'] ?? '',
    );
  }

  factory PayrollData.mock(String m, String y) {
    return PayrollData(
      idpublish: 168414,
      nip: "10616049757",
      noMesin: "201606012",
      nama: "Roni Jayawinangun, SE., M. Si.",
      prodi: "ISIB",
      status: "DOSEN",
      jafung: "Lektor Kepala",
      gajiPokok: 2277300,
      tkeluarga: 113865,
      tanak: 0,
      tpangan: 160930,
      tstruktural: 2750000,
      tfungsional: 2000000,
      mengajar: 480000,
      nonregular: 370000,
      d3regular: 0,
      d3nonregular: 0,
      pascasarjana: 0,
      transpot: 550000,
      tkhusus: 500000,
      bpjs: 156042,
      astekY: 330809,
      dplkY: 0,
      gajikotor: 9688946,
      astekP: 156042,
      dplkP: 0,
      pkoperasi: 0,
      pyayasan: 0,
      pzakat: 0,
      gajibersih: 8968032,
      bulan: m,
      tahun: y,
    );
  }
}

class AppState extends ChangeNotifier {
  // Navigation State
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Location Strategy
  LocationValidationStrategy _locationStrategy = PolygonValidationStrategy();
  LocationValidationStrategy get locationStrategy => _locationStrategy;

  void setLocationStrategy(LocationValidationStrategy strategy) {
    _locationStrategy = strategy;
    notifyListeners();
    evaluateAndTriggerAutoCheckIn();
  }

  // Upacara Ceremony State
  bool _isUpacaraCheckedIn = false;
  bool get isUpacaraCheckedIn => _isUpacaraCheckedIn;
  
  String _upacaraTime = "--:--";
  String get upacaraTime => _upacaraTime;

  bool _isUpacaraCheckInIntent = false;
  bool get isUpacaraCheckInIntent => _isUpacaraCheckInIntent;
  set isUpacaraCheckInIntent(bool val) {
    _isUpacaraCheckInIntent = val;
    notifyListeners();
  }

  bool isUpacaraEligible() {
    final now = DateTime.now();
    if (now.day != 17) return false;

    double lat = _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    double lon = _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;

    bool insidePoly1 = LocationWifiHelper.isPointInPolygon(lat, lon, LocationWifiHelper.polygon1);
    bool insidePoly2 = LocationWifiHelper.isPointInPolygon(lat, lon, LocationWifiHelper.polygon2);
    bool insidePoly3 = LocationWifiHelper.isPointInPolygon(lat, lon, LocationWifiHelper.polygon3);

    bool timeMatch = now.hour >= 8 && now.hour < 9; // 08:00 to 09:00

    return insidePoly1 || (insidePoly2 && timeMatch && insidePoly3);
  }

  void doUpacaraCheckIn(String time) {
    _isUpacaraCheckedIn = true;
    _upacaraTime = time;

    _activities.insert(
      0,
      ActivityItem(
        title: "Presensi Upacara Berhasil",
        time: "Hari ini • $time AM",
        isSuccess: true,
      ),
    );
    notifyListeners();
  }

  // Authentication State
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String _loggedInUser = "Aditama";

  String get loggedInUser => _loggedInUser;

  bool login(String username, String password) {
    _isLoggedIn = true;
    _loggedInUser = username.isNotEmpty && !username.contains('@')
        ? username
        : (username.contains('@') ? username.split('@')[0] : "Aditama");
    if (_loggedInUser.isNotEmpty) {
      _loggedInUser =
          _loggedInUser[0].toUpperCase() + _loggedInUser.substring(1);
    }
    _isAutoCheckInEvaluating = true;
    _initRealTimeIpAndGpsTracking();

    notifyListeners();
    startTokenRefreshTimer();
    SsoHelper.printSsoTelemetry();

    return true;
  }

  void logout() async {
    _tokenRefreshTimer?.cancel();
    _isLoggedIn = false;
    _currentTabIndex = 0;
    _isCheckedIn = false;
    _isUpacaraCheckedIn = false;
    _checkInTime = "--:--";
    _checkOutTime = "--:--";
    _upacaraTime = "--:--";
    _isAutoCheckInEvaluating = true;
    notifyListeners();

    try {
      await SsoHelper.logout();
    } catch (e) {
      debugPrint("SSO Logout error: $e");
    }
  }

  Timer? _tokenRefreshTimer;

  void startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_isLoggedIn) {
        debugPrint("Background auto-checking token validity...");
        final token = await SsoHelper.getValidToken();
        if (token == null) {
          debugPrint(
              "Token expired and refresh failed. Automatically logging out.");
          logout();
        }
      } else {
        _tokenRefreshTimer?.cancel();
      }
    });
  }

  // Real-time IP and GPS properties
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _ipCheckTimer;

  String _realIp = "Mendeteksi...";
  double _realLatitude = -6.2088;
  double _realLongitude = 106.8456;

  bool _isAutoCheckInEvaluating = true;

  String get realIp => _realIp;
  double get realLatitude => _realLatitude;
  double get realLongitude => _realLongitude;
  bool get isAutoCheckInEvaluating => _isAutoCheckInEvaluating;

  // Constructor
  AppState() {
    _initRealTimeIpAndGpsTracking();
  }

  void _initRealTimeIpAndGpsTracking() async {
    // 1. Periodic IP checking stream (every 5 seconds)
    _ipCheckTimer?.cancel();
    _ipCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final ip = await LocationWifiHelper.getActiveDeviceIp();
        if (ip != _realIp) {
          _realIp = ip;
          if (_useRealNetworkAndGps) {
            _simulatedIp = ip;
          }
          notifyListeners();
          evaluateAndTriggerAutoCheckIn();
        }
      } catch (_) {}
    });

    // 2. Await public IP resolution on startup with retries (helps emulator NAT/lags)
    try {
      int retryCount = 0;
      String resolvedIp = "127.0.0.1";
      while (retryCount < 3) {
        resolvedIp = await LocationWifiHelper.getPublicIpWithTimeoutFallback();
        // If we successfully resolved a real public IP (not loopback and not emulator NAT IP), break!
        if (resolvedIp != "127.0.0.1" &&
            resolvedIp != "10.0.2.16" &&
            resolvedIp != "10.0.2.15") {
          break;
        }
        retryCount++;
        await Future.delayed(const Duration(milliseconds: 800));
      }

      _realIp = resolvedIp;
      if (_useRealNetworkAndGps) {
        _simulatedIp = _realIp;
      }
      notifyListeners();
      evaluateAndTriggerAutoCheckIn();
    } catch (_) {}

    // 3. Real-time GPS stream listener
    _gpsSubscription?.cancel();
    try {
      // Prompt GPS permission first if needed
      final pos = await LocationWifiHelper.getCurrentLocation();
      if (pos != null) {
        _realLatitude = pos.latitude;
        _realLongitude = pos.longitude;
        if (_useRealNetworkAndGps) {
          _simulatedLatitude = pos.latitude;
          _simulatedLongitude = pos.longitude;
        }
        notifyListeners();
        evaluateAndTriggerAutoCheckIn();
      }

      // Mark first initialization pass as complete
      _isAutoCheckInEvaluating = false;
      notifyListeners();

      // Stream subscription for moving positions
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // Update coordinates every 3 meters of movement
        ),
      ).listen((Position position) {
        _realLatitude = position.latitude;
        _realLongitude = position.longitude;

        if (_useRealNetworkAndGps) {
          _simulatedIp = _realIp;
          _simulatedLatitude = position.latitude;
          _simulatedLongitude = position.longitude;
        }

        notifyListeners();
        evaluateAndTriggerAutoCheckIn();
      }, onError: (err) {
        debugPrint("Realtime GPS Stream Error: $err");
      });
    } catch (e) {
      debugPrint("Failed to initialize GPS subscription: $e");
      _isAutoCheckInEvaluating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _ipCheckTimer?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  // Location & Wi-Fi Simulation configuration for Pakuan University Auto-CheckIn
  bool _useRealNetworkAndGps = true;
  bool get useRealNetworkAndGps => _useRealNetworkAndGps;

  String _simulatedIp = "103.169.23.10"; // Default to Pakuan range IP
  String get simulatedIp => _simulatedIp;

  double _simulatedLatitude = -6.600109; // Universitas Pakuan Latitude
  double get simulatedLatitude => _simulatedLatitude;

  double _simulatedLongitude = 106.814324; // Universitas Pakuan Longitude
  double get simulatedLongitude => _simulatedLongitude;

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
    evaluateAndTriggerAutoCheckIn(); // Re-evaluate on config updates
  }

  void resetAttendanceStateForDemo() {
    _isCheckedIn = false;
    _checkInTime = "--:--";
    _checkOutTime = "--:--";
    notifyListeners();
  }

  Future<bool> evaluateAndTriggerAutoCheckIn() async {
    if (!_isLoggedIn) return false;

    // Use real active values if useRealNetworkAndGps is true, or falls back to simulated settings
    String currentIp = _useRealNetworkAndGps ? _realIp : _simulatedIp;
    double currentLat =
        _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    double currentLon =
        _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;

    // 1. Wi-Fi constraint rule: IP contains "103.169" or "2001:df0:3140"
    bool matchesWifi = LocationWifiHelper.isPakuanIp(currentIp);

    // 2. Location validation via Strategy (Polygon default, Radius alternate)
    bool matchesLocation = _locationStrategy.isWithinCampus(currentLat, currentLon);

    // 3. Upacara Ceremony check-in evaluation
    if (isUpacaraEligible() && !_isUpacaraCheckedIn) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      doUpacaraCheckIn(timeStr);
      debugPrint("Auto Presensi Upacara Triggered successfully!");
    }

    // SSO and Auto Attendance evaluation logs to console
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

    // Auto submit standard check-in if eligible and not already checked in
    if ((matchesWifi || matchesLocation) && !_isCheckedIn) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      doCheckIn(timeStr);
      return true;
    }
    return false;
  }

  // Attendance State
  bool _isCheckedIn = false;
  bool get isCheckedIn => _isCheckedIn;

  String _checkInTime = "--:--";
  String get checkInTime => _checkInTime;

  String _checkOutTime = "--:--";
  String get checkOutTime => _checkOutTime;

  void doCheckIn(String time) {
    _isCheckedIn = true;
    _checkInTime = time;

    double lat = _useRealNetworkAndGps ? _realLatitude : _simulatedLatitude;
    double lon = _useRealNetworkAndGps ? _realLongitude : _simulatedLongitude;
    
    // Check inside campus status via strategy
    bool isInside = _locationStrategy.isWithinCampus(lat, lon);
    String noteLabel = isInside ? "Di Dalam Kampus" : "Di Luar Radius Kampus";

    // Add to recent activities
    _activities.insert(
        0,
        ActivityItem(
          title: "Absen Masuk Berhasil ($noteLabel)",
          time: "Hari ini • $time AM",
          isSuccess: true,
        ));

    notifyListeners();
  }

  void doCheckOut(String time) {
    _checkOutTime = time;

    _activities.insert(
        0,
        ActivityItem(
          title: "Absen Pulang Berhasil",
          time: "Hari ini • $time PM",
          isSuccess: true,
        ));

    notifyListeners();
  }

  // Calendar State
  DateTime _selectedCalendarDay = DateTime(2023, 10, 9);
  DateTime get selectedCalendarDay => _selectedCalendarDay;

  void selectCalendarDay(DateTime date) {
    _selectedCalendarDay = date;
    notifyListeners();
  }

  // Leave / Request State
  int _sisaCuti = 12;
  int get sisaCuti => _sisaCuti;

  int _cutiDiambil = 4;
  int get cutiDiambil => _cutiDiambil;

  int _cutiPending = 1;
  int get cutiPending => _cutiPending;

  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      id: "req_1",
      type: "Perjalanan Dinas (SPPD)",
      status: "Pengajuan",
      dateRange: "15 - 18 Okt 2026",
      details: "Dinas Ke Jakarta - Singapore",
      note: "Menunggu verifikasi: Sobar Sukmana, MH.",
      startDate: DateTime(2026, 10, 15),
      endDate: DateTime(2026, 10, 18),
    ),
    LeaveRequest(
      id: "req_2",
      type: "Izin Sakit",
      status: "Di ACC Atasan",
      dateRange: "12 Okt 2026",
      details: "Sakit Demam Tinggi",
      note: "Disetujui oleh Firdanianty, Dr., M.Pd",
      startDate: DateTime(2026, 10, 12),
      endDate: DateTime(2026, 10, 12),
    ),
  ];

  final List<LeaveRequest> _historyRequests = [
    LeaveRequest(
      id: "hist_1",
      type: "Cuti Tahunan",
      status: "ACC SDM",
      dateRange: "5 - 7 Sep 2026",
      details: "Acara Keluarga Tahunan",
      note: "Disetujui oleh Rektorat & SDM",
      startDate: DateTime(2026, 9, 5),
      endDate: DateTime(2026, 9, 7),
    ),
    LeaveRequest(
      id: "hist_2",
      type: "Izin Dinas Luar Kantor",
      status: "Tolak Atasan",
      dateRange: "28 Agu 2026",
      details: "Rapat Koordinasi Asosiasi",
      note: "Ditolak Atasan: Bentrok Jadwal Mengajar",
      startDate: DateTime(2026, 8, 28),
      endDate: DateTime(2026, 8, 28),
    ),
    LeaveRequest(
      id: "hist_3",
      type: "Cuti Melahirkan",
      status: "Tolak SDM",
      dateRange: "1 - 14 Jul 2026",
      details: "Cuti Bersalin Melahirkan Anak Kedua",
      note: "Ditolak SDM: Melebihi Kuota Cuti Tersedia",
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 14),
    ),
  ];

  List<LeaveRequest> get activeRequests => _leaveRequests;
  List<LeaveRequest> get historyRequests => _historyRequests;

  void addLeaveRequest(
      String type, DateTime start, DateTime end, String reason, {String? customNote, int? customDays}) {
    final rangeStr = start.day == end.day
        ? "${start.day} ${_getMonthNameShort(start.month)}"
        : "${start.day} - ${end.day} ${_getMonthNameShort(start.month)}";

    final newReq = LeaveRequest(
      id: "req_${DateTime.now().millisecondsSinceEpoch}",
      type: type,
      status: "Menunggu",
      dateRange: rangeStr,
      details: reason,
      note: customNote ?? (type == "Cuti Tahunan"
          ? "Review oleh HR Admin"
          : "Menunggu persetujuan Manager"),
      startDate: start,
      endDate: end,
    );

    _leaveRequests.insert(0, newReq);

    final days = customDays ?? (end.difference(start).inDays + 1);
    if (type.contains("Tahunan")) {
      _sisaCuti = _sisaCuti - days;
      if (_sisaCuti < 0) _sisaCuti = 0;
      _cutiDiambil += days;
    } else {
      _cutiPending += 1;
    }

    // Add to recent activities
    _activities.insert(
        0,
        ActivityItem(
          title: "Pengajuan $type Berhasil",
          time: "Hari ini • Menunggu Persetujuan",
          isSuccess: false,
        ));

    notifyListeners();
  }

  String _getMonthNameShort(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    return months[month - 1];
  }

  // Activities State
  final List<ActivityItem> _activities = [
    ActivityItem(
      title: "Pengajuan Cuti Tahunan",
      time: "Kemarin • Menunggu Persetujuan",
      isSuccess: false,
    ),
  ];
  List<ActivityItem> get activities => _activities;

  // Dashboard Summary Metrics
  int get totalAbsen {
    // Count baseline check-ins + 1 if checked in today
    return 18 + (_isCheckedIn ? 1 : 0);
  }

  int get totalIzin {
    // Count number of approved Cuti/Izin requests from leave history
    int count = 0;
    for (var req in [..._leaveRequests, ..._historyRequests]) {
      if (req.status == 'ACC SDM' || req.status == 'Di ACC Atasan') {
        if (req.type.contains('Izin') || req.type.contains('Cuti') || req.type.contains('SPPD')) {
          final days = req.endDate.difference(req.startDate).inDays + 1;
          count += days;
        }
      }
    }
    return count > 0 ? count : 4; // Baseline of 4 days if empty
  }

  int get totalTidakMasuk {
    // Return standard mock count of 1 day missed
    return 1;
  }

  // Payroll State
  String _selectedPayrollMonth = "Jun";
  String get selectedPayrollMonth => _selectedPayrollMonth;

  String _selectedPayrollYear = "2026";
  String get selectedPayrollYear => _selectedPayrollYear;

  bool _isLoadingPayroll = false;
  bool get isLoadingPayroll => _isLoadingPayroll;

  final Map<String, PayrollData?> _payrollDatabase = {
    "Jan-2026": PayrollData.mock("Januari", "2026"),
    "Feb-2026": PayrollData.mock("Februari", "2026"),
    "Mar-2026": PayrollData.mock("Maret", "2026"),
    "Apr-2026": PayrollData.mock("April", "2026"),
    "Mei-2026": PayrollData.mock("Mei", "2026"),
    "Jun-2026": PayrollData.mock("Juni", "2026"),
  };

  PayrollData? get currentPayrollData {
    final key = "$_selectedPayrollMonth-$_selectedPayrollYear";
    return _payrollDatabase[key];
  }

  void setSelectedPayrollMonth(String month) {
    _selectedPayrollMonth = month;
    notifyListeners();
    fetchPayrollDataFromApi();
  }

  void setSelectedPayrollYear(String year) {
    _selectedPayrollYear = year;
    notifyListeners();
    fetchPayrollDataFromApi();
  }

  Future<void> fetchPayrollDataFromApi() async {
    _isLoadingPayroll = true;
    notifyListeners();

    final Map<String, String> monthMap = {
      "Jan": "01",
      "Feb": "02",
      "Mar": "03",
      "Apr": "04",
      "Mei": "05",
      "Jun": "06",
      "Jul": "07",
      "Agu": "08",
      "Sep": "09",
      "Okt": "10",
      "Nov": "11",
      "Des": "12",
    };

    final numericMonth = monthMap[_selectedPayrollMonth] ?? "06";
    final targetNip = _loggedInUser.isNotEmpty && RegExp(r'^\d+$').hasMatch(_loggedInUser)
        ? _loggedInUser
        : "10616049757";

    final key = "$_selectedPayrollMonth-$_selectedPayrollYear";

    try {
      final response = await http.post(
        Uri.parse("https://hrportal.unpak.ac.id/api/slip_gaji"),
        body: {
          "nip": targetNip,
          "tahun": _selectedPayrollYear,
          "bulan": numericMonth,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'ok' && responseData['data'] != null) {
          _payrollDatabase[key] = PayrollData.fromJson(responseData['data']);
        } else {
          _payrollDatabase[key] = null;
        }
      } else {
        _payrollDatabase[key] = null;
      }
    } catch (e) {
      debugPrint("Error fetching payroll data: $e");
      if (!_payrollDatabase.containsKey(key)) {
        _payrollDatabase[key] = null;
      }
    } finally {
      _isLoadingPayroll = false;
      notifyListeners();
    }
  }
}
