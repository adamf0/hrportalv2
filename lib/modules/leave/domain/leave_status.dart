import 'package:flutter/material.dart';
import 'package:hrportalv2/core/app_theme.dart';

/// Strongly-typed Enum for Leave Request Statuses following Clean Code & Value Object pattern.
enum LeaveRequestStatus {
  pengajuan('Pengajuan', 'Menunggu'),
  diAccAtasan('Di ACC Atasan', 'Di ACC Atasan'),
  accSdm('ACC SDM', 'Disetujui'),
  tolakAtasan('Tolak Atasan', 'Tolak Atasan'),
  tolakSdm('Tolak SDM', 'Ditolak');

  final String label;
  final String alias;

  const LeaveRequestStatus(this.label, this.alias);

  /// Parse raw status strings dynamically into strongly-typed LeaveRequestStatus enum
  static LeaveRequestStatus fromString(String statusStr) {
    final normalized = statusStr.trim().toUpperCase();
    if (normalized == 'ACC SDM' || normalized == 'DISETUJUI' || normalized == 'TERIMA SDM') {
      return LeaveRequestStatus.accSdm;
    } else if (normalized == 'DI ACC ATASAN') {
      return LeaveRequestStatus.diAccAtasan;
    } else if (normalized == 'TOLAK ATASAN') {
      return LeaveRequestStatus.tolakAtasan;
    } else if (normalized == 'TOLAK SDM' || normalized == 'DITOLAK') {
      return LeaveRequestStatus.tolakSdm;
    } else {
      return LeaveRequestStatus.pengajuan;
    }
  }

  /// True if the leave status is in approved state
  bool get isApproved =>
      this == LeaveRequestStatus.accSdm || this == LeaveRequestStatus.diAccAtasan;

  /// Background color for status badge rendering
  Color get tagBackgroundColor {
    switch (this) {
      case LeaveRequestStatus.accSdm:
        return AppTheme.successContainer;
      case LeaveRequestStatus.diAccAtasan:
        return AppTheme.infoContainer;
      case LeaveRequestStatus.pengajuan:
        return AppTheme.warningContainer;
      case LeaveRequestStatus.tolakAtasan:
        return AppTheme.errorContainer;
      case LeaveRequestStatus.tolakSdm:
        return AppTheme.errorContainer;
    }
  }

  /// Text color for status badge rendering
  Color get tagTextColor {
    switch (this) {
      case LeaveRequestStatus.accSdm:
        return AppTheme.success;
      case LeaveRequestStatus.diAccAtasan:
        return AppTheme.info;
      case LeaveRequestStatus.pengajuan:
        return AppTheme.warning;
      case LeaveRequestStatus.tolakAtasan:
        return AppTheme.error;
      case LeaveRequestStatus.tolakSdm:
        return AppTheme.error;
    }
  }
}
