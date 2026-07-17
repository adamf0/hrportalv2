import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class PermissionTileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onRequestTap;

  const PermissionTileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGrey = Theme.of(context).colorScheme.secondary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(context.isWatch ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isGranted ? AppTheme.successContainer : AppTheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isGranted ? AppTheme.success : AppTheme.error,
                    size: context.w(20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ),
                if (!isGranted)
                  TextButton(
                    onPressed: onRequestTap,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Izinkan', style: GoogleFonts.inter(fontSize: context.sp(12))),
                  )
                else
                  Icon(Icons.check_circle, color: Colors.green, size: context.w(20)),
              ],
            ),
            if (!context.isWatch) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: context.sp(11),
                  color: textGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
