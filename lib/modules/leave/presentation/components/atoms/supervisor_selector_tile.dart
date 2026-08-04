import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/presentation/components/atoms/pulsing_skeleton.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';

class SupervisorSelectorTile extends StatelessWidget {
  final Supervisor? selectedSupervisor;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRetry;

  const SupervisorSelectorTile({
    super.key,
    required this.selectedSupervisor,
    required this.onTap,
    this.isLoading = false,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const PulsingSkeleton(
        width: double.infinity,
        height: 72,
        borderRadius: 12,
      );
    }

    if (isError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gagal Memuat Verifikator',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Periksa koneksi lalu coba lagi',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[700],
              ),
            ),
          ],
        ),
      );
    }

    if (selectedSupervisor == null) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.surfaceContainer),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_search, color: colorScheme.primary),
        ),
        title: Text(
          'Pilih Atasan Verifikator',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Ketuk untuk mencari atasan Anda...',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: colorScheme.secondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.surfaceContainer),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppTheme.infoContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: colorScheme.primary),
      ),
      title: Text(
        selectedSupervisor!.name,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        'NIP: ${selectedSupervisor!.id} • ${selectedSupervisor!.role}',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: colorScheme.secondary,
        ),
      ),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          'Ganti',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
