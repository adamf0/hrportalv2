import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class GreetingBanner extends StatelessWidget {
  final bool isCheckedIn;

  const GreetingBanner({
    super.key,
    required this.isCheckedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isWatch ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
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
            isCheckedIn
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
    );
  }
}
