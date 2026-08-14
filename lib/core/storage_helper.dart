import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'api_client.dart';

class StorageHelper {
  /// Mendeteksi Content-Type (MIME) dari ekstensi file
  static String getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload file ke S3 Object Storage via Presigned PUT URL
  /// Mengembalikan objectKey (contoh: "2026/08/abc123_surat.pdf")
  static Future<String?> uploadFileWithPresign({
    required File file,
    required String type, // 'cuti', 'izin', atau 'sppd'
    Function(double progress)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        debugPrint('[StorageHelper] File lokal tidak ditemukan: ${file.path}');
        return null;
      }

      final fileName = p.basename(file.path);
      final mimeType = getMimeType(file.path);

      // 1. Minta Presigned Upload URL ke Backend Go
      final presignUri = Uri.parse(
        "${ApiClient.baseUrl}/api/storage/presign-upload?type=$type&filename=${Uri.encodeComponent(fileName)}&content_type=${Uri.encodeComponent(mimeType)}",
      );

      final res = await ApiClient.get(presignUri);
      if (res is! Map<String, dynamic> || res['upload_url'] == null) {
        throw Exception("Gagal mendapatkan presigned upload URL dari server");
      }

      final uploadUrl = res['upload_url'].toString();
      final objectKey = res['object_key']?.toString() ?? res['file_path']?.toString() ?? fileName;

      onProgress?.call(0.3);

      // 2. Upload langsung bytes file ke Object Storage via HTTP PUT
      final fileBytes = await file.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': mimeType,
        },
        body: fileBytes,
      );

      onProgress?.call(0.9);

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 204) {
        debugPrint('[StorageHelper] Berhasil upload ke S3: $objectKey (Bucket: $type)');
        onProgress?.call(1.0);
        return objectKey;
      } else {
        throw Exception(
            "S3 Upload failed with status ${uploadResponse.statusCode}: ${uploadResponse.body}");
      }
    } catch (e, stack) {
      debugPrint('[StorageHelper uploadFileWithPresign error]: $e\n$stack');
      return null;
    }
  }

  /// Mendapatkan URL read private via Presigned GET
  static Future<String?> getPresignedReadUrl({
    required String type, // 'cuti', 'izin', atau 'sppd'
    required String objectKey,
  }) async {
    try {
      if (objectKey.isEmpty) return null;

      final presignUri = Uri.parse(
        "${ApiClient.baseUrl}/api/storage/presign-read?type=$type&object=${Uri.encodeComponent(objectKey)}",
      );

      final res = await ApiClient.get(presignUri);
      if (res is Map<String, dynamic> && (res['read_url'] != null || res['url'] != null)) {
        return (res['read_url'] ?? res['url']).toString();
      }

      // Fallback ke secure streaming endpoint backend
      return "${ApiClient.baseUrl}/api/storage/file?type=$type&object=${Uri.encodeComponent(objectKey)}";
    } catch (e) {
      debugPrint('[StorageHelper getPresignedReadUrl error]: $e');
      return "${ApiClient.baseUrl}/api/storage/file?type=$type&object=${Uri.encodeComponent(objectKey)}";
    }
  }

  /// Download file private & buka via OpenFilex / URL Launcher
  static Future<void> openPrivateAttachment({
    required BuildContext context,
    required String type,
    required String objectKey,
    String? customFileName,
  }) async {
    try {
      ApiClient.showToast("Menyiapkan dokumen lampiran...", scope: 'storage');

      final readUrl = await getPresignedReadUrl(type: type, objectKey: objectKey);
      if (readUrl == null || readUrl.isEmpty) {
        ApiClient.showToast("Gagal memuat link dokumen lampiran.", scope: 'storage');
        return;
      }

      // Download file ke direktori sementara
      final response = await http.get(Uri.parse(readUrl));
      if (response.statusCode == 200) {
        Directory? dir;
        try {
          dir = await getTemporaryDirectory();
        } catch (_) {
          dir = await getApplicationDocumentsDirectory();
        }

        final fileName = customFileName ?? p.basename(objectKey);
        final cleanFileName = fileName.isEmpty ? "lampiran_$type.pdf" : fileName;
        final localFilePath = '${dir.path}/$cleanFileName';
        final file = File(localFilePath);
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFilex.open(localFilePath);
        if (result.type != ResultType.done) {
          // Fallback buka via browser
          final uri = Uri.parse(readUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        // Coba buka langsung URL jika download via app gagal
        final uri = Uri.parse(readUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ApiClient.showToast("Gagal mengunduh lampiran (status: ${response.statusCode})",
              scope: 'storage');
        }
      }
    } catch (e) {
      debugPrint('[StorageHelper openPrivateAttachment error]: $e');
      ApiClient.showToast("Gagal membuka dokumen: $e", scope: 'storage');
    }
  }
}
