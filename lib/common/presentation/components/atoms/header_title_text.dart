import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';

class HeaderTitleText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final TextAlign? textAlign;

  const HeaderTitleText({
    super.key,
    required this.text,
    this.fontSize = 18.0,
    this.color = AppTheme.onSurface,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
