// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:path_provider/path_provider.dart';
import 'sqlite_auth_storage.dart';
import 'fcm_service.dart';
import 'api_client.dart';

class SsoHelper {
  static const String _clientId = "unpak_link_gate";
  static const String _logoutUrl =
      "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/logout";

  static const _appAuth = FlutterAppAuth();

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
        final nip = decoded['preferred_username'] ?? "";
        final groups = (decoded['group'] as List?) ?? [];

        String level = "Dosen";
        if (groups.contains("adm_pusat")) {
          level = "Admin";
        } else if (groups.contains("Mahasiswa")) {
          level = "Mahasiswa";
        } else if (groups.contains("Dosen")) {
          level = "Dosen";
        } else if (groups.contains("Tendik")) {
          level = "Tendik";
        }

        await saveSession(
          username: nip,
          password: "",
          token: accessToken,
          name: name,
          nip: nip,
          email: email,
          role: level,
          groups: [level],
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

    if (_isTokenExpired(token)) {
      final username = session['username'] as String?;
      final password = session['password'] as String?;

      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        print("JWT Token expired. Attempting background re-login via SQLite credentials...");
        try {
          final responseData = await ApiClient.post(
            Uri.parse("${ApiClient.baseUrlUnpak}/account/login"),
            body: {
              "username": username,
              "password": password,
            },
          );

          if (responseData is Map<String, dynamic> &&
              responseData['token'] != null) {
            final newToken = responseData['token'] as String;

            final whoamiData = await ApiClient.get(
              Uri.parse("${ApiClient.baseUrlUnpak}/account/whoami"),
              headers: {"Authorization": "Bearer $newToken"},
            );

            if (whoamiData is Map<String, dynamic>) {
              final name = whoamiData['nama'] ?? whoamiData['name'] ?? session['name'];
              final nip = whoamiData['nip'] ?? session['nip'];
              final email = whoamiData['email'] ?? session['email'];
              final role = session['role'] as String? ?? 'Dosen';
              final groups = List<String>.from(session['groups'] ?? []);

              await saveSession(
                username: username,
                password: password,
                token: newToken,
                name: name,
                nip: nip,
                email: email,
                role: role,
                groups: groups,
              );

              await FcmService.showCustomNotification(
                title: 'Sesi Keamanan Diperbarui',
                body: 'Token JWT Anda berhasil diperbarui secara otomatis di latar belakang.',
              );

              print("Background token refresh SUCCESS.");
              return newToken;
            }
          }
        } catch (e) {
          print("Background token refresh failed: $e");
        }
      }

      // Re-login failed or no stored password
      await clearSession();
      await FcmService.showCustomNotification(
        title: 'Sesi Berakhir',
        body: 'Token JWT telah kadaluarsa. Silakan login kembali ke HR Portal.',
      );
      return null;
    }

    return token;
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
      nip: nip,
      email: email,
      role: role,
      groups: groups,
    );
    await LocalStorageMobile.write('username', username);
    await LocalStorageMobile.write('password', password);
    await LocalStorageMobile.write('token', token);
    await LocalStorageMobile.write('name', name);
    await LocalStorageMobile.write('nip', nip);
    await LocalStorageMobile.write('email', email);
    await LocalStorageMobile.write('role', role);
    await LocalStorageMobile.write('groups', jsonEncode(groups));
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
