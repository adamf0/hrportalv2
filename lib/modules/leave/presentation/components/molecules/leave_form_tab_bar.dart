import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/modules/leave/domain/leave_form_type.dart';

class LeaveFormTabBar extends StatelessWidget {
  final LeaveFormType activeType;
  final ValueChanged<LeaveFormType> onTypeChanged;

  const LeaveFormTabBar({
    super.key,
    required this.activeType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.isWatch ? 8.0 : 20.0,
        vertical: 12.0,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabItem(
              context: context,
              type: LeaveFormType.cuti,
              watchLabel: 'Cuti',
              label: 'Form Cuti',
              primaryColor: primaryColor,
              onSurfaceVariant: onSurfaceVariant,
            ),
            _buildTabItem(
              context: context,
              type: LeaveFormType.izin,
              watchLabel: 'Izin',
              label: 'Form Izin',
              primaryColor: primaryColor,
              onSurfaceVariant: onSurfaceVariant,
            ),
            _buildTabItem(
              context: context,
              type: LeaveFormType.sppd,
              watchLabel: 'SPPD',
              label: 'Form SPPD',
              primaryColor: primaryColor,
              onSurfaceVariant: onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required LeaveFormType type,
    required String watchLabel,
    required String label,
    required Color primaryColor,
    required Color onSurfaceVariant,
  }) {
    final isSelected = activeType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            context.isWatch ? watchLabel : label,
            style: GoogleFonts.inter(
              fontSize: context.sp(12),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primaryColor : onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
