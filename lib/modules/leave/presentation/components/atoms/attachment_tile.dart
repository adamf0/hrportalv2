import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttachmentTile extends StatelessWidget {
  final bool hasAttachment;
  final String fileName;
  final double fileSizeMb;
  final VoidCallback onUpload;
  final VoidCallback onDelete;
  final bool isUploading;
  final double uploadPercentage;
  final int bytesUploaded;
  final int totalBytes;
  final double speedMBps;
  final bool isUploadFailed;
  final VoidCallback? onCancelUpload;
  final VoidCallback? onRetryUpload;

  const AttachmentTile({
    super.key,
    required this.hasAttachment,
    required this.fileName,
    required this.fileSizeMb,
    required this.onUpload,
    required this.onDelete,
    this.isUploading = false,
    this.uploadPercentage = 0.0,
    this.bytesUploaded = 0,
    this.totalBytes = 0,
    this.speedMBps = 0.0,
    this.isUploadFailed = false,
    this.onCancelUpload,
    this.onRetryUpload,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Upload in progress state
    if (isUploading) {
      final uploadedMB = (bytesUploaded / (1024 * 1024)).toStringAsFixed(2);
      final totalMB = totalBytes > 0
          ? (totalBytes / (1024 * 1024)).toStringAsFixed(2)
          : fileSizeMb.toStringAsFixed(2);
      final pctText = '${(uploadPercentage * 100).toInt()}%';
      final speedText = speedMBps > 0 ? '${speedMBps.toStringAsFixed(1)} MB/s' : 'Mengunggah...';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  pctText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (onCancelUpload != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onCancelUpload,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.cancel_outlined, size: 20, color: Colors.grey),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: uploadPercentage > 0 ? uploadPercentage : null,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$uploadedMB MB / $totalMB MB',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  speedText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Upload Failed state
    if (isUploadFailed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gagal Mengunggah File',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onRetryUpload != null)
              TextButton.icon(
                onPressed: onRetryUpload,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi', style: TextStyle(fontSize: 11)),
              ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      );
    }

    // 3. No attachment selected state
    if (!hasAttachment) {
      return GestureDetector(
        onTap: onUpload,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainer, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_upload_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 32),
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

    // 4. Attachment completed state
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file,
              color: Theme.of(context).colorScheme.primary, size: 28),
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
                Row(
                  children: [
                    Text(
                      fileSizeMb > 0
                          ? '${fileSizeMb.toStringAsFixed(2)} MB'
                          : 'Dokumen terlampir',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Upload Selesai',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
