import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../core/location_wifi_helper.dart';
import '../core/responsive_helper.dart';
import 'leave_form_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const background = Color(0xFFF8F9FB);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF535F73);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Prompt GPS permission dialog on startup if not allowed yet
      await LocationWifiHelper.getCurrentLocation();
      appState.evaluateAndTriggerAutoCheckIn();
    });

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Circular Profile Avatar (Matching premium woman image in mockup)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[200]!, width: 1.5),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HR Connect',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Halo, ${appState.loggedInUser}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Logout action next to notification
                      IconButton(
                        icon: const Icon(Icons.logout,
                            color: onSurfaceVariant, size: 20),
                        onPressed: () {
                          _showLogoutConfirmDialog(context, appState);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 14),
                      // Notification Bell
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.notifications_none,
                                color: primaryColor, size: 20),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // "Selamat Pagi!" Banner Card (Dark blue rounded card)
              Container(
                padding: EdgeInsets.all(context.isWatch ? 12 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003D9B), Color(0xFF0A4EBC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Pagi!',
                      style: GoogleFonts.inter(
                        fontSize: context.sp(20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appState.isCheckedIn
                          ? 'Anda sudah melakukan absen masuk hari ini. Selamat bekerja!'
                          : 'Jangan lupa untuk melakukan absen masuk hari ini.',
                      style: GoogleFonts.inter(
                        fontSize: context.sp(12),
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Check-in / Check-out status cards (Side-by-Side or Stacked)
              Builder(
                builder: (context) {
                  final jamMasukCard = GestureDetector(
                    onTap: () {
                      if (!appState.isCheckedIn) {
                        appState.setTabIndex(1); // Go to attendance tab
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.login, color: primaryColor, size: context.w(24)),
                          const SizedBox(height: 8),
                          Text(
                            'Jam Masuk',
                            style: GoogleFonts.inter(
                              fontSize: context.sp(11),
                              color: onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.checkInTime,
                            style: GoogleFonts.inter(
                              fontSize: context.sp(15),
                              fontWeight: FontWeight.bold,
                              color: appState.isCheckedIn ? onSurface : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final jamPulangCard = GestureDetector(
                    onTap: () {
                      if (appState.isCheckedIn && appState.checkOutTime == "--:--") {
                        _simulateCheckOut(context, appState);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.logout, color: Colors.grey, size: context.w(24)),
                          const SizedBox(height: 8),
                          Text(
                            'Jam Pulang',
                            style: GoogleFonts.inter(
                              fontSize: context.sp(11),
                              color: onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.checkOutTime,
                            style: GoogleFonts.inter(
                              fontSize: context.sp(15),
                              fontWeight: FontWeight.bold,
                              color: appState.checkOutTime != "--:--" ? onSurface : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  return Flex(
                    direction: context.isWatch ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                    children: [
                      context.isWatch ? jamMasukCard : Expanded(child: jamMasukCard),
                      SizedBox(
                        width: context.isWatch ? 0 : 16,
                        height: context.isWatch ? 12 : 0,
                      ),
                      context.isWatch ? jamPulangCard : Expanded(child: jamPulangCard),
                    ],
                  );
                },
              ),
              // Presensi Upacara Banner/Button (appears if 17th and eligible, or already checked in)
              if (appState.isUpacaraEligible() || appState.isUpacaraCheckedIn) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appState.isUpacaraCheckedIn ? const Color(0xFFE8F0FE) : const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appState.isUpacaraCheckedIn ? Colors.blue[200]! : Colors.orange[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            appState.isUpacaraCheckedIn ? Icons.military_tech : Icons.campaign,
                            color: appState.isUpacaraCheckedIn ? Colors.blue : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Presensi Upacara Bendera 17-an',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: appState.isUpacaraCheckedIn ? const Color(0xFF1967D2) : const Color(0xFFB06000),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appState.isUpacaraCheckedIn
                                      ? 'Berhasil presensi upacara pada ${appState.upacaraTime} (Tanpa absen keluar)'
                                      : 'Jadwal presensi upacara aktif. Silakan lakukan verifikasi wajah.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: appState.isUpacaraCheckedIn ? const Color(0xFF1967D2).withOpacity(0.8) : const Color(0xFFB06000).withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!appState.isUpacaraCheckedIn) ...[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            appState.isUpacaraCheckInIntent = true;
                            appState.setTabIndex(1); // Go to Liveness Scanner tab
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 38),
                            elevation: 0,
                          ),
                          child: Text(
                            'Lakukan Presensi Upacara',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Real-time Auto-Attendance Status Card
              Builder(
                builder: (context) {
                  if (appState.isCheckedIn) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA), // Soft green
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Absen Otomatis Berhasil',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF137333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kehadiran Anda hari ini telah berhasil diverifikasi secara otomatis.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF137333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'IP: ${appState.realIp} | GPS: ${appState.realLatitude.toStringAsFixed(6)}, ${appState.realLongitude.toStringAsFixed(6)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF137333)
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // If still loading location/IP details
                  final isLoading = appState.isAutoCheckInEvaluating;

                  if (isLoading) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE), // Soft blue
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proses Absensi Otomatis...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'mencoba absen otomatis dari jaringan / gps unpak...',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: primaryColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // If location resolved but failed (not in radius and not on wifi)
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8E6), // Soft red/pink
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Absen Otomatis Gagal',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFC5221F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'sistem gagal absensi otomatis, perlu presensi manual oleh pengguna',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFC5221F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'note: secara otomatis jalankan ulang presensi otomatis ketika anda terhubung wifi unpak / berada kawasan unpak',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          const Color.fromARGB(255, 67, 67, 67),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'IP: ${appState.realIp} | GPS: ${appState.realLatitude.toStringAsFixed(6)}, ${appState.realLongitude.toStringAsFixed(6)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFC5221F)
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => appState.setTabIndex(1),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: Text(
                            'Presensi Manual (Scan Wajah)',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5221F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(double.infinity, 38),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Calendar Card Container (October 2023)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey[150] ?? const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Calendar Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Oktober 2023',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: onSurfaceVariant, size: 22),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: onSurfaceVariant, size: 22),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calendar Table
                    _buildCalendarView(context, appState),
                    const SizedBox(height: 20),

                    // Divider
                    Container(height: 0.5, color: Colors.grey[200]),
                    const SizedBox(height: 16),

                    // Status Hari Ini Section
                    Text(
                      'Status Hari Ini (${appState.selectedCalendarDay.day} Okt)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hadir Tepat Waktu Card with Left Vertical Color Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFF3F4F6), // light gray background matching design
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Left color indicator bar
                          Container(
                            width: 6,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _getCalendarDayStatusColor(
                                  appState.selectedCalendarDay.day, appState),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getCalendarDayStatus(
                                      appState.selectedCalendarDay.day,
                                      appState),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getCalendarDayTimes(
                                      appState.selectedCalendarDay.day,
                                      appState),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Legend indicators row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLegendDot(Colors.green, 'Masuk'),
                        _buildLegendDot(Colors.orange, 'Izin'),
                        _buildLegendDot(Colors.blue, 'Cuti'),
                        _buildLegendDot(const Color(0xFF535F73), 'Dinas'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // "Statistik Kehadiran Bulan Ini" section
              Text(
                'Statistik Kehadiran Bulan Ini',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final card1 = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6F4EA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appState.totalAbsen}',
                          style: GoogleFonts.outfit(
                            fontSize: context.sp(20),
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Absen',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(11),
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );

                  final card2 = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4E5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_outline, color: Colors.orange, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appState.totalIzin}',
                          style: GoogleFonts.outfit(
                            fontSize: context.sp(20),
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Izin',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(11),
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );

                  final card3 = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFCE8E6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appState.totalTidakMasuk}',
                          style: GoogleFonts.outfit(
                            fontSize: context.sp(20),
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tidak Masuk',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(11),
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );

                  return Flex(
                    direction: context.isWatch ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                    children: [
                      context.isWatch ? card1 : Expanded(child: card1),
                      SizedBox(
                        width: context.isWatch ? 0 : 8,
                        height: context.isWatch ? 8 : 0,
                      ),
                      context.isWatch ? card2 : Expanded(child: card2),
                      SizedBox(
                        width: context.isWatch ? 0 : 8,
                        height: context.isWatch ? 8 : 0,
                      ),
                      context.isWatch ? card3 : Expanded(child: card3),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // "Ringkasan Cuti" section
              Text(
                'Ringkasan Cuti',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Split grid cuti (Left large card, Right column of 2 smaller cards)
              Builder(
                builder: (context) {
                  final leftCard = Container(
                    height: 124, // fits the height of the two right cards + spacing
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E3FB), // light blue-indigo card
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SISA CUTI TAHUNAN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF3B475B),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${appState.sisaCuti} Hari',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF101C2D),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 13, color: Color(0xFF3B475B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Berlaku hingga Des 2024',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF3B475B),
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  final cardDiambil = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEFF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diambil',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appState.cutiDiambil}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  );

                  final cardPending = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEFF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appState.cutiPending}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  );

                  final rightColumn = Column(
                    children: [
                      cardDiambil,
                      const SizedBox(height: 8),
                      cardPending,
                    ],
                  );

                  return Flex(
                    direction: context.isWatch ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      context.isWatch ? leftCard : Expanded(flex: 3, child: leftCard),
                      SizedBox(
                        width: context.isWatch ? 0 : 16,
                        height: context.isWatch ? 12 : 0,
                      ),
                      context.isWatch
                          ? Row(
                              children: [
                                Expanded(child: cardDiambil),
                                const SizedBox(width: 8),
                                Expanded(child: cardPending),
                              ],
                            )
                          : Expanded(flex: 2, child: rightColumn),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // "Menu Cepat" section
              Text(
                'Menu Cepat',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final buttons = [
                    _buildQuickMenuButton(
                      context,
                      Icons.face_retouching_natural,
                      'Absensi',
                      () => appState.setTabIndex(1),
                    ),
                    _buildQuickMenuButton(
                      context,
                      Icons.calendar_month_outlined,
                      'Cuti',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveFormPage(initialTab: 0),
                        ),
                      ),
                    ),
                    _buildQuickMenuButton(
                      context,
                      Icons.assignment_turned_in_outlined,
                      'Izin',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveFormPage(initialTab: 1),
                        ),
                      ),
                    ),
                    _buildQuickMenuButton(
                      context,
                      Icons.flight_takeoff,
                      'SPPD',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveFormPage(
                            initialTab: 1,
                            initialType: 'Dinas Luar Kantor',
                          ),
                        ),
                      ),
                    ),
                    _buildQuickMenuButton(
                      context,
                      Icons.payments_outlined,
                      'Slip Gaji',
                      () => appState.setTabIndex(3),
                    ),
                  ];

                  if (context.isWatch) {
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: buttons,
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: buttons,
                  );
                },
              ),
              const SizedBox(height: 24),

              // "Aktivitas Terbaru" section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas Terbaru',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      appState.setTabIndex(2); // Go to Request tab
                    },
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Activities List (Borderless filled cards)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.activities.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final act = appState.activities[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFF3F4F6), // filled light gray background
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: act.isSuccess
                                ? const Color(0xFFE6F4EA)
                                : const Color(0xFFFEF3D6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            act.isSuccess
                                ? Icons.check_circle_outlined
                                : Icons.more_horiz,
                            color: act.isSuccess ? Colors.green : Colors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                act.time,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Builder(builder: (context) {
                return Container();
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, AppState appState) {
    // Standard weekdays headers
    final weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Row 1 (faded): 24, 25, 26, 27, 28, 29, 30
    final row1 = [24, 25, 26, 27, 28, 29, 30];
    // Row 2: 1, 2, 3, 4, 5, 6, 7
    final row2 = [1, 2, 3, 4, 5, 6, 7];
    // Row 3: 8, 9, 10, 11, 12, 13, 14
    final row3 = [8, 9, 10, 11, 12, 13, 14];

    return Column(
      children: [
        // Weekdays Headers Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays
              .map((dayName) => Expanded(
                    child: Text(
                      dayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Row 1 Days (Faded)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row1
              .map((d) => Expanded(
                    child: _buildDayCell(d, true, false, appState),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Row 2 Days
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row2
              .map((d) => Expanded(
                    child: _buildDayCell(d, false, d == 7, appState),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Row 3 Days
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row3
              .map((d) => Expanded(
                    child: _buildDayCell(d, false, d == 8 || d == 14, appState),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDayCell(int day, bool isFaded, bool isRed, AppState appState) {
    final isSelected = !isFaded && appState.selectedCalendarDay.day == day;

    // Day text style
    Color textColor = Colors.black;
    if (isFaded) {
      textColor = Colors.grey[300]!;
    } else if (isRed) {
      textColor = Colors.red[600]!;
    }
    if (isSelected) {
      textColor = const Color(0xFF003D9B); // matching capsule highlighting
    }

    return GestureDetector(
      onTap: isFaded
          ? null
          : () {
              appState.selectCalendarDay(DateTime(2023, 10, day));
            },
      child: Center(
        child: Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD7E3FB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              // Indicator Dot
              _buildDayIndicatorDot(day, isFaded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayIndicatorDot(int day, bool isFaded) {
    Color dotColor = Colors.transparent;
    if (!isFaded) {
      if (day == 9 || day == 1 || day == 2 || day == 5 || day == 6) {
        dotColor = Colors.green; // Hadir / Masuk
      } else if (day == 3) {
        dotColor = Colors.orange; // Izin
      } else if (day == 4) {
        dotColor = Colors.blue; // Cuti
      }
    }

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getCalendarDayStatusColor(int day, AppState appState) {
    if (day == 9) {
      return appState.isCheckedIn ? Colors.green : Colors.grey[400]!;
    }
    if (day == 1 || day == 2 || day == 5 || day == 6) {
      return Colors.green;
    }
    if (day == 3) return Colors.orange;
    if (day == 4) return Colors.blue;
    return Colors.grey;
  }

  String _getCalendarDayStatus(int day, AppState appState) {
    if (day == 9) {
      return appState.isCheckedIn ? 'Hadir Tepat Waktu' : 'Belum Absen';
    }
    if (day == 1 || day == 2 || day == 5 || day == 6) {
      return 'Hadir Tepat Waktu';
    }
    if (day == 3) return 'Izin Sakit';
    if (day == 4) return 'Cuti Tahunan';
    return 'Libur Hari Raya / Akhir Pekan';
  }

  String _getCalendarDayTimes(int day, AppState appState) {
    if (day == 9) {
      return 'Masuk: ${appState.checkInTime} • Pulang: ${appState.checkOutTime}';
    }
    if (day == 1 || day == 2 || day == 5 || day == 6) {
      return 'Masuk: 08:15 • Pulang: 17:00';
    }
    if (day == 3) return 'Tanpa Surat Dokter (Disetujui)';
    if (day == 4) return 'Acara Keluarga (Disetujui)';
    return 'Hari Istirahat';
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF535F73),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMenuButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    const primaryColor = Color(0xFF003D9B);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: context.w(56),
            height: context.w(56),
            decoration: BoxDecoration(
              color: const Color(
                  0xFFE6F0FD), // light blue background matching design mockup
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor, size: context.w(24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: context.sp(11),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1E),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateCheckOut(BuildContext context, AppState appState) {
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
            onPressed: () {
              Navigator.pop(context);
              appState.doCheckOut("17:05");
              ScaffoldMessenger.of(context).showSnackBar(
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

  void _showLogoutConfirmDialog(BuildContext context, AppState appState) {
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
            onPressed: () {
              Navigator.pop(context);
              appState.logout();
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
