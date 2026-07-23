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

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                _buildStatusTag(req.status),
              ],
            ),
            // Applicant Info Badge (Pemohon & NIP/NIDN)
            if (req.applicantName != null || req.applicantNip != null || req.applicantNidn != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue[800]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Pemohon: ',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            TextSpan(
                              text: req.applicantName ?? 'Pegawai',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                            if (req.applicantNip != null && req.applicantNip!.isNotEmpty)
                              TextSpan(
                                text: '  (NIP: ${req.applicantNip})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
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
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  req.dateRange,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.details,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.note,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[650],
                    ),
                  ),
                ),
                if (onApprove != null || onReject != null) ...[
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (onReject != null)
                        ElevatedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Tolak'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (onReject != null && onApprove != null) const SizedBox(width: 6),
                      if (onApprove != null)
                        ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('ACC'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String statusStr) {
    final status = LeaveRequestStatus.fromString(statusStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
