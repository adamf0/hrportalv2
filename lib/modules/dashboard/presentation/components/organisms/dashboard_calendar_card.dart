import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/presentation/components/organisms/calendar_view.dart';
import 'package:hrportalv2/core/presentation/components/atoms/legend_dot.dart';

class DashboardCalendarCard extends StatelessWidget {
  final DateTime selectedCalendarDay;
  final ValueChanged<DateTime> onDaySelected;
  final Color Function(DateTime day) getDayStatusColor;
  final Color Function(DateTime day, bool isFaded, bool isRed, bool isSelected) getDayTextColor;
  final Widget Function(DateTime day, bool isFaded) buildDayIndicatorDot;
  final String dayStatus;
  final String dayTimes;
  final Color statusColor;

  const DashboardCalendarCard({
    super.key,
    required this.selectedCalendarDay,
    required this.onDaySelected,
    required this.getDayStatusColor,
    required this.getDayTextColor,
    required this.buildDayIndicatorDot,
    required this.dayStatus,
    required this.dayTimes,
    required this.statusColor,
  });

  String _getMonthName(int month) {
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  String _getMonthNameShort(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(selectedCalendarDay.month)} ${selectedCalendarDay.year}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: onSurfaceVariant, size: 22),
                    onPressed: () {
                      onDaySelected(DateTime(
                        selectedCalendarDay.year,
                        selectedCalendarDay.month - 1,
                        1,
                      ));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: onSurfaceVariant, size: 22),
                    onPressed: () {
                      onDaySelected(DateTime(
                        selectedCalendarDay.year,
                        selectedCalendarDay.month + 1,
                        1,
                      ));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          CalendarView(
            selectedCalendarDay: selectedCalendarDay,
            onDaySelected: onDaySelected,
            getDayStatusColor: getDayStatusColor,
            getDayTextColor: getDayTextColor,
            buildDayIndicatorDot: buildDayIndicatorDot,
          ),
          const SizedBox(height: 20),
          Container(height: 0.5, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Status Hari Ini (${selectedCalendarDay.day} ${_getMonthNameShort(selectedCalendarDay.month)})',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor,
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
                        dayStatus,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayTimes,
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LegendDot(color: AppTheme.success, label: 'Masuk'),
              LegendDot(color: AppTheme.warning, label: 'Izin'),
              LegendDot(color: AppTheme.info, label: 'Cuti'),
              LegendDot(color: AppTheme.secondary, label: 'Dinas'),
            ],
          ),
        ],
      ),
    );
  }
}
