import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';

class AutoCheckInStatusCard extends StatelessWidget {
  final bool isCheckedIn;
  final bool isAutoCheckInEvaluating;
  final String realIp;
  final double realLatitude;
  final double realLongitude;
  final VoidCallback onManualCheckInTap;

  const AutoCheckInStatusCard({
    super.key,
    required this.isCheckedIn,
    required this.isAutoCheckInEvaluating,
    required this.realIp,
    required this.realLatitude,
    required this.realLongitude,
    required this.onManualCheckInTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (isCheckedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Absen Otomatis Berhasil',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kehadiran Anda hari ini telah berhasil diverifikasi secara otomatis.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'IP: $realIp | GPS: ${realLatitude.toStringAsFixed(6)}, ${realLongitude.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.success.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isAutoCheckInEvaluating) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.infoContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proses Absensi Otomatis...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'mencoba absen otomatis dari jaringan / gps unpak...',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Absen Otomatis Gagal',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'sistem gagal absensi otomatis, perlu presensi manual oleh pengguna',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pencegahan: Posisi Anda berada di luar area kampus Pakuan.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IP: $realIp | GPS: ${realLatitude.toStringAsFixed(6)}, ${realLongitude.toStringAsFixed(6)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.error.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onManualCheckInTap,
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: Text(
              'Presensi Manual (Scan Wajah)',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 38),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
