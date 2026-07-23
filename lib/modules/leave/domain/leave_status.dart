import 'package:flutter/material.dart';
import 'package:hrportalv2/core/app_theme.dart';

/// Strongly-typed Enum for Leave Request Statuses following Clean Code & Value Object pattern.
enum LeaveRequestStatus {
  pengajuan('pengajuan', 'menunggu'),
  diAccAtasan('terima atasan', 'terima atasan'),
  accSdm('terima sdm', 'disetujui'),
  tolakAtasan('tolak atasan', 'tolak atasan'),
  tolakSdm('tolak sdm', 'ditolak');

  final String label;
  final String alias;

  const LeaveRequestStatus(this.label, this.alias);

  /// Parse raw status strings dynamically into strongly-typed LeaveRequestStatus enum
  static LeaveRequestStatus fromString(String statusStr) {
    final normalized = statusStr.trim().toLowerCase();
    if (normalized == 'terima sdm' ||
        normalized == 'disetujui' ||
        normalized == 'terima sdm') {
      return LeaveRequestStatus.accSdm;
    } else if (normalized == 'terima atasan') {
      return LeaveRequestStatus.diAccAtasan;
    } else if (normalized == 'tolak atasan') {
      return LeaveRequestStatus.tolakAtasan;
    } else if (normalized == 'tolak sdm' || normalized == 'ditolak') {
      return LeaveRequestStatus.tolakSdm;
    } else if (normalized == 'pengajuan' || normalized == 'menunggu') {
      return LeaveRequestStatus.pengajuan;
    } else {
      return LeaveRequestStatus.pengajuan;
    }
  }

  /// True if the leave status is in approved state
  bool get isApproved =>
      this == LeaveRequestStatus.accSdm ||
      this == LeaveRequestStatus.diAccAtasan;

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
