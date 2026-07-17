import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusFilterSheet extends StatelessWidget {
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final ValueChanged<String> onStatusSelected;

  const StatusFilterSheet({
    super.key,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Status Pengajuan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: statusFilters.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final statusName = statusFilters[index];
                  final isSelected = selectedStatusFilter == statusName;

                  return ListTile(
                    title: Text(
                      statusName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryColor : onSurface,
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
                    onTap: () => onStatusSelected(statusName),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
