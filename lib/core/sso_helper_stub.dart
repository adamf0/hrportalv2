// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'sqlite_auth_storage.dart';
import 'fcm_service.dart';
import 'api_client.dart';

import 'auto_attendance_service.dart';

class SsoHelper {
  static const String _clientId = "unpak_link_gate";
  static const String _logoutUrl =
      "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/logout";

  static const _appAuth = FlutterAppAuth();

  static String lastTokenRefreshTime = "Belum Refreshed";
  static Completer<String?>? _refreshCompleter;

  static void updateTokenRefreshTime() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    lastTokenRefreshTime = "$year-$month-$day $hour:$minute:$second";
  }

  static Future<String?> getLoggedInName() async {
    final session = await SqliteAuthStorage.instance.getSession();
    if (session != null && (session['name'] as String).isNotEmpty) {
      return session['name'];
    }
    return await LocalStorageMobile.read('name');
  }

  static Future<void> printSsoTelemetry() async {
    try {
      final session = await SqliteAuthStorage.instance.getSession();
      final token = session?['token'] ?? await LocalStorageMobile.read('token');
      final refresh = await LocalStorageMobile.read('refresh');
      final idToken = await LocalStorageMobile.read('idToken');
      print("========== KEYCLOAK SSO DEBUG TELEMETRY ==========");
      print("Access Token: $token");
      print("Refresh Token: $refresh");
      print("ID Token: $idToken");
      if (token != null) {
        final decoded = _decodeJwt(token);
        print("Decoded Access Token Payload: ${jsonEncode(decoded)}");
      }
      if (idToken != null) {
        final decoded = _decodeJwt(idToken);
        print("Decoded ID Token Payload: ${jsonEncode(decoded)}");
      }
      print("==================================================");
    } catch (e) {
      print("Telemetry logging error: $e");
    }
  }

  static Future<Map<String, dynamic>?> loginWithSso() async {
    try {
      print("Starting SSO mobile login via flutter_appauth...");
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          "com.unpak.hrportal:/oauth2redirect",
          issuer: "https://gerbang.unpak.ac.id/realms/gateway",
          scopes: ['openid', 'profile', 'email'],
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint:
                "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/auth",
            tokenEndpoint:
                "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/token",
            endSessionEndpoint:
                "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/logout",
          ),
        ),
      );

      if (result.accessToken != null) {
        final accessToken = result.accessToken!;
        final refreshToken = result.refreshToken;
        final idToken = result.idToken;

        await LocalStorageMobile.write('token', accessToken);
        if (refreshToken != null) {
          await LocalStorageMobile.write('refresh', refreshToken);
        }
        if (idToken != null) await LocalStorageMobile.write('idToken', idToken);

        final decoded = _decodeJwt(idToken ?? accessToken);
        final name = decoded['name'] ?? "User";
        final email = decoded['email'] ?? "";
        final employeeId = decoded['employeeid']?.toString() ?? "";
        final groups = (decoded['group'] as List?) ?? [];

        String level = "tendik";
        String nip = "-";
        String nidn = "-";

        if (groups.contains("SDM")) {
          level = "sdm";
          nip = employeeId.isNotEmpty ? employeeId : "-";
        } else if (groups.contains("Dosen")) {
          level = "dosen";
          nidn = employeeId.isNotEmpty ? employeeId : "-";
        } else if (groups.contains("Tendik")) {
          level = "tendik";
          nip = employeeId.isNotEmpty ? employeeId : "-";
        }

        final usernameStr = employeeId.isNotEmpty ? employeeId : "-";

        await saveSession(
          username: usernameStr,
          password: "",
          token: accessToken,
          name: name,
          nidn: nidn,
          nip: nip,
          email: email,
          role: level,
          groups: List<String>.from(groups.map((e) => e.toString())),
        );

        return {
          "name": name,
          "level": level,
          "token": accessToken,
        };
      }
    } catch (e) {
      print("SSO Mobile Login Error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> checkAndExchangeCode() async {
    return null;
  }

  static Future<void> logout() async {
    await AutoAttendanceService.instance.stopServiceAndCancelWorkmanager();
    final refreshToken = await LocalStorageMobile.read('refresh');
    await SqliteAuthStorage.instance.clearAll();
    await LocalStorageMobile.clear();

    if (refreshToken != null) {
      try {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse(_logoutUrl));
        request.headers
            .set('content-type', 'application/x-www-form-urlencoded');
        final body =
            "client_id=$_clientId&refresh_token=${Uri.encodeComponent(refreshToken)}";
        request.write(body);
        await request.close();
      } catch (e) {
        // Ignore
      }
    }
  }

  static bool _isTokenExpired(String token) {
    try {
      final decoded = _decodeJwt(token);
      final exp = decoded['exp'] as int?;
      if (exp == null) return false;
      final currentEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return currentEpoch >= (exp - 30);
    } catch (e) {
      return true;
    }
  }

  static Future<String?> getValidToken() async {
    final session = await getSession();
    if (session == null) return null;

    final token = session['token'] as String?;
    if (token == null || token.isEmpty) return null;

    if (!_isTokenExpired(token)) {
      if (lastTokenRefreshTime == "Aktif") {
        updateTokenRefreshTime();
      }
      return token;
    }

    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      print("[SsoHelper] Token refresh already in progress. Waiting for existing request...");
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final newToken = await _performTokenRefresh(session);
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      print("[SsoHelper] Token refresh error: $e");
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  static Future<String?> _performTokenRefresh(Map<String, dynamic> session) async {
    final username = session['username'] as String?;
    final refreshToken = await LocalStorageMobile.read('refresh');

    if (refreshToken == null || refreshToken.isEmpty) {
      print("[SsoHelper] No refresh token found. Clearing session...");
      await clearSession();
      await FcmService.showCustomNotification(
        title: 'Sesi Berakhir',
        body: 'Sesi login telah kadaluarsa. Silakan login kembali.',
      );
      return null;
    }

    print("[SsoHelper] JWT Token expired. Attempting direct refresh via Golang API...");
    try {
      final response = await http
          .post(
            Uri.parse("${ApiClient.baseUrl}/api/account/refresh-token"),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Thunder Client (https://www.thunderclient.com)',
              'Accept': '*/*',
            },
            body: jsonEncode({"refresh_token": refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && responseData['token'] != null) {
          final newToken = responseData['token'] as String;
          final newRefresh = responseData['refresh'] as String? ?? refreshToken;

          await saveSession(
            username: username ?? '',
            password: session['password'] ?? '',
            token: newToken,
            name: session['name'] ?? '',
            nidn: session['nidn'] ?? '',
            nip: session['nip'] ?? '',
            email: session['email'] ?? '',
            role: session['role'] ?? 'Dosen',
            groups: List<String>.from(session['groups'] ?? []),
          );
          await LocalStorageMobile.write('refresh', newRefresh);

          await FcmService.showCustomNotification(
            title: 'Sesi Keamanan Diperbarui',
            body: 'Token JWT Anda berhasil diperbarui secara otomatis.',
          );
          updateTokenRefreshTime();
          print("[SsoHelper] Background token refresh SUCCESS via Golang API.");
          return newToken;
        }
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        print("[SsoHelper] Server rejected refresh token (${response.statusCode}). Force clearing session...");
        await clearSession();
        await FcmService.showCustomNotification(
          title: 'Sesi Berakhir',
          body: 'Sesi login telah kadaluarsa. Akun dan token telah dibersihkan secara aman dari DB lokal.',
        );
        return null;
      } else {
        print("[SsoHelper] Refresh request returned HTTP ${response.statusCode}. Preserving local session.");
        return session['token'] as String?;
      }
    } catch (e) {
      print("[SsoHelper] Network/timeout error during token refresh ($e). Preserving local session.");
      return session['token'] as String?;
    }
    return null;
  }

  static Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final payload = parts[1];
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveSession({
    required String username,
    required String password,
    required String token,
    required String name,
    required String nidn,
    required String nip,
    required String email,
    required String role,
    required List<String> groups,
  }) async {
    await SqliteAuthStorage.instance.saveSession(
      username: username,
      password: password,
      token: token,
      name: name,
      nidn: nidn,
      nip: nip,
      email: email,
      role: role,
      groups: groups,
    );
    await LocalStorageMobile.write('username', username);
    await LocalStorageMobile.write('password', password);
    await LocalStorageMobile.write('token', token);
    await LocalStorageMobile.write('name', name);
    await LocalStorageMobile.write('nidn', nidn);
    await LocalStorageMobile.write('nip', nip);
    await LocalStorageMobile.write('email', email);
    await LocalStorageMobile.write('role', role);
    await LocalStorageMobile.write('groups', jsonEncode(groups));
    updateTokenRefreshTime();
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final sqliteSession = await SqliteAuthStorage.instance.getSession();
    if (sqliteSession != null && (sqliteSession['token'] ?? '').isNotEmpty) {
      return sqliteSession;
    }

    final token = await LocalStorageMobile.read('token');
    if (token == null || token.isEmpty) return null;
    final username = await LocalStorageMobile.read('username') ?? '';
    final password = await LocalStorageMobile.read('password') ?? '';
    final name = await LocalStorageMobile.read('name') ?? '';
    final nidn = await LocalStorageMobile.read('nidn') ?? '';
    final nip = await LocalStorageMobile.read('nip') ?? '';
    final email = await LocalStorageMobile.read('email') ?? '';
    final role = await LocalStorageMobile.read('role') ?? '';
    final groupsRaw = await LocalStorageMobile.read('groups');
    List<String> groups = [];
    if (groupsRaw != null) {
      try {
        groups =
            (jsonDecode(groupsRaw) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return {
      'username': username,
      'password': password,
      'token': token,
      'name': name,
      'nip': nip,
      'nidn': nidn,
      'email': email,
      'role': role,
      'groups': groups,
    };
  }

  static Future<void> clearSession() async {
    await SqliteAuthStorage.instance.clearAll();
    await LocalStorageMobile.clear();
  }
}

class LocalStorageMobile {
  static Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File("${dir.path}/sso_storage.json");
  }

  static Future<void> write(String key, String value) async {
    try {
      final f = await _file;
      Map<String, dynamic> data = {};
      if (await f.exists()) {
        data = jsonDecode(await f.readAsString());
      }
      data[key] = value;
      await f.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Write Storage Error: $e");
    }
  }

  static Future<String?> read(String key) async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString());
        return data[key] as String?;
      }
    } catch (e) {
      print("Read Storage Error: $e");
    }
    return null;
  }

  static Future<void> clear() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      print("Clear Storage Error: $e");
    }
  }
}
