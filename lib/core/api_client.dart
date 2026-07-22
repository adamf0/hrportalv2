import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'sso_helper.dart';

/// Exception object for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}

/// Exception for cancelled API requests due to page switches
class ApiCancelledException implements Exception {
  final String scope;
  final String url;

  ApiCancelledException(this.scope, this.url);

  @override
  String toString() => 'Request cancelled due to page switch ($scope | $url)';
}

/// Robust API Client handling:
/// - Status 200, 204, 304: SUCCESS (Parses and extracts JSON data)
/// - Non 200/204/304 Statuses: Checks if JSON -> Extracts `message` field, else uses common error
/// - Catches network/timeout/unpredicted exceptions -> Logs full details & displays Toast/SnackBar
/// - Supports Page Scope cancellation (cancels/blocks requests when switching pages, except whoami/auth)
class ApiClient {
  static const String _defaultCommonError = 'Terjadi kesalahan pada server.';

  static String _activeScope = 'global';
  static int _currentScopeId = 0;

  static String get activeScope => _activeScope;
  static int get currentScopeId => _currentScopeId;

  /// Set active page scope. Cancels/blocks requests from previous page scopes!
  static void setActivePageScope(String scope) {
    _currentScopeId++;
    _activeScope = scope;
    debugPrint('[ApiClient PageScope] Active page scope set to: $scope (ID: $_currentScopeId)');
  }

  /// Check if a request URL or scope is exempted from page switch cancellation (e.g. auth, whoami, check-token)
  static bool isExemptedUrl(Uri url, String? customScope) {
    if (customScope == 'global' || customScope == 'whoami' || customScope == 'auth') return true;
    final path = url.path.toLowerCase();
    if (path.contains('whoami') ||
        path.contains('check-token') ||
        path.contains('auth') ||
        path.contains('login') ||
        path.contains('logout')) {
      return true;
    }
    return false;
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  /// Global key for displaying Toast/SnackBar for API notifications
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static String _scopeToPageTitle(String scope) {
    switch (scope.toLowerCase()) {
      case 'dashboard':
        return 'Dashboard';
      case 'sdm_report':
        return 'Laporan SDM';
      case 'attendance':
        return 'Presensi';
      case 'requests':
        return 'Pengajuan';
      case 'leave':
        return 'Cuti';
      case 'payroll':
        return 'Gaji';
      case 'auth':
        return 'Autentikasi';
      default:
        return scope.isNotEmpty ? scope : 'Halaman';
    }
  }

  /// Display a Toast SnackBar for API errors
  static void showToast(String message, {String? scope}) {
    final pageContext = scope ?? _activeScope;
    final pageTitle = _scopeToPageTitle(pageContext);
    final formattedMsg = '[$pageTitle] $message';
    debugPrint('[API Toast Notification]: $formattedMsg');

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formattedMsg,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Process HTTP Response according to status rules
  static dynamic processResponse(http.Response response) {
    final statusCode = response.statusCode;
    debugPrint('[API Log Response] Status: $statusCode | URL: ${response.request?.url} | Body: ${response.body}');

    // Status 200, 204, 304 = Success
    if (statusCode == 200 || statusCode == 204 || statusCode == 304) {
      if (response.body.isEmpty || statusCode == 204) {
        return <String, dynamic>{};
      }
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/event-stream') || response.body.startsWith('total:')) {
        try {
          final List<dynamic> list = [];
          final lines = response.body.split('\n');
          for (var line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('data:')) {
              final jsonStr = trimmed.substring(5).trim();
              if (jsonStr.isNotEmpty) {
                list.add(json.decode(jsonStr));
              }
            }
          }
          return list;
        } catch (e, stackTrace) {
          const errorMsg = 'Gagal memproses event stream data.';
          debugPrint('[API Error Log] Failed to parse SSE event-stream: $e\n$stackTrace');
          showToast(errorMsg);
          throw ApiException(errorMsg, statusCode: statusCode, body: response.body);
        }
      }
      try {
        return json.decode(response.body);
      } catch (e, stackTrace) {
        const errorMsg = 'Format data dari server tidak valid.';
        debugPrint('[API Error Log] Failed to parse JSON response on success status ($statusCode): $e\n$stackTrace');
        showToast(errorMsg);
        throw ApiException(errorMsg, statusCode: statusCode, body: response.body);
      }
    }

    // Status other than 200, 204, 304 -> Error Handling
    String errorMessage = '$_defaultCommonError (Status HTTP: $statusCode)';
    dynamic jsonBody;

    try {
      jsonBody = json.decode(response.body);
      if (jsonBody is Map<String, dynamic>) {
        if (jsonBody.containsKey('message') && jsonBody['message'] != null && jsonBody['message'].toString().isNotEmpty) {
          errorMessage = jsonBody['message'].toString();
        } else if (jsonBody.containsKey('msg') && jsonBody['msg'] != null && jsonBody['msg'].toString().isNotEmpty) {
          errorMessage = jsonBody['msg'].toString();
        } else if (jsonBody.containsKey('error') && jsonBody['error'] != null && jsonBody['error'].toString().isNotEmpty) {
          errorMessage = jsonBody['error'].toString();
        }
      }
    } catch (_) {
      debugPrint('[API Error Log] Non-JSON error body on status $statusCode: ${response.body}');
    }

    debugPrint('[API Error Log] Status $statusCode Exception: $errorMessage');
    showToast(errorMessage);
    throw ApiException(errorMessage, statusCode: statusCode, body: jsonBody ?? response.body);
  }

  static Future<Map<String, String>> _injectAuthHeaders(Map<String, String>? headers) async {
    final Map<String, String> finalHeaders = headers != null ? Map.from(headers) : {};
    try {
      final session = await SsoHelper.getSession();
      if (session != null && session['token'] != null) {
        final token = session['token'] as String;
        if (token.isNotEmpty && !finalHeaders.containsKey('Authorization')) {
          finalHeaders['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {}
    return finalHeaders;
  }

  /// Perform POST request
  static Future<dynamic> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
    String? scope,
  }) async {
    final reqScopeId = _currentScopeId;
    final reqScope = scope ?? _activeScope;
    final isExempt = isExemptedUrl(url, scope);

    if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
      debugPrint('[ApiClient Pre-Check Blocked]: POST $url (Scope mismatch: $reqScope != $_activeScope)');
      throw ApiCancelledException(reqScope, url.toString());
    }

    final injectedHeaders = await _injectAuthHeaders(headers);
    debugPrint('[API Loading State Log] Request: POST $url | State: START (Scope: $reqScope)');
    try {
      final response = await http.post(
        url,
        headers: injectedHeaders,
        body: body,
      ).timeout(timeout);

      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        debugPrint('[ApiClient Post-Check Cancelled]: POST $url (Page switched during request)');
        throw ApiCancelledException(reqScope, url.toString());
      }

      debugPrint('[API Loading State Log] Request: POST $url | State: END');
      return processResponse(response);
    } on ApiCancelledException {
      rethrow;
    } on SocketException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST $url | State: END (SocketException)');
      const msg = 'Koneksi internet terputus. Periksa jaringan Anda.';
      debugPrint('[API Exception Log] SocketException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on TimeoutException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST $url | State: END (TimeoutException)');
      const msg = 'Koneksi server mengalami batas waktu (timeout). Silakan coba lagi.';
      debugPrint('[API Exception Log] TimeoutException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on FormatException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST $url | State: END (FormatException)');
      const msg = 'Format data dari server mengalami kesalahan.';
      debugPrint('[API Exception Log] FormatException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST $url | State: END (Exception)');
      if (e is ApiException) rethrow;
      final msg = 'Terjadi kesalahan tidak terduga: $e';
      debugPrint('[API Unpredicted Exception Log]: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    }
  }

  /// Perform Multipart POST request
  static Future<dynamic> postMultipart(
    Uri url, {
    Map<String, String>? headers,
    required Map<String, String> fields,
    String? fileFieldName,
    String? filePath,
    Duration timeout = const Duration(seconds: 15),
    String? scope,
  }) async {
    final reqScopeId = _currentScopeId;
    final reqScope = scope ?? _activeScope;
    final isExempt = isExemptedUrl(url, scope);

    if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
      debugPrint('[ApiClient Pre-Check Blocked]: POST MULTIPART $url (Scope mismatch: $reqScope != $_activeScope)');
      throw ApiCancelledException(reqScope, url.toString());
    }

    final injectedHeaders = await _injectAuthHeaders(headers);
    debugPrint('[API Loading State Log] Request: POST MULTIPART $url | State: START (Scope: $reqScope)');
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(injectedHeaders);
      request.fields.addAll(fields);

      if (fileFieldName != null && filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(fileFieldName, filePath));
        }
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        debugPrint('[ApiClient Post-Check Cancelled]: POST MULTIPART $url (Page switched during request)');
        throw ApiCancelledException(reqScope, url.toString());
      }

      debugPrint('[API Loading State Log] Request: POST MULTIPART $url | State: END');
      return processResponse(response);
    } on ApiCancelledException {
      rethrow;
    } on SocketException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST MULTIPART $url | State: END (SocketException)');
      const msg = 'Koneksi internet terputus. Periksa jaringan Anda.';
      debugPrint('[API Exception Log] SocketException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on TimeoutException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST MULTIPART $url | State: END (TimeoutException)');
      const msg = 'Koneksi server mengalami batas waktu (timeout). Silakan coba lagi.';
      debugPrint('[API Exception Log] TimeoutException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on FormatException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST MULTIPART $url | State: END (FormatException)');
      const msg = 'Format data dari server mengalami kesalahan.';
      debugPrint('[API Exception Log] FormatException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: POST MULTIPART $url | State: END (Exception)');
      if (e is ApiException) rethrow;
      final msg = 'Terjadi kesalahan tidak terduga: $e';
      debugPrint('[API Unpredicted Exception Log]: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    }
  }

  /// Perform GET request
  static Future<dynamic> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 45),
    String? scope,
  }) async {
    final reqScopeId = _currentScopeId;
    final reqScope = scope ?? _activeScope;
    final isExempt = isExemptedUrl(url, scope);

    if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
      debugPrint('[ApiClient Pre-Check Blocked]: GET $url (Scope mismatch: $reqScope != $_activeScope)');
      throw ApiCancelledException(reqScope, url.toString());
    }

    final injectedHeaders = await _injectAuthHeaders(headers);
    debugPrint('[API Loading State Log] Request: GET $url | State: START (Scope: $reqScope)');
    try {
      final response = await http.get(
        url,
        headers: injectedHeaders,
      ).timeout(timeout);

      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        debugPrint('[ApiClient Post-Check Cancelled]: GET $url (Page switched during request)');
        throw ApiCancelledException(reqScope, url.toString());
      }

      debugPrint('[API Loading State Log] Request: GET $url | State: END');
      return processResponse(response);
    } on ApiCancelledException {
      rethrow;
    } on SocketException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: GET $url | State: END (SocketException)');
      const msg = 'Koneksi internet terputus. Periksa jaringan Anda.';
      debugPrint('[API Exception Log] SocketException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on TimeoutException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: GET $url | State: END (TimeoutException)');
      const msg = 'Koneksi server mengalami batas waktu (timeout). Silakan coba lagi.';
      debugPrint('[API Exception Log] TimeoutException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on FormatException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: GET $url | State: END (FormatException)');
      const msg = 'Format data dari server mengalami kesalahan.';
      debugPrint('[API Exception Log] FormatException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: GET $url | State: END (Exception)');
      if (e is ApiException) rethrow;
      final msg = 'Terjadi kesalahan tidak terduga: $e';
      debugPrint('[API Unpredicted Exception Log]: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    }
  }

  /// Perform PUT request
  static Future<dynamic> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
    String? scope,
  }) async {
    final reqScopeId = _currentScopeId;
    final reqScope = scope ?? _activeScope;
    final isExempt = isExemptedUrl(url, scope);

    if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
      debugPrint('[ApiClient Pre-Check Blocked]: PUT $url (Scope mismatch: $reqScope != $_activeScope)');
      throw ApiCancelledException(reqScope, url.toString());
    }

    final injectedHeaders = await _injectAuthHeaders(headers);
    debugPrint('[API Loading State Log] Request: PUT $url | State: START (Scope: $reqScope)');
    try {
      final response = await http.put(
        url,
        headers: injectedHeaders,
        body: body,
      ).timeout(timeout);

      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        debugPrint('[ApiClient Post-Check Cancelled]: PUT $url (Page switched during request)');
        throw ApiCancelledException(reqScope, url.toString());
      }

      debugPrint('[API Loading State Log] Request: PUT $url | State: END');
      return processResponse(response);
    } on ApiCancelledException {
      rethrow;
    } on SocketException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: PUT $url | State: END (SocketException)');
      const msg = 'Koneksi internet terputus. Periksa jaringan Anda.';
      debugPrint('[API Exception Log] SocketException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on TimeoutException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: PUT $url | State: END (TimeoutException)');
      const msg = 'Koneksi server mengalami batas waktu (timeout). Silakan coba lagi.';
      debugPrint('[API Exception Log] TimeoutException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } on FormatException catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: PUT $url | State: END (FormatException)');
      const msg = 'Format data dari server mengalami kesalahan.';
      debugPrint('[API Exception Log] FormatException: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    } catch (e, stackTrace) {
      if (!isExempt && (_activeScope != reqScope || _currentScopeId != reqScopeId)) {
        throw ApiCancelledException(reqScope, url.toString());
      }
      debugPrint('[API Loading State Log] Request: PUT $url | State: END (Exception)');
      if (e is ApiException) rethrow;
      final msg = 'Terjadi kesalahan tidak terduga: $e';
      debugPrint('[API Unpredicted Exception Log]: $e\n$stackTrace');
      showToast(msg);
      throw ApiException(msg);
    }
  }
}
