import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';

class MemberSelectorTile extends StatelessWidget {
  final List<Supervisor> selectedMembers;
  final VoidCallback onTap;
  final ValueChanged<Supervisor> onRemoveMember;

  const MemberSelectorTile({
    super.key,
    required this.selectedMembers,
    required this.onTap,
    required this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (selectedMembers.isEmpty) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.group_add, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pilih Anggota Tim / Pengikut',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedMembers.map((member) {
              return Chip(
                backgroundColor: primaryColor.withOpacity(0.1),
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                avatar: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                label: Text(
                  member.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteIconColor: Colors.red[700],
                onDeleted: () => onRemoveMember(member),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              icon: Icon(Icons.add, size: 16, color: primaryColor),
              label: Text(
                'Kelola Anggota (${selectedMembers.length})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
