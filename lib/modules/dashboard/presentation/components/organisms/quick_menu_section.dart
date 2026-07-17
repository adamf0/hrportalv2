import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class QuickMenuSection extends StatelessWidget {
  final List<Widget> buttons;

  const QuickMenuSection({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}
