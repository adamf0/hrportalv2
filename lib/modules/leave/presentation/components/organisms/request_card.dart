import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:hrportalv2/modules/leave/domain/leave.dart';
import 'package:hrportalv2/modules/leave/domain/leave_status.dart';
import 'package:hrportalv2/core/storage_helper.dart';

class RequestCard extends StatefulWidget {
  final LeaveRequest req;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RequestCard({
    super.key,
    required this.req,
    this.onApprove,
    this.onReject,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _isDownloading = false;
  double _downloadPercentage = 0.0;
  int _bytesDownloaded = 0;
  int _totalBytes = 0;
  double _speedMBps = 0.0;
  bool _isDownloadCompleted = false;
  bool _isDownloadFailed = false;
  String? _localDownloadedPath;

  bool _hasValidAttachment(String? path) {
    if (path == null) return false;
    final t = path.trim().toLowerCase();
    return t.isNotEmpty &&
        t != 'null' &&
        t != '-' &&
        t != 'false' &&
        t != 'undefined';
  }

  String _resolveApplicantName() {
    final req = widget.req;
    if (req.applicantName != null && req.applicantName!.trim().isNotEmpty) {
      return req.applicantName!.trim();
    }
    final nip = req.applicantNip ?? '';
    final nidn = req.applicantNidn ?? '';

    if (nip.isNotEmpty) {
      return 'Pegawai (NIP: $nip)';
    }
    if (nidn.isNotEmpty) {
      return 'Dosen (NIDN: $nidn)';
    }
    return 'Pegawai';
  }

  String _calculateDuration() {
    final req = widget.req;
    final days = req.endDate.difference(req.startDate).inDays + 1;
    if (days <= 1) {
      return '1 Hari';
    }
    return '$days Hari';
  }

  IconData _getTypeIcon(String typeStr) {
    final lower = typeStr.toLowerCase();
    if (lower.contains('sppd')) return Icons.flight_takeoff;
    if (lower.contains('izin')) return Icons.time_to_leave;
    return Icons.event_note;
  }

  Color _getTypeColor(String typeStr) {
    final lower = typeStr.toLowerCase();
    if (lower.contains('sppd')) return Colors.orange[800]!;
    if (lower.contains('izin')) return Colors.teal[700]!;
    return Colors.indigo[700]!;
  }

  Future<void> _handleOpenAttachment(BuildContext context) async {
    final objectKey = widget.req.attachmentPath;
    if (objectKey == null || objectKey.trim().isEmpty) return;

    final lowerKey = objectKey.trim().toLowerCase();

    // 1. Deteksi link non-S3 (domain luar/URL web biasa seperti google.com, http://, https://)
    bool isExternalUrl = lowerKey.startsWith('http://') ||
        lowerKey.startsWith('https://') ||
        lowerKey.startsWith('www.') ||
        (lowerKey.contains('.') &&
            !lowerKey.contains('/') &&
            !lowerKey.endsWith('.pdf') &&
            !lowerKey.endsWith('.jpg') &&
            !lowerKey.endsWith('.jpeg') &&
            !lowerKey.endsWith('.png') &&
            !lowerKey.endsWith('.doc') &&
            !lowerKey.endsWith('.docx'));

    if (isExternalUrl) {
      String url = objectKey.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // 2. Jika file sudah pernah diunduh, buka langsung (Continue)
    if (_isDownloadCompleted && _localDownloadedPath != null) {
      final file = File(_localDownloadedPath!);
      if (await file.exists()) {
        final res = await OpenFilex.open(_localDownloadedPath!);
        if (res.type != ResultType.done) {
          final typeLower = widget.req.type.toLowerCase();
          final storageType = typeLower.contains('sppd')
              ? 'sppd'
              : (typeLower.contains('izin') ? 'izin' : 'cuti');
          final readUrl = await StorageHelper.getPresignedReadUrl(
              type: storageType, objectKey: objectKey);
          if (readUrl != null && readUrl.isNotEmpty) {
            final uri = Uri.parse(readUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        }
        return;
      }
    }

    // 3. Jalankan HTTP Streamed Download dengan indikator progress di bawah label
    final typeLower = widget.req.type.toLowerCase();
    final storageType = typeLower.contains('sppd')
        ? 'sppd'
        : (typeLower.contains('izin') ? 'izin' : 'cuti');

    final readUrl = await StorageHelper.getPresignedReadUrl(
        type: storageType, objectKey: objectKey);
    if (readUrl == null || readUrl.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _isDownloadFailed = false;
      _downloadPercentage = 0.0;
      _bytesDownloaded = 0;
      _totalBytes = 0;
      _speedMBps = 0.0;
    });

    try {
      final client = http.Client();
      final req = http.Request('GET', Uri.parse(readUrl));
      final response = await client.send(req);

      final total = response.contentLength ?? 0;
      final List<int> bytes = [];
      final stopwatch = Stopwatch()..start();

      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
          if (mounted) {
            setState(() {
              _bytesDownloaded = bytes.length;
              _totalBytes = total;
              if (elapsedSec > 0) {
                _speedMBps = (_bytesDownloaded / (1024 * 1024)) / elapsedSec;
              }
              if (total > 0) {
                _downloadPercentage = (_bytesDownloaded / total).clamp(0.0, 1.0);
              }
            });
          }
        },
        onDone: () async {
          stopwatch.stop();
          Directory? dir;
          try {
            dir = await getTemporaryDirectory();
          } catch (_) {
            dir = await getApplicationDocumentsDirectory();
          }
          final fileName = p.basename(objectKey);
          final cleanFileName = fileName.isEmpty ? "lampiran_$storageType.pdf" : fileName;
          final localFilePath = '${dir.path}/$cleanFileName';
          final file = File(localFilePath);
          await file.writeAsBytes(bytes);

          if (mounted) {
            setState(() {
              _isDownloading = false;
              _isDownloadCompleted = true;
              _localDownloadedPath = localFilePath;
              _downloadPercentage = 1.0;
            });
          }

          final res = await OpenFilex.open(localFilePath);
          if (res.type != ResultType.done) {
            final uri = Uri.parse(readUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _isDownloadFailed = true;
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[RequestCard _handleOpenAttachment error]: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final applicantName = _resolveApplicantName();
    final durationStr = _calculateDuration();
    final sppdMembersList = req.sppdMembers ??
        (req.members?.map((s) => SppdMember.fromSupervisor(s)).toList());

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Title & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(req.type).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTypeIcon(req.type),
                          size: 16,
                          color: _getTypeColor(req.type),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req.type,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _buildStatusTag(req.status),
              ],
            ),

            const SizedBox(height: 10),

            // Applicant Info Badge (Pemohon & NIP/NIDN)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50]?.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pemohon: ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          TextSpan(
                            text: applicantName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue[900],
                            ),
                          ),
                          if (req.applicantNip != null && req.applicantNip!.isNotEmpty)
                            TextSpan(
                              text: '  (NIP: ${req.applicantNip})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[800],
                              ),
                            ),
                          if (req.applicantNidn != null &&
                              req.applicantNidn!.isNotEmpty &&
                              (req.applicantNip == null || req.applicantNip!.isEmpty))
                            TextSpan(
                              text: '  (NIDN: ${req.applicantNidn})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[800],
                              ),
                            ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Card Body (Date, Duration, Details/Reason, Supervisor Note)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Tanggal: ${req.dateRange}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Lama: $durationStr',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alasan / Tujuan: ${req.details}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (req.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan Status: ${req.note}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (req.type.toLowerCase().contains('sppd') &&
                      sppdMembersList != null &&
                      sppdMembersList.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryColor.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.groups_outlined,
                                  size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'Daftar Anggota SPPD (${sppdMembersList.length} Orang):',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sppdMembersList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final m = sppdMembersList[index];
                              final details = <String>[];
                              if (m.nip.isNotEmpty) details.add('NIP: ${m.nip}');
                              if (m.nidn.isNotEmpty) details.add('NIDN: ${m.nidn}');
                              if (m.unit.isNotEmpty) details.add('Unit: ${m.unit}');
                              if (m.fakultas.isNotEmpty) details.add('Fakultas: ${m.fakultas}');
                              if (m.prodi.isNotEmpty) details.add('Prodi: ${m.prodi}');
                              final detailText = details.join(' • ');

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 11,
                                      backgroundColor: primaryColor.withOpacity(0.1),
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.nama,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[900],
                                            ),
                                          ),
                                          if (detailText.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              detailText,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_hasValidAttachment(req.attachmentPath)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isDownloadCompleted ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isDownloadCompleted
                              ? Colors.green[200]!
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _isDownloading
                                ? null
                                : () => _handleOpenAttachment(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                Icon(
                                  _isDownloadCompleted
                                      ? Icons.check_circle_outline
                                      : Icons.attachment_rounded,
                                  size: 16,
                                  color: _isDownloadCompleted
                                      ? Colors.green[700]
                                      : Colors.blue[800],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _isDownloadCompleted
                                        ? 'Buka Dokumen (Continue) (${req.attachmentPath!.split('/').last})'
                                        : 'Buka Lampiran Dokumen (${req.attachmentPath!.split('/').last})',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isDownloadCompleted
                                          ? Colors.green[800]
                                          : Colors.blue[900],
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_isDownloading)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_isDownloading) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _downloadPercentage > 0
                                    ? _downloadPercentage
                                    : null,
                                backgroundColor: Colors.blue[100],
                                color: Colors.blue[700],
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _totalBytes > 0
                                      ? '${(_bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB / ${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                                      : '${(_bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${(_downloadPercentage * 100).toStringAsFixed(0)}% • ${_speedMBps.toStringAsFixed(1)} MB/s',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_isDownloadFailed) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Gagal mengunduh dokumen. Ketuk lagi untuk mencoba ulang.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (widget.onApprove != null ||
                widget.onReject != null ||
                widget.onEdit != null ||
                widget.onDelete != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onDelete != null) ...[
                    OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                      label: Text('Hapus',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700])),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onEdit != null) ...[
                    OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.blue),
                      label: Text('Edit',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700])),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue[200]!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onReject != null) ...[
                    ElevatedButton.icon(
                      onPressed: widget.onReject,
                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      label: Text('Tolak',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onApprove != null)
                    ElevatedButton.icon(
                      onPressed: widget.onApprove,
                      icon: const Icon(Icons.check, size: 14, color: Colors.white),
                      label: Text('Setujui',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    final statusType = LeaveRequestStatus.fromString(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusType.tagBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusType.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: statusType.tagTextColor,
        ),
      ),
    );
  }
}
