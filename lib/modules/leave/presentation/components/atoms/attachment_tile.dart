import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttachmentTile extends StatelessWidget {
  final bool hasAttachment;
  final String fileName;
  final double fileSizeMb;
  final VoidCallback onUpload;
  final VoidCallback onDelete;

  const AttachmentTile({
    super.key,
    required this.hasAttachment,
    required this.fileName,
    required this.fileSizeMb,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasAttachment) {
      return GestureDetector(
        onTap: onUpload,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                'Unggah Dokumen Lampiran',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Format PDF, JPG, PNG (Maks. 5MB)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${fileSizeMb.toStringAsFixed(2)} MB',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
