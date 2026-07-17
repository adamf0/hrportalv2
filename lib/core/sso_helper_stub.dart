// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:path_provider/path_provider.dart';

class SsoHelper {
  static const String _clientId = "unpak_link_gate";
  static const String _logoutUrl = "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/logout";
  
  static const _appAuth = FlutterAppAuth();

  static Future<String?> getLoggedInName() async {
    return await LocalStorageMobile.read('name');
  }

  static Future<void> printSsoTelemetry() async {
    try {
      final token = await LocalStorageMobile.read('token');
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
          "com.sipaksi.sipaksiv2:/oauth2redirect",
          issuer: "https://gerbang.unpak.ac.id/realms/gateway",
          scopes: ['openid', 'profile', 'email'],
        ),
      );

      if (result.accessToken != null) {
        final accessToken = result.accessToken!;
        final refreshToken = result.refreshToken;
        final idToken = result.idToken;

        await LocalStorageMobile.write('token', accessToken);
        if (refreshToken != null) await LocalStorageMobile.write('refresh', refreshToken);
        if (idToken != null) await LocalStorageMobile.write('idToken', idToken);

        final decoded = _decodeJwt(idToken ?? accessToken);
        final name = decoded['name'] ?? "User";
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

        await LocalStorageMobile.write('name', name);
        await LocalStorageMobile.write('level', level);

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
    await LocalStorageMobile.clear();

    if (refreshToken != null) {
      try {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse(_logoutUrl));
        request.headers.set('content-type', 'application/x-www-form-urlencoded');
        final body = "client_id=$_clientId&refresh_token=${Uri.encodeComponent(refreshToken)}";
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
    final token = await LocalStorageMobile.read('token');
    final refresh = await LocalStorageMobile.read('refresh');
    
    if (token == null) return null;
    
    if (_isTokenExpired(token)) {
      if (refresh != null) {
        print("Token expired. Attempting to refresh token...");
        try {
          final result = await _appAuth.token(
            TokenRequest(
              _clientId,
              "com.sipaksi.sipaksiv2:/oauth2redirect",
              issuer: "https://gerbang.unpak.ac.id/realms/gateway",
              refreshToken: refresh,
              scopes: ['openid', 'profile', 'email'],
            ),
          );
          if (result.accessToken != null) {
            await LocalStorageMobile.write('token', result.accessToken!);
            if (result.refreshToken != null) {
              await LocalStorageMobile.write('refresh', result.refreshToken!);
            }
            print("Token refreshed successfully.");
            return result.accessToken;
          }
        } catch (e) {
          print("Failed to refresh token: $e");
        }
      }
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
    required String token,
    required String name,
    required String nip,
    required String email,
    required String role,
    required List<String> groups,
  }) async {
    await LocalStorageMobile.write('token', token);
    await LocalStorageMobile.write('name', name);
    await LocalStorageMobile.write('nip', nip);
    await LocalStorageMobile.write('email', email);
    await LocalStorageMobile.write('role', role);
    await LocalStorageMobile.write('groups', jsonEncode(groups));
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final token = await LocalStorageMobile.read('token');
    if (token == null) return null;
    final name = await LocalStorageMobile.read('name') ?? '';
    final nip = await LocalStorageMobile.read('nip') ?? '';
    final email = await LocalStorageMobile.read('email') ?? '';
    final role = await LocalStorageMobile.read('role') ?? '';
    final groupsRaw = await LocalStorageMobile.read('groups');
    List<String> groups = [];
    if (groupsRaw != null) {
      try {
        groups = (jsonDecode(groupsRaw) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return {
      'token': token,
      'name': name,
      'nip': nip,
      'email': email,
      'role': role,
      'groups': groups,
    };
  }

  static Future<void> clearSession() async {
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
