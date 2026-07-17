import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'package:hrportalv2/core/app_theme.dart';
import '../../../auth/presentation/auth_bloc.dart';
import '../../../attendance/presentation/attendance_bloc.dart';
import '../../../leave/presentation/leave_bloc.dart';
import '../../../../core/location_wifi_helper.dart';
import '../../../leave/presentation/components/pages/leave_form_page.dart';

// Atomic Design Components
import 'package:hrportalv2/core/presentation/components/molecules/quick_menu_button.dart';
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
      if (statusLower == "acc" || statusLower == "disetujui" || statusLower == "terima sdm") {
        return ev;
      }
    }

    // 3. Otherwise return the first event (e.g. pending ones)
    return list.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LocationWifiHelper.getCurrentLocation();
      if (!mounted) return;
      final authBloc = context.read<AuthBloc>();
      final attendanceBloc = context.read<AttendanceBloc>();
      attendanceBloc.updateLoginState(authBloc.isLoggedIn);
      await context.read<LeaveBloc>().fetchLeaves();
      await _fetchCalendarEvents();
    });
  }

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  Future<void> _fetchCalendarEvents() async {
    final authBloc = context.read<AuthBloc>();
    final nip = authBloc.session?.nip ?? '';
    if (nip.isEmpty) return;

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

      final responseData = await ApiClient.get(
        Uri.parse(
            "${ApiClient.baseUrl}/api/calendar?start_date=$startStr&end_date=$endStr"),
      );

      if (responseData is List) {
        _calendarEvents.clear();
        for (var item in responseData) {
          if (item is Map<String, dynamic>) {
            final tanggal = item['tanggal'] as String? ?? '';
            if (tanggal.isNotEmpty) {
              final cleanKey = tanggal.split('T')[0];
              _calendarEvents.putIfAbsent(cleanKey, () => []).add(CalendarItem.fromJson(item));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching calendar events: $e");
    }
  }

  Map<String, DateTime> _getPeriod1To31() {
    final ref = _selectedCalendarDay;
    final start = DateTime(ref.year, ref.month, 1);
    final end = DateTime(ref.year, ref.month + 1, 0);
    return {'start': start, 'end': end};
  }

  Map<String, DateTime> _getPeriod15To15() {
    final ref = _selectedCalendarDay;
    final start = DateTime(ref.year, ref.month - 1, 15);
    final end = DateTime(ref.year, ref.month, 14);
    return {'start': start, 'end': end};
  }

  int _calculateAbsenForPeriod(
      DateTime start, DateTime end, AttendanceBloc attendanceBloc) {
    int count = 0;
    for (var act in attendanceBloc.activities) {
      if (act.title.contains("Absen Masuk") && act.isSuccess) {
        final parts = act.time.split(' • ');
        if (parts.isNotEmpty) {
          final dateStr = parts[0];
          DateTime? actDate;
          if (dateStr == "Hari ini" || dateStr.startsWith("Hari")) {
            actDate = DateTime.now();
          } else {
            actDate = DateTime.tryParse(dateStr);
          }
          if (actDate != null) {
            final normalizedAct =
                DateTime(actDate.year, actDate.month, actDate.day);
            final normalizedStart =
                DateTime(start.year, start.month, start.day);
            final normalizedEnd = DateTime(end.year, end.month, end.day);
            if ((normalizedAct.isAfter(normalizedStart) ||
                    normalizedAct.isAtSameMomentAs(normalizedStart)) &&
                (normalizedAct.isBefore(normalizedEnd) ||
                    normalizedAct.isAtSameMomentAs(normalizedEnd))) {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  int _calculateIzinForPeriod(
      DateTime start, DateTime end, LeaveBloc leaveBloc) {
    int count = 0;
    for (var req in leaveBloc.leaves) {
      final statusLower = req.status.toLowerCase();
      if (statusLower == "acc" ||
          statusLower == "disetujui" ||
          statusLower.contains("acc")) {
        final isCuti = req.type.toLowerCase().contains("cuti");
        if (!isCuti) {
          final reqStart = req.startDate;
          final reqEnd = req.endDate;
          final intersectStart = reqStart.isAfter(start) ? reqStart : start;
          final intersectEnd = reqEnd.isBefore(end) ? reqEnd : end;
          if (intersectStart.isBefore(intersectEnd) ||
              DateUtils.isSameDay(intersectStart, intersectEnd)) {
            final days = intersectEnd.difference(intersectStart).inDays + 1;
            count += days;
          }
        }
      }
    }
    return count;
  }

  int _calculateTidakMasukForPeriod(
      DateTime start, DateTime end, int totalAbsen, int totalIzin) {
    int workdays = 0;
    DateTime cur = start;
    final today = DateTime.now();
    final limit = end.isAfter(today) ? today : end;
    while (cur.isBefore(limit) || DateUtils.isSameDay(cur, limit)) {
      if (cur.weekday != DateTime.sunday) {
        workdays++;
      }
      cur = cur.add(const Duration(days: 1));
    }
    final missing = workdays - totalAbsen - totalIzin;
    return missing > 0 ? missing : 0;
  }

  int _calculateUpacaraForPeriod(
      DateTime start, DateTime end, AttendanceBloc attendanceBloc) {
    int count = 0;
    for (var upacara in attendanceBloc.ceremonyAttendances) {
      final dateStr = upacara.tanggal.contains('T') ? upacara.tanggal.split('T')[0] : upacara.tanggal;
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final normalizedStart = DateTime(start.year, start.month, start.day);
        
        // Upacaras are held on the 17th of each month. 
        // If it's the 15-15 cutoff, extend the end limit to the 17th to count the current month's upacara.
        final adjustedEnd = (end.day == 14 || end.day == 15)
            ? DateTime(end.year, end.month, 17)
            : end;
        final normalizedEnd = DateTime(adjustedEnd.year, adjustedEnd.month, adjustedEnd.day);
        
        if ((normalizedDate.isAfter(normalizedStart) ||
                normalizedDate.isAtSameMomentAs(normalizedStart)) &&
            (normalizedDate.isBefore(normalizedEnd) ||
                normalizedDate.isAtSameMomentAs(normalizedEnd))) {
          count++;
        }
      }
    }
    return count;
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
                    Color textColor = Colors.black;
                    if (isFaded) {
                      textColor = Colors.grey[300]!;
                    } else if (isRed) {
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
                  totalAbsen1To31: _calculateAbsenForPeriod(
                      _getPeriod1To31()['start']!,
                      _getPeriod1To31()['end']!,
                      attendanceBloc),
                  totalIzin1To31: _calculateIzinForPeriod(
                      _getPeriod1To31()['start']!,
                      _getPeriod1To31()['end']!,
                      leaveBloc),
                  tidakMasuk1To31: _calculateTidakMasukForPeriod(
                    _getPeriod1To31()['start']!,
                    _getPeriod1To31()['end']!,
                    _calculateAbsenForPeriod(_getPeriod1To31()['start']!,
                        _getPeriod1To31()['end']!, attendanceBloc),
                    _calculateIzinForPeriod(_getPeriod1To31()['start']!,
                        _getPeriod1To31()['end']!, leaveBloc),
                  ),
                  totalUpacara1To31: _calculateUpacaraForPeriod(
                      _getPeriod1To31()['start']!,
                      _getPeriod1To31()['end']!,
                      attendanceBloc),
                  totalAbsen15To15: _calculateAbsenForPeriod(
                      _getPeriod15To15()['start']!,
                      _getPeriod15To15()['end']!,
                      attendanceBloc),
                  totalIzin15To15: _calculateIzinForPeriod(
                      _getPeriod15To15()['start']!,
                      _getPeriod15To15()['end']!,
                      leaveBloc),
                  tidakMasuk15To15: _calculateTidakMasukForPeriod(
                    _getPeriod15To15()['start']!,
                    _getPeriod15To15()['end']!,
                    _calculateAbsenForPeriod(_getPeriod15To15()['start']!,
                        _getPeriod15To15()['end']!, attendanceBloc),
                    _calculateIzinForPeriod(_getPeriod15To15()['start']!,
                        _getPeriod15To15()['end']!, leaveBloc),
                  ),
                  totalUpacara15To15: _calculateUpacaraForPeriod(
                      _getPeriod15To15()['start']!,
                      _getPeriod15To15()['end']!,
                      attendanceBloc),
                ),
                const SizedBox(height: 24),
                LeaveSummarySection(
                  sisaCuti: leaveBloc.sisaCuti,
                  cutiDiambil: leaveBloc.cutiDiambil,
                  cutiPending: leaveBloc.cutiPending,
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
            },
            child: Text('Keluar',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
