import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/core/presentation/components/atoms/pulsing_skeleton.dart';

class AttendanceTimeCards extends StatelessWidget {
  final bool isCheckedIn;
  final String checkInTime;
  final String checkOutTime;
  final VoidCallback onJamMasukTap;
  final VoidCallback onJamPulangTap;
  final bool isLoading;

  const AttendanceTimeCards({
    super.key,
    required this.isCheckedIn,
    required this.checkInTime,
    required this.checkOutTime,
    required this.onJamMasukTap,
    required this.onJamPulangTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;

    if (isLoading) {
      const shimmerCard = PulsingSkeleton(
        width: double.infinity,
        height: 90,
        borderRadius: 12,
      );

      return Flex(
        direction: context.isWatch ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: context.isWatch
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: [
          context.isWatch ? shimmerCard : const Expanded(child: shimmerCard),
          SizedBox(
            width: context.isWatch ? 0 : 16,
            height: context.isWatch ? 12 : 0,
          ),
          context.isWatch ? shimmerCard : const Expanded(child: shimmerCard),
        ],
      );
    }

    final jamMasukCard = GestureDetector(
      onTap: onJamMasukTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.login, color: primaryColor, size: context.w(24)),
            const SizedBox(height: 8),
            Text(
              'Jam Masuk',
              style: GoogleFonts.inter(
                fontSize: context.sp(11),
                color: onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              checkInTime,
              style: GoogleFonts.inter(
                fontSize: context.sp(15),
                fontWeight: FontWeight.bold,
                color: isCheckedIn ? onSurface : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );

    final jamPulangCard = GestureDetector(
      onTap: onJamPulangTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.logout, color: Colors.grey, size: context.w(24)),
            const SizedBox(height: 8),
            Text(
              'Jam Pulang',
              style: GoogleFonts.inter(
                fontSize: context.sp(11),
                color: onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              checkOutTime,
              style: GoogleFonts.inter(
                fontSize: context.sp(15),
                fontWeight: FontWeight.bold,
                color: checkOutTime != "--:--" ? onSurface : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );

    return Flex(
      direction: context.isWatch ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: context.isWatch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        context.isWatch ? jamMasukCard : Expanded(child: jamMasukCard),
        SizedBox(
          width: context.isWatch ? 0 : 16,
          height: context.isWatch ? 12 : 0,
        ),
        context.isWatch ? jamPulangCard : Expanded(child: jamPulangCard),
      ],
    );
  }
}
