import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthSelector extends StatelessWidget {
  final List<String> months;
  final String selectedMonth;
  final ValueChanged<String> onMonthSelected;

  const MonthSelector({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: months.map((m) {
          final isSelected = selectedMonth == m;
          return GestureDetector(
            onTap: () => onMonthSelected(m),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Text(
                m,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
