import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class YearSelector extends StatelessWidget {
  final String selectedYear;
  final ValueChanged<String?> onChanged;

  const YearSelector({
    super.key,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Flex(
      direction: context.isWatch ? Axis.vertical : Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        if (!context.isWatch) ...[
          Text(
            'Periode Tahun',
            style: GoogleFonts.inter(
              fontSize: context.sp(12),
              fontWeight: FontWeight.w500,
              color: onSurfaceVariant,
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedYear,
              icon: Icon(Icons.expand_more, color: onSurfaceVariant, size: 18),
              style: GoogleFonts.inter(
                fontSize: context.sp(14),
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
              onChanged: onChanged,
              items: List<String>.generate(
                DateTime.now().year - 2000 + 1,
                (index) => (2000 + index).toString(),
              ).map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
