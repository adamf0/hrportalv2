import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class LeaveSummarySection extends StatelessWidget {
  final int sisaCuti;
  final int cutiDiambil;
  final int cutiPending;

  const LeaveSummarySection({
    super.key,
    required this.sisaCuti,
    required this.cutiDiambil,
    required this.cutiPending,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;

    final leftCard = Container(
      height: 124,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SISA CUTI TAHUNAN',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
          ),
          ),
          const SizedBox(height: 6),
          Text(
            '$sisaCuti Hari',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppTheme.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Berlaku hingga Des 2024',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final cardDiambil = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diambil',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$cutiDiambil',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
    );

    final cardPending = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$cutiPending',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
    );

    final rightColumn = Column(
      children: [
        cardDiambil,
        const SizedBox(height: 8),
        cardPending,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Cuti',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Flex(
          direction: context.isWatch ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            context.isWatch ? leftCard : Expanded(flex: 3, child: leftCard),
            SizedBox(
              width: context.isWatch ? 0 : 16,
              height: context.isWatch ? 12 : 0,
            ),
            context.isWatch
                ? Row(
                    children: [
                      Expanded(child: cardDiambil),
                      const SizedBox(width: 8),
                      Expanded(child: cardPending),
                    ],
                  )
                : Expanded(flex: 2, child: rightColumn),
          ],
        ),
      ],
    );
  }
}
