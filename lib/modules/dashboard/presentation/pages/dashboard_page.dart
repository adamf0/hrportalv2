import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'package:hrportalv2/core/app_theme.dart';
import '../../../auth/presentation/components/pages/login_page.dart';
import '../../../auth/presentation/auth_bloc.dart';
import '../../../attendance/presentation/attendance_bloc.dart';
import '../../../leave/presentation/leave_bloc.dart';
import '../../../../core/location_wifi_helper.dart';
import '../../../leave/presentation/components/pages/leave_form_page.dart';
import '../../../report/presentation/report_bloc.dart';

// Atomic Design Components
import 'package:hrportalv2/core/presentation/components/molecules/quick_menu_button.dart';
import 'package:hrportalv2/core/presentation/components/atoms/pulsing_skeleton.dart';
// Dashboard Specific Components
import 'package:hrportalv2/modules/dashboard/presentation/components/molecules/dashboard_header.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/molecules/greeting_banner.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/attendance_time_cards.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/flag_ceremony_card.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/auto_check_in_status_card.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/dashboard_calendar_card.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/attendance_stats_section.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/leave_summary_section.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/questionnaire_section.dart';
import 'package:hrportalv2/modules/dashboard/presentation/components/organisms/quick_menu_section.dart';

class CalendarItem {
  final String nidn;
  final String nip;
  final String tanggal;
  final String type;
  final String catatan;
  final String status;

  CalendarItem({
    required this.nidn,
    required this.nip,
    required this.tanggal,
    required this.type,
    required this.catatan,
    required this.status,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      nidn: json['nidn'] ?? '',
      nip: json['nip'] ?? '',
      tanggal: json['tanggal'] ?? '',
      type: json['type'] ?? '',
      catatan: json['catatan'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _selectedCalendarDay = DateTime.now();
  final Map<String, List<CalendarItem>> _calendarEvents = {};

  bool _calendarLoading = true;
  bool _calendarError = false;

  int _totalAbsen1To31 = 0;
  int _totalIzin1To31 = 0;
  int _totalSppd1To31 = 0;
  int _tidakMasuk1To31 = 0;
  int _totalUpacara1To31 = 0;

  int _totalAbsen15To15 = 0;
  int _totalIzin15To15 = 0;
  int _totalSppd15To15 = 0;
  int _tidakMasuk15To15 = 0;
  int _totalUpacara15To15 = 0;

  CalendarItem? _getPriorityEvent(String key) {
    final list = _calendarEvents[key];
    if (list == null || list.isEmpty) return null;

    // 1. Absen has the highest priority
    for (var ev in list) {
      if (ev.type.toLowerCase() == "absen") return ev;
    }

    // 2. Approved events have the second highest priority (disetujui/acc/terima sdm)
    for (var ev in list) {
      final statusLower = ev.status.toLowerCase();
      if (statusLower == "acc" ||
          statusLower == "disetujui" ||
          statusLower == "terima sdm") {
        return ev;
      }
    }

    // 3. Otherwise return the first event (e.g. pending ones)
    return list.first;
  }

  int? _previousTabIndex;

  @override
  void initState() {
    super.initState();
    ApiClient.setActivePageScope('dashboard');
    _calendarLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.isSdmUser) {
        _calendarLoading = false;
        context.read<ReportBloc>().fetchReportData();
        return;
      }
      _fetchCalendarEvents();
      _initDashboardDependencies();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final attendanceBloc = Provider.of<AttendanceBloc>(context);
    final currentIndex = attendanceBloc.currentTabIndex;
    if (_previousTabIndex != null &&
        _previousTabIndex != 0 &&
        currentIndex == 0) {
      ApiClient.setActivePageScope('dashboard');
      final authBloc = context.read<AuthBloc>();
      if (authBloc.isSdmUser) {
        context.read<ReportBloc>().fetchReportData();
        _previousTabIndex = currentIndex;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchCalendarEvents();
        context.read<LeaveBloc>().fetchLeaves();
      });
    }
    _previousTabIndex = currentIndex;
  }

  Future<void> _initDashboardDependencies() async {
    await LocationWifiHelper.getCurrentLocation();
    if (!mounted) return;
    final authBloc = context.read<AuthBloc>();
    final attendanceBloc = context.read<AttendanceBloc>();
    attendanceBloc.updateLoginState(authBloc.isLoggedIn);
    await context.read<LeaveBloc>().fetchLeaves();
  }

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  Future<void> _fetchCalendarEvents() async {
    if (!mounted) return;
    if (!_calendarLoading) {
      setState(() {
        _calendarLoading = true;
        _calendarError = false;
      });
    }

    final authBloc = context.read<AuthBloc>();
    final nip = authBloc.session?.nip ?? '';
    if (nip.isEmpty) {
      if (mounted) {
        setState(() {
          _calendarLoading = false;
        });
      }
      return;
    }

    try {
      final firstDay =
          DateTime(_selectedCalendarDay.year, _selectedCalendarDay.month, 1);
      final prefixDays = firstDay.weekday % 7;
      final gridStart = firstDay.subtract(Duration(days: prefixDays));
      final gridEnd = gridStart.add(const Duration(days: 42));

      final startStr =
          "${gridStart.year}-${_twoDigits(gridStart.month)}-${_twoDigits(gridStart.day)}";
      final endStr =
          "${gridEnd.year}-${_twoDigits(gridEnd.month)}-${_twoDigits(gridEnd.day)}";

      final yearMonthStr =
          "${_selectedCalendarDay.year}-${_twoDigits(_selectedCalendarDay.month)}";

      // Execute all 4 requests in parallel!
      final results = await Future.wait([
        ApiClient.get(Uri.parse(
            "${ApiClient.baseUrl}/api/calendar?start_date=$startStr&end_date=$endStr")),
        ApiClient.get(Uri.parse(
            "${ApiClient.baseUrl}/api/holiday?year=${_selectedCalendarDay.year}")),
        ApiClient.get(Uri.parse(
            "${ApiClient.baseUrl}/api/laporan/summary?periode_type=CALENDAR&periode_key=$yearMonthStr")),
        ApiClient.get(Uri.parse(
            "${ApiClient.baseUrl}/api/laporan/summary?periode_type=CALENDAR-CUTOFF&periode_key=$yearMonthStr")),
      ]);

      final responseData = results[0];
      final holidayData = results[1];
      final summaryCalendar = results[2];
      final summaryCutoff = results[3];

      _calendarEvents.clear();

      // Parse calendar events
      if (responseData is List) {
        for (var item in responseData) {
          if (item is Map<String, dynamic>) {
            final tanggal = item['tanggal'] as String? ?? '';
            if (tanggal.isNotEmpty) {
              final cleanKey = tanggal.split('T')[0];
              _calendarEvents
                  .putIfAbsent(cleanKey, () => [])
                  .add(CalendarItem.fromJson(item));
            }
          }
        }
      }

      // Parse holidays
      if (holidayData is List) {
        for (var item in holidayData) {
          if (item is Map<String, dynamic>) {
            final tanggal = item['tanggal'] as String? ?? '';
            final nama = item['nama'] as String? ?? '';
            final isLibur = item['libur'] == 1;

            if (tanggal.isNotEmpty && isLibur) {
              final cleanKey = tanggal.split('T')[0];
              final calItem = CalendarItem(
                nidn: '',
                nip: '',
                tanggal: tanggal,
                type: 'holiday',
                catatan: nama,
                status: 'Libur',
              );
              _calendarEvents.putIfAbsent(cleanKey, () => []).add(calItem);
            }
          }
        }
      }

      // Parse CALENDAR summary (1-31)
      if (summaryCalendar is Map<String, dynamic>) {
        _totalAbsen1To31 = summaryCalendar['total_masuk'] ?? 0;
        _totalIzin1To31 = (summaryCalendar['total_izin'] ?? 0) +
            (summaryCalendar['total_cuti'] ?? 0);
        _totalSppd1To31 = summaryCalendar['total_sppd'] ?? 0;
        _totalUpacara1To31 = summaryCalendar['total_upacara'] ?? 0;

        final start =
            DateTime(_selectedCalendarDay.year, _selectedCalendarDay.month, 1);
        final end = DateTime(
            _selectedCalendarDay.year, _selectedCalendarDay.month + 1, 0);
        final totalLibur = summaryCalendar['total_libur'] ?? 0;
        _tidakMasuk1To31 = _calculateTidakMasukFromDB(_totalAbsen1To31,
            _totalIzin1To31, _totalSppd1To31, totalLibur, start, end);
      }

      // Parse CALENDAR-CUTOFF summary (15-15)
      if (summaryCutoff is Map<String, dynamic>) {
        _totalAbsen15To15 = summaryCutoff['total_masuk'] ?? 0;
        _totalIzin15To15 = (summaryCutoff['total_izin'] ?? 0) +
            (summaryCutoff['total_cuti'] ?? 0);
        _totalSppd15To15 = summaryCutoff['total_sppd'] ?? 0;
        _totalUpacara15To15 = summaryCutoff['total_upacara'] ?? 0;

        final start = DateTime(
            _selectedCalendarDay.year, _selectedCalendarDay.month - 1, 16);
        final end =
            DateTime(_selectedCalendarDay.year, _selectedCalendarDay.month, 15);
        final totalLibur = summaryCutoff['total_libur'] ?? 0;
        _tidakMasuk15To15 = _calculateTidakMasukFromDB(_totalAbsen15To15,
            _totalIzin15To15, _totalSppd15To15, totalLibur, start, end);
      }
    } catch (e) {
      debugPrint("Error fetching calendar events: $e");
      if (mounted) {
        setState(() {
          _calendarError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _calendarLoading = false;
        });
      }
    }
  }

  int _calculateTidakMasukFromDB(int totalAbsen, int totalIzin, int totalSppd,
      int totalLibur, DateTime start, DateTime end) {
    int totalDays = 0;
    int sundays = 0;
    DateTime cur = start;
    final today = DateTime.now();
    final limit = end.isAfter(today) ? today : end;
    while (cur.isBefore(limit) || DateUtils.isSameDay(cur, limit)) {
      totalDays++;
      if (cur.weekday == DateTime.sunday) {
        sundays++;
      }
      cur = cur.add(const Duration(days: 1));
    }
    final missing =
        totalDays - totalAbsen - totalIzin - totalSppd - sundays - totalLibur;
    return missing > 0 ? missing : 0;
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);
    final attendanceBloc = Provider.of<AttendanceBloc>(context);
    final leaveBloc = Provider.of<LeaveBloc>(context);

    final background = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              attendanceBloc.fetchAttendanceHistory(),
              leaveBloc.fetchLeaves(),
              _fetchCalendarEvents(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardHeader(
                  userName: authBloc.session?.name ?? "User",
                  onLogoutTap: () => _showLogoutConfirmDialog(
                      context, authBloc, attendanceBloc),
                  onNotificationTap: () {},
                ),
                const SizedBox(height: 24),
                GreetingBanner(
                  isCheckedIn: attendanceBloc.isCheckedIn,
                ),
                const SizedBox(height: 20),
                AttendanceTimeCards(
                  isLoading: _calendarLoading,
                  isCheckedIn: attendanceBloc.isCheckedIn,
                  checkInTime: attendanceBloc.checkInTime,
                  checkOutTime: attendanceBloc.checkOutTime,
                  onJamMasukTap: () {
                    if (!attendanceBloc.isCheckedIn) {
                      attendanceBloc.setTabIndex(1);
                    }
                  },
                  onJamPulangTap: () {
                    if (attendanceBloc.isCheckedIn &&
                        attendanceBloc.checkOutTime == "--:--") {
                      _simulateCheckOut(context, attendanceBloc);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final isButtonEnabled = now.day == 17 && now.hour == 8;
                    return FlagCeremonyCard(
                      isUpacaraCheckedIn: attendanceBloc.isUpacaraCheckedIn,
                      upacaraTime: attendanceBloc.upacaraTime,
                      isButtonEnabled: isButtonEnabled,
                      onVerifyTap: () {
                        attendanceBloc.isUpacaraCheckInIntent = true;
                        attendanceBloc.setTabIndex(1);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                AutoCheckInStatusCard(
                  isCheckedIn: attendanceBloc.isCheckedIn,
                  isAutoCheckInEvaluating:
                      attendanceBloc.isAutoCheckInEvaluating,
                  realIp: attendanceBloc.realIp,
                  realLatitude: attendanceBloc.realLatitude,
                  realLongitude: attendanceBloc.realLongitude,
                  onManualCheckInTap: () => attendanceBloc.setTabIndex(1),
                ),
                const SizedBox(height: 24),
                const QuestionnaireSection(),
                const SizedBox(height: 24),
                if (_calendarLoading)
                  _buildCalendarShimmer(context)
                else if (_calendarError)
                  _buildCalendarError(context)
                else
                  DashboardCalendarCard(
                    selectedCalendarDay: _selectedCalendarDay,
                    onDaySelected: (day) {
                      final oldMonth = _selectedCalendarDay.month;
                      final oldYear = _selectedCalendarDay.year;
                      setState(() {
                        _selectedCalendarDay = day;
                      });
                      if (day.month != oldMonth || day.year != oldYear) {
                        _fetchCalendarEvents();
                      }
                    },
                    getDayStatusColor: (day) =>
                        _getCalendarDayStatusColor(day, attendanceBloc),
                    getDayTextColor: (day, isFaded, isRed, isSelected) {
                      final key =
                          "${day.year}-${_twoDigits(day.month)}-${_twoDigits(day.day)}";
                      final event = _getPriorityEvent(key);
                      final isHoliday = event != null &&
                          event.type.toLowerCase() == "holiday";

                      Color textColor = Colors.black;
                      if (isFaded) {
                        textColor = Colors.grey[300]!;
                      } else if (isRed || isHoliday) {
                        textColor = Colors.red[600]!;
                      }
                      if (isSelected) {
                        textColor = Theme.of(context).colorScheme.primary;
                      }
                      return textColor;
                    },
                    buildDayIndicatorDot: (day, isFaded) =>
                        _buildDayIndicatorDot(day, isFaded),
                    dayStatus: _getCalendarDayStatus(
                        _selectedCalendarDay, attendanceBloc),
                    dayTimes: _getCalendarDayTimes(
                        _selectedCalendarDay, attendanceBloc),
                    statusColor: _getCalendarDayStatusColor(
                        _selectedCalendarDay, attendanceBloc),
                  ),
                const SizedBox(height: 24),
                AttendanceStatsSection(
                  isLoading: _calendarLoading,
                  totalAbsen1To31: _totalAbsen1To31,
                  totalIzin1To31: _totalIzin1To31,
                  totalSppd1To31: _totalSppd1To31,
                  tidakMasuk1To31: _tidakMasuk1To31,
                  totalUpacara1To31: _totalUpacara1To31,
                  totalAbsen15To15: _totalAbsen15To15,
                  totalIzin15To15: _totalIzin15To15,
                  totalSppd15To15: _totalSppd15To15,
                  tidakMasuk15To15: _tidakMasuk15To15,
                  totalUpacara15To15: _totalUpacara15To15,
                ),
                const SizedBox(height: 24),
                LeaveSummarySection(
                  sisaCuti: leaveBloc.sisaCuti,
                  cutiDiambil: leaveBloc.cutiDiambil,
                  cutiPending: leaveBloc.cutiPending,
                  summaries: leaveBloc.cutiTypeSummaries,
                ),
                const SizedBox(height: 24),
                QuickMenuSection(
                  buttons: [
                    QuickMenuButton(
                      icon: Icons.face_retouching_natural,
                      label: 'Absensi',
                      onTap: () => attendanceBloc.setTabIndex(1),
                    ),
                    QuickMenuButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'Cuti',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LeaveFormPage(initialTab: 0),
                        ),
                      ),
                    ),
                    QuickMenuButton(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Izin',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LeaveFormPage(initialTab: 1),
                        ),
                      ),
                    ),
                    QuickMenuButton(
                      icon: Icons.flight_takeoff,
                      label: 'SPPD',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveFormPage(
                            initialTab: 1,
                            initialType: 'Dinas Luar Kantor',
                          ),
                        ),
                      ),
                    ),
                    QuickMenuButton(
                      icon: Icons.payments_outlined,
                      label: 'Slip Gaji',
                      onTap: () => attendanceBloc.setTabIndex(3),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayIndicatorDot(DateTime day, bool isFaded) {
    if (isFaded) return const SizedBox.shrink();

    final key = "${day.year}-${_twoDigits(day.month)}-${_twoDigits(day.day)}";
    final event = _getPriorityEvent(key);

    Color dotColor = Colors.transparent;
    if (event != null) {
      final type = event.type.toLowerCase();
      if (type == "absen") {
        dotColor = AppTheme.success;
      } else if (type == "izin") {
        dotColor = AppTheme.warning;
      } else if (type == "cuti" || type == "leave") {
        dotColor = AppTheme.info;
      } else if (type == "sppd") {
        dotColor = AppTheme.secondary;
      } else if (type == "holiday") {
        dotColor = Colors.red[600]!;
      }
    } else if (DateUtils.isSameDay(DateTime.now(), day) &&
        context.read<AttendanceBloc>().isCheckedIn) {
      dotColor = AppTheme.success;
    }

    if (dotColor == Colors.transparent) return const SizedBox.shrink();

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getCalendarDayStatusColor(DateTime day, AttendanceBloc appState) {
    final key = "${day.year}-${_twoDigits(day.month)}-${_twoDigits(day.day)}";
    final event = _getPriorityEvent(key);

    if (event != null) {
      final type = event.type.toLowerCase();
      if (type == "absen") {
        return AppTheme.success;
      } else if (type == "izin") {
        return AppTheme.warning;
      } else if (type == "cuti" || type == "leave") {
        return AppTheme.info;
      } else if (type == "sppd") {
        return AppTheme.secondary;
      } else if (type == "holiday") {
        return Colors.red[600]!;
      }
    }

    if (DateUtils.isSameDay(DateTime.now(), day)) {
      return appState.isCheckedIn ? AppTheme.success : Colors.grey[400]!;
    }

    if (day.weekday == DateTime.sunday) {
      return AppTheme.error;
    }

    return Colors.grey;
  }

  String _getCalendarDayStatus(DateTime day, AttendanceBloc appState) {
    final key = "${day.year}-${_twoDigits(day.month)}-${_twoDigits(day.day)}";
    final event = _getPriorityEvent(key);

    if (event != null) {
      final type = event.type.toLowerCase();
      if (type == "absen") {
        return event.catatan.isNotEmpty ? event.catatan : 'Hadir Tepat Waktu';
      } else if (type == "izin") {
        return 'Izin Sakit (${event.status})';
      } else if (type == "cuti" || type == "leave") {
        return 'Cuti Tahunan (${event.status})';
      } else if (type == "sppd") {
        return 'Dinas Luar SPPD (${event.status})';
      } else if (type == "holiday") {
        return '${event.catatan} (Hari Libur)';
      }
    }

    if (DateUtils.isSameDay(DateTime.now(), day)) {
      return appState.isCheckedIn ? 'Hadir Tepat Waktu' : 'Belum Absen';
    }

    if (day.weekday == DateTime.sunday) {
      return 'Libur Akhir Pekan';
    }

    return 'Belum Ada Data';
  }

  String _getCalendarDayTimes(DateTime day, AttendanceBloc appState) {
    final key = "${day.year}-${_twoDigits(day.month)}-${_twoDigits(day.day)}";
    final event = _getPriorityEvent(key);

    if (event != null) {
      if (event.type.toLowerCase() == "absen" &&
          event.catatan.contains("Masuk")) {
        return event.catatan;
      }
      return event.catatan.isNotEmpty ? event.catatan : 'Aktivitas Tercatat';
    }

    if (DateUtils.isSameDay(DateTime.now(), day)) {
      return 'Masuk: ${appState.checkInTime} • Pulang: ${appState.checkOutTime}';
    }

    return 'Hari Istirahat / Tidak Ada Riwayat';
  }

  void _simulateCheckOut(BuildContext context, AttendanceBloc appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin melakukan absen pulang sekarang?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await appState.doCheckOut("17:05");
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Absen pulang berhasil dilakukan!')),
              );
            },
            child: Text('Absen Pulang',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(
      BuildContext context, AuthBloc authBloc, AttendanceBloc attendanceBloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar Akun',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Anda?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authBloc.logout();
              attendanceBloc.updateLoginState(false);
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: Text('Keluar',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarShimmer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PulsingSkeleton(width: 120, height: 18),
              Row(
                children: [
                  PulsingSkeleton(width: 24, height: 24, borderRadius: 12),
                  SizedBox(width: 16),
                  PulsingSkeleton(width: 24, height: 24, borderRadius: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Days skeleton grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => const Center(
              child: PulsingSkeleton(width: 24, height: 24, borderRadius: 6),
            ),
          ),
          const SizedBox(height: 20),
          const PulsingSkeleton(width: double.infinity, height: 1),
          const SizedBox(height: 16),
          const PulsingSkeleton(width: 80, height: 12),
          const SizedBox(height: 8),
          const PulsingSkeleton(
              width: double.infinity, height: 52, borderRadius: 8),
        ],
      ),
    );
  }

  Widget _buildCalendarError(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data kalender',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet Anda dan coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCalendarEvents,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
