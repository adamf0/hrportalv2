import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class QuickMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.w(56),
            height: context.w(56),
            decoration: BoxDecoration(
              color: AppTheme.infoContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor, size: context.w(24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: context.sp(11),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
