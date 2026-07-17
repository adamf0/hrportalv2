import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/common/presentation/components/atoms/header_title_text.dart';

class LeaveFormSuccessDialog extends StatelessWidget {
  const LeaveFormSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.successContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
          ),
          const SizedBox(height: 16),
          const HeaderTitleText(
            text: 'Pengajuan Terkirim',
            fontSize: 18,
          ),
          const SizedBox(height: 8),
          Text(
            'Pengajuan Anda telah berhasil dikirim ke atasan untuk verifikasi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 44),
              elevation: 0,
            ),
            child: Text(
              'Kembali',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
