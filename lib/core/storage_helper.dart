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

  /// Direct S3 Presigned Upload (HTTP PUT via Streaming Request with Progress)
  static Future<String?> uploadFileWithPresign({
    required File file,
    required String type,
    http.Client? httpClient,
    void Function({
      required int bytesUploaded,
      required int totalBytes,
      required double percentage,
      required double speedMBps,
    })? onProgressDetailed,
  }) async {
    try {
      final fileName = p.basename(file.path);
      final mimeType = getMimeType(file.path);

      // 1. Request presigned upload URL ke backend Golang port 3000
      final presignUri = Uri.parse(
          "${ApiClient.baseUrl}/api/storage/presign-upload?type=$type&filename=${Uri.encodeComponent(fileName)}");

      final presignData = await ApiClient.get(presignUri);
      if (presignData == null || presignData['upload_url'] == null) {
        debugPrint('[StorageHelper] Presigned upload URL generation failed');
        return null;
      }

      final String uploadUrl = presignData['upload_url'];
      final String objectKey = presignData['object_key'];

      // 2. Perform HTTP PUT stream to S3 with progress calculation
      final fileLength = await file.length();
      final uri = Uri.parse(uploadUrl);
      final request = http.StreamedRequest('PUT', uri);

      request.headers['Content-Type'] = mimeType;
      request.contentLength = fileLength;

      final client = httpClient ?? http.Client();

      int bytesUploaded = 0;
      final stopwatch = Stopwatch()..start();

      final fileStream = file.openRead();
      final streamSubscription = fileStream.listen(
        (chunk) {
          bytesUploaded += chunk.length;
          request.sink.add(chunk);

          final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
          final double speedMBps = elapsedSec > 0
              ? (bytesUploaded / (1024 * 1024)) / elapsedSec
              : 0.0;
          final double percentage =
              fileLength > 0 ? (bytesUploaded / fileLength).clamp(0.0, 1.0) : 0.0;

          if (onProgressDetailed != null) {
            onProgressDetailed(
              bytesUploaded: bytesUploaded,
              totalBytes: fileLength,
              percentage: percentage,
              speedMBps: speedMBps,
            );
          }
        },
        onDone: () {
          request.sink.close();
          stopwatch.stop();
        },
        onError: (err) {
          request.sink.close();
          stopwatch.stop();
        },
        cancelOnError: true,
      );

      final response = await client.send(request);
      await streamSubscription.asFuture();

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint(
            '[StorageHelper] File uploaded successfully to S3: $objectKey');
        return objectKey;
      } else {
        debugPrint(
            '[StorageHelper] S3 Upload failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[StorageHelper uploadFileWithPresign error]: $e');
      return null;
    }
  }

  /// Meminta Presigned Read URL (HTTP GET) dari backend Golang untuk file private
  static Future<String?> getPresignedReadUrl({
    required String type,
    required String objectKey,
  }) async {
    try {
      final uri = Uri.parse(
          "${ApiClient.baseUrl}/api/storage/presign-read?type=$type&object=${Uri.encodeComponent(objectKey)}");

      final data = await ApiClient.get(uri);
      if (data != null && data['read_url'] != null) {
        return data['read_url'];
      }

      // Fallback ke secure streaming endpoint backend
      return "${ApiClient.baseUrl}/api/storage/file?type=$type&object=${Uri.encodeComponent(objectKey)}";
    } catch (e) {
      debugPrint('[StorageHelper getPresignedReadUrl error]: $e');
      return "${ApiClient.baseUrl}/api/storage/file?type=$type&object=${Uri.encodeComponent(objectKey)}";
    }
  }

  /// Download file private & buka via OpenFilex / URL Launcher tanpa toast, dengan browser launcher untuk non-S3
  static Future<void> openPrivateAttachment({
    required BuildContext context,
    required String type,
    required String objectKey,
    String? customFileName,
  }) async {
    final lowerKey = objectKey.trim().toLowerCase();

    // Deteksi jika link non-S3 (domain luar/URL web biasa seperti google.com, http://, https://)
    bool isExternalUrl = lowerKey.startsWith('http://') ||
        lowerKey.startsWith('https://') ||
        lowerKey.startsWith('www.') ||
        (lowerKey.contains('.') &&
            !lowerKey.contains('/') &&
            !lowerKey.endsWith('.pdf') &&
            !lowerKey.endsWith('.jpg') &&
            !lowerKey.endsWith('.jpeg') &&
            !lowerKey.endsWith('.png') &&
            !lowerKey.endsWith('.doc') &&
            !lowerKey.endsWith('.docx'));

    if (isExternalUrl) {
      String url = objectKey.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final readUrl = await getPresignedReadUrl(type: type, objectKey: objectKey);
    if (readUrl == null || readUrl.isEmpty) return;

    try {
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
          final uri = Uri.parse(readUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        final uri = Uri.parse(readUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[openPrivateAttachment error]: $e');
    }
  }
}
