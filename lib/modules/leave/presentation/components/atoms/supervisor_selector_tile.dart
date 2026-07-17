import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';

class SupervisorSelectorTile extends StatelessWidget {
  final Supervisor? selectedSupervisor;
  final VoidCallback onTap;

  const SupervisorSelectorTile({
    super.key,
    required this.selectedSupervisor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
