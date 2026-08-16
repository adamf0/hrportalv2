import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color circleColor;
  final String value;
  final String label;
  final VoidCallback? onDetailTap;
  final String? detailText;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.circleColor,
    required this.value,
    required this.label,
    this.onDetailTap,
    this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (onDetailTap != null)
                InkWell(
                  onTap: onDetailTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detailText ?? 'Detail',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 12, color: primaryColor),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: context.sp(20),
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: context.sp(11),
              color: onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
