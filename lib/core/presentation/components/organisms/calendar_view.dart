import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';

class CalendarView extends StatelessWidget {
  final DateTime selectedCalendarDay;
  final ValueChanged<DateTime> onDaySelected;
  final Color Function(DateTime day) getDayStatusColor;
  final Color Function(DateTime day, bool isFaded, bool isRed, bool isSelected) getDayTextColor;
  final Widget Function(DateTime day, bool isFaded) buildDayIndicatorDot;

  const CalendarView({
    super.key,
    required this.selectedCalendarDay,
    required this.onDaySelected,
    required this.getDayStatusColor,
    required this.getDayTextColor,
    required this.buildDayIndicatorDot,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Calculate start of grid based on first day of month
    final firstDay = DateTime(selectedCalendarDay.year, selectedCalendarDay.month, 1);
    final prefixDays = firstDay.weekday % 7;
    final gridStart = firstDay.subtract(Duration(days: prefixDays));

    // Generate 6 rows of 7 days (42 days total)
    final List<DateTime> calendarDays = List.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
    );

    final row1 = calendarDays.sublist(0, 7);
    final row2 = calendarDays.sublist(7, 14);
    final row3 = calendarDays.sublist(14, 21);
    final row4 = calendarDays.sublist(21, 28);
    final row5 = calendarDays.sublist(28, 35);
    final row6 = calendarDays.sublist(35, 42);

    return Column(
      children: [
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row1.map((d) => Expanded(child: _buildDayCell(d))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row2.map((d) => Expanded(child: _buildDayCell(d))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row3.map((d) => Expanded(child: _buildDayCell(d))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row4.map((d) => Expanded(child: _buildDayCell(d))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row5.map((d) => Expanded(child: _buildDayCell(d))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row6.map((d) => Expanded(child: _buildDayCell(d))).toList(),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isFaded = day.month != selectedCalendarDay.month;
    final isSelected = DateUtils.isSameDay(selectedCalendarDay, day);
    final isRed = day.weekday == DateTime.sunday;
    final textColor = getDayTextColor(day, isFaded, isRed, isSelected);

    return GestureDetector(
      onTap: () => onDaySelected(day),
      child: Center(
        child: Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.infoContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.day}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              buildDayIndicatorDot(day, isFaded),
            ],
          ),
        ),
      ),
    );
  }
}
