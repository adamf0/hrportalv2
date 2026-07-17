import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';
import 'package:hrportalv2/modules/leave/domain/leave_status.dart';

class RequestCard extends StatelessWidget {
  final LeaveRequest req;

  const RequestCard({
    super.key,
    required this.req,
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
            Text(
              req.note,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[650],
              ),
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
