import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/core/presentation/components/atoms/stat_card.dart';
import 'package:hrportalv2/modules/attendance/presentation/components/pages/ceremony_attendance_list_page.dart';

class AttendanceStatsSection extends StatefulWidget {
  final int totalAbsen1To31;
  final int totalIzin1To31;
  final int tidakMasuk1To31;
  final int totalUpacara1To31;
  final int totalAbsen15To15;
  final int totalIzin15To15;
  final int tidakMasuk15To15;
  final int totalUpacara15To15;

  const AttendanceStatsSection({
    super.key,
    required this.totalAbsen1To31,
    required this.totalIzin1To31,
    required this.tidakMasuk1To31,
    required this.totalUpacara1To31,
    required this.totalAbsen15To15,
    required this.totalIzin15To15,
    required this.tidakMasuk15To15,
    required this.totalUpacara15To15,
  });

  @override
  State<AttendanceStatsSection> createState() => _AttendanceStatsSectionState();
}

class _AttendanceStatsSectionState extends State<AttendanceStatsSection> {
  bool _is15To15 = false;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final currentAbsen = _is15To15 ? widget.totalAbsen15To15 : widget.totalAbsen1To31;
    final currentIzin = _is15To15 ? widget.totalIzin15To15 : widget.totalIzin1To31;
    final currentTidakMasuk = _is15To15 ? widget.tidakMasuk15To15 : widget.tidakMasuk1To31;
    final currentUpacara = _is15To15 ? widget.totalUpacara15To15 : widget.totalUpacara1To31;

    final card1 = StatCard(
      icon: Icons.check_circle_outline,
      iconColor: AppTheme.success,
      circleColor: AppTheme.successContainer,
      value: '$currentAbsen',
      label: 'Total Absen',
    );

    final card2 = StatCard(
      icon: Icons.star_outline,
      iconColor: AppTheme.warning,
      circleColor: AppTheme.warningContainer,
      value: '$currentIzin',
      label: 'Total Izin',
    );

    final card3 = StatCard(
      icon: Icons.cancel_outlined,
      iconColor: AppTheme.error,
      circleColor: AppTheme.errorContainer,
      value: '$currentTidakMasuk',
      label: 'Tidak Masuk',
    );

    final card4 = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CeremonyAttendanceListPage(),
          ),
        );
      },
      child: StatCard(
        icon: Icons.assistant_photo_outlined,
        iconColor: primaryColor,
        circleColor: primaryColor.withOpacity(0.1),
        value: '$currentUpacara',
        label: 'Total Upacara',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Statistik Kehadiran',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
            ),
            // Custom Segmented Toggle Button
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _is15To15 = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: !_is15To15 ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '1 - 31',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: !_is15To15 ? Colors.white : onSurface,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _is15To15 = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _is15To15 ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '15 - 15',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _is15To15 ? Colors.white : onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: context.isWatch ? 1 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            card1,
            card2,
            card3,
            card4,
          ],
        ),
      ],
    );
  }
}
