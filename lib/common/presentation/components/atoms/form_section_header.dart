import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormSectionHeader extends StatelessWidget {
  final String title;

  const FormSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: onSurface,
        letterSpacing: 0.5,
      ),
    );
  }
}
