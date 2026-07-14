// ignore_for_file: avoid_web_libraries_in_flutter, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class SsoHelper {
  static const String _clientId = "unpak_link_gate";
  static const String _authUrl =
      "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/auth";
  static const String _tokenUrl =
      "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/token";
  static const String _logoutUrl =
      "https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/logout";

  static void redirectToSso() {
    final origin = html.window.location.origin;
    final redirectUri = Uri.encodeComponent("$origin/callback_sso");
    final url =
        "$_authUrl?client_id=$_clientId&redirect_uri=$redirectUri&response_type=code&scope=openid";
    print("SSO Redirecting to: $url");
    html.window.location.href = url;
  }

  static Future<Map<String, dynamic>?> loginWithSso() async {
    redirectToSso();
    return null;
  }

  static Future<String?> getLoggedInName() async {
    final idToken = html.window.localStorage['idToken'] ?? html.window.localStorage['token'];
    if (idToken != null) {
      final decoded = _decodeJwt(idToken);
      return decoded['name'] as String?;
    }
    return null;
  }

  static Future<void> printSsoTelemetry() async {
    try {
      final token = html.window.localStorage['token'];
      final refresh = html.window.localStorage['refresh'];
      final idToken = html.window.localStorage['idToken'];
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

  static Future<Map<String, dynamic>?> checkAndExchangeCode() async {
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];
    if (code == null) return null;

    print("SSO Callback detected. Code: $code");

    try {
      final origin = html.window.location.origin;
      final request = html.HttpRequest();
      request.open('POST', _tokenUrl);
      request.setRequestHeader(
          'Content-Type', 'application/x-www-form-urlencoded');

      final body =
          "grant_type=authorization_code&client_id=$_clientId&code=$code&redirect_uri=${Uri.encodeComponent("$origin/callback_sso")}";
      print("SSO Exchanging token via POST to $_tokenUrl with body: $body");
      request.send(body);

      await request.onLoad.first;
      print("SSO Response Status: ${request.status}");
      print("SSO Response Text: ${request.responseText}");

      if (request.status == 200) {
        final response =
            jsonDecode(request.responseText ?? '{}') as Map<String, dynamic>;
        final accessToken = response['access_token'] as String?;
        final refreshToken = response['refresh_token'] as String?;
        final idToken = response['id_token'] as String?;

        if (accessToken != null) {
          html.window.localStorage['token'] = accessToken;
          if (refreshToken != null) {
            html.window.localStorage['refresh'] = refreshToken;
          }
          if (idToken != null) html.window.localStorage['idToken'] = idToken;

          // Clear query params from browser address bar
          html.window.history.replaceState({}, '', origin);

          // Decode ID Token or Access Token to extract name and level/role
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

          return {
            "name": name,
            "level": level,
            "token": accessToken,
          };
        }
      }
    } catch (e) {
      print("SSO Exchange Exception: $e");
    }

    return null;
  }

  static Future<void> logout() async {
    final refreshToken = html.window.localStorage['refresh'];
    html.window.localStorage.remove('token');
    html.window.localStorage.remove('refresh');
    html.window.localStorage.remove('idToken');
    html.window.localStorage.remove('info');

    if (refreshToken != null) {
      try {
        final request = html.HttpRequest();
        request.open('POST', _logoutUrl);
        request.setRequestHeader(
            'Content-Type', 'application/x-www-form-urlencoded');
        final body =
            "client_id=$_clientId&refresh_token=${Uri.encodeComponent(refreshToken)}";
        request.send(body);
        await request.onLoad.first;
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
    final token = html.window.localStorage['token'];
    final refresh = html.window.localStorage['refresh'];
    
    if (token == null) return null;
    
    if (_isTokenExpired(token)) {
      if (refresh != null) {
        print("Token expired. Attempting to refresh token via API...");
        try {
          final request = html.HttpRequest();
          request.open('POST', _tokenUrl, async: false);
          request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
          final body = "grant_type=refresh_token&client_id=$_clientId&refresh_token=${Uri.encodeComponent(refresh)}";
          request.send(body);
          
          if (request.status == 200) {
            final response = jsonDecode(request.responseText ?? '{}') as Map<String, dynamic>;
            final newAccessToken = response['access_token'] as String?;
            final newRefreshToken = response['refresh_token'] as String?;
            if (newAccessToken != null) {
              html.window.localStorage['token'] = newAccessToken;
              if (newRefreshToken != null) {
                html.window.localStorage['refresh'] = newRefreshToken;
              }
              print("Token refreshed successfully.");
              return newAccessToken;
            }
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

  static void initDeepLinkListener(void Function(Map<String, dynamic>) onLoginSuccess) {}
  static void disposeListener() {}
}
