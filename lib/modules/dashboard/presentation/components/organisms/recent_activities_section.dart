import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentActivitiesSection extends StatelessWidget {
  final Widget activitiesList;
  final VoidCallback onSeeAllTap;

  const RecentActivitiesSection({
    super.key,
    required this.activitiesList,
    required this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: onSeeAllTap,
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
        activitiesList,
      ],
    );
  }
}
