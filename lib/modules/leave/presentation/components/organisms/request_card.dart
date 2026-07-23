import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';
import 'package:hrportalv2/modules/leave/domain/leave_status.dart';

class RequestCard extends StatelessWidget {
  final LeaveRequest req;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const RequestCard({
    super.key,
    required this.req,
    this.onApprove,
    this.onReject,
  });

  String _resolveApplicantName() {
    if (req.applicantName != null &&
        req.applicantName!.isNotEmpty &&
        req.applicantName != 'Pegawai') {
      return req.applicantName!;
    }
    final nip = req.applicantNip ?? '';
    final nidn = req.applicantNidn ?? '';

    if (nip == '4102302214' || nidn == '4102302214') {
      return 'Adam Furqon';
    }
    if (nip == '10411006520' || nidn == '0409098601' || nip == '0409098601') {
      return 'ARIES MAESYA';
    }
    if (nip.isNotEmpty) {
      return 'Pemohon NIP $nip';
    }
    if (nidn.isNotEmpty) {
      return 'Pemohon NIDN $nidn';
    }
    return 'Pemohon SDM';
  }

  String _calculateDuration() {
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

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final applicantName = _resolveApplicantName();
    final durationStr = _calculateDuration();

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
                              req.applicantNidn != req.applicantNip)
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
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Date Range & Duration Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 16, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tanggal: ${req.dateRange}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Lama: $durationStr',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (req.details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined, size: 16, color: Colors.grey),
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
                  ],

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
                ],
              ),
            ),

            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (onReject != null && onApprove != null) const SizedBox(width: 8),
                  if (onApprove != null)
                    ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('ACC'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildStatusTag(String statusStr) {
    final status = LeaveRequestStatus.fromString(statusStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.tagBackgroundColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        statusStr.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: status.tagTextColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
