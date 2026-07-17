import 'package:flutter/material.dart';
import 'package:hrportalv2/modules/leave/domain/leave_form_type.dart';

/// Strategy Interface for handling form attachments
abstract class AttachmentStrategy {
  bool get hasAttachment;
  String get fileName;
  double get fileSizeMb;
  VoidCallback get onUpload;
  VoidCallback get onDelete;
}

/// Concrete Strategy for Cuti Attachments
class CutiAttachmentStrategy implements AttachmentStrategy {
  @override
  final bool hasAttachment;
  @override
  final String fileName;
  @override
  final double fileSizeMb;
  @override
  final VoidCallback onUpload;
  @override
  final VoidCallback onDelete;

  CutiAttachmentStrategy({
    required this.hasAttachment,
    required this.fileName,
    required this.fileSizeMb,
    required this.onUpload,
    required this.onDelete,
  });
}

/// Concrete Strategy for Izin Attachments
class IzinAttachmentStrategy implements AttachmentStrategy {
  @override
  final bool hasAttachment;
  @override
  final String fileName;
  @override
  final double fileSizeMb;
  @override
  final VoidCallback onUpload;
  @override
  final VoidCallback onDelete;

  IzinAttachmentStrategy({
    required this.hasAttachment,
    required this.fileName,
    required this.fileSizeMb,
    required this.onUpload,
    required this.onDelete,
  });
}

/// Concrete Strategy for SPPD Attachments
class SppdAttachmentStrategy implements AttachmentStrategy {
  @override
  final bool hasAttachment;
  @override
  final String fileName;
  @override
  final double fileSizeMb;
  @override
  final VoidCallback onUpload;
  @override
  final VoidCallback onDelete;

  SppdAttachmentStrategy({
    required this.hasAttachment,
    required this.fileName,
    required this.fileSizeMb,
    required this.onUpload,
    required this.onDelete,
  });
}

/// Simple Factory to create concrete strategies based on strongly-typed LeaveFormType enum
class AttachmentStrategyFactory {
  static AttachmentStrategy create({
    required LeaveFormType type,
    required bool hasAttachment,
    required String fileName,
    required double fileSizeMb,
    required VoidCallback onUpload,
    required VoidCallback onDelete,
  }) {
    switch (type) {
      case LeaveFormType.cuti:
        return CutiAttachmentStrategy(
          hasAttachment: hasAttachment,
          fileName: fileName,
          fileSizeMb: fileSizeMb,
          onUpload: onUpload,
          onDelete: onDelete,
        );
      case LeaveFormType.izin:
        return IzinAttachmentStrategy(
          hasAttachment: hasAttachment,
          fileName: fileName,
          fileSizeMb: fileSizeMb,
          onUpload: onUpload,
          onDelete: onDelete,
        );
      case LeaveFormType.sppd:
        return SppdAttachmentStrategy(
          hasAttachment: hasAttachment,
          fileName: fileName,
          fileSizeMb: fileSizeMb,
          onUpload: onUpload,
          onDelete: onDelete,
        );
    }
  }
}
