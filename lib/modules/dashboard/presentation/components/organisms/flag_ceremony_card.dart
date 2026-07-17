import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';

class FlagCeremonyCard extends StatelessWidget {
  final bool isUpacaraCheckedIn;
  final String upacaraTime;
  final VoidCallback onVerifyTap;
  final bool isButtonEnabled;

  const FlagCeremonyCard({
    super.key,
    required this.isUpacaraCheckedIn,
    required this.upacaraTime,
    required this.onVerifyTap,
    this.isButtonEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUpacaraCheckedIn ? AppTheme.infoContainer : AppTheme.warningContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpacaraCheckedIn ? Colors.blue[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isUpacaraCheckedIn ? Icons.military_tech : Icons.campaign,
                color: isUpacaraCheckedIn ? AppTheme.info : AppTheme.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presensi Upacara Bendera 17-an',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUpacaraCheckedIn ? AppTheme.info : AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUpacaraCheckedIn
                          ? 'Berhasil presensi upacara pada $upacaraTime (Tanpa absen keluar)'
                          : isButtonEnabled
                              ? 'Jadwal presensi upacara aktif. Silakan lakukan verifikasi wajah.'
                              : 'Presensi hanya dibuka setiap tanggal 17 pukul 08:00 - 09:00 WIB.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isUpacaraCheckedIn
                            ? AppTheme.info.withOpacity(0.8)
                            : AppTheme.warning.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isUpacaraCheckedIn) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isButtonEnabled ? onVerifyTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 38),
                elevation: 0,
              ),
              child: Text(
                'Lakukan Presensi Upacara',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
