import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:hrportalv2/core/api_client.dart';
import '../../../core/sso_helper.dart';
import '../domain/auth.dart';
import '../domain/auth_errors.dart';
import '../domain/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  @override
  Future<AuthSession?> login(String username, String password) async {
    try {
      final responseData = await ApiClient.post(
        Uri.parse("${ApiClient.baseUrl}/api/account/login"),
        body: {
          "username": username,
          "password": password,
        },
      );

      if (responseData is Map<String, dynamic> && responseData['token'] != null) {
        final token = responseData['token'] as String;

        // Fetch user info from /api/account/whoami using the token
        final whoamiData = await ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/account/whoami"),
          headers: {
            "Authorization": "Bearer $token",
          },
        );

        if (whoamiData is Map<String, dynamic>) {
          final name = whoamiData['nama'] ?? whoamiData['name'] ?? 'User';
          final nip = whoamiData['nip'] ?? '';
          final email = whoamiData['email'] ?? '';
          final nidn = whoamiData['nidn'] ?? '';

          final level = (whoamiData['level'] ?? whoamiData['role'] ?? '').toString();
          final resolvedRole = level.isNotEmpty ? level : (nidn.isNotEmpty ? 'Dosen' : 'Tendik');
          final groups = level.isNotEmpty ? [level] : (resolvedRole == 'Dosen' ? ['Dosen'] : ['Tendik']);

          await SsoHelper.saveSession(
            token: token,
            name: name,
            nip: nip,
            email: email,
            role: resolvedRole,
            groups: groups,
          );

          return AuthSession(
            name: name,
            nip: nip,
            email: email,
            role: resolvedRole,
            groups: groups,
            token: token,
          );
        } else {
          throw const InvalidCredentialsError();
        }
      } else {
        throw const InvalidCredentialsError();
      }
    } on ApiException catch (e, stackTrace) {
      debugPrint('[AuthRepository API Exception]: ${e.message}\n$stackTrace');
      throw const NetworkError();
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository Unhandled Error]: $e\n$stackTrace');
      if (e is AuthError) rethrow;
      throw const InvalidCredentialsError();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await SsoHelper.clearSession();
    } catch (e, stackTrace) {
      debugPrint("[AuthRepository logout error]: $e\n$stackTrace");
      throw const NetworkError();
    }
  }

  @override
  Future<AuthSession?> checkValidSession() async {
    try {
      final sessionData = await SsoHelper.getSession();
      if (sessionData != null) {
        return AuthSession(
          name: sessionData['name'] ?? '',
          nip: sessionData['nip'] ?? '',
          email: sessionData['email'] ?? '',
          role: sessionData['role'] ?? '',
          groups: sessionData['groups'] != null
              ? (sessionData['groups'] as List).map((e) => e.toString()).toList()
              : [],
          token: sessionData['token'] ?? '',
        );
      } else {
        throw const UnauthorizedError();
      }
    } catch (e, stackTrace) {
      debugPrint("[AuthRepository checkValidSession error]: $e\n$stackTrace");
      if (e is AuthError) rethrow;
      throw const UnauthorizedError();
    }
  }

  @override
  Future<bool> checkPermissionsGranted() async {
    bool hasLoc = false;
    bool hasCam = false;

    try {
      final locPermission = await Geolocator.checkPermission();
      hasLoc = locPermission == LocationPermission.always || 
               locPermission == LocationPermission.whileInUse;
    } catch (e, stackTrace) {
      debugPrint("[AuthRepository checkPermissions location error]: $e\n$stackTrace");
      hasLoc = false;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras.first, ResolutionPreset.low);
        await controller.initialize();
        await controller.dispose();
        hasCam = true;
      }
    } catch (e, stackTrace) {
      debugPrint("[AuthRepository checkPermissions camera error]: $e\n$stackTrace");
      if (e is CameraException && e.code == 'cameraPermission') {
        hasCam = false;
      } else {
        hasCam = true; // granted but busy
      }
    }

    return hasLoc && hasCam;
  }

  @override
  Future<bool> requestPermissions() async {
    bool locOk = false;
    bool camOk = false;

    try {
      final locPermission = await Geolocator.requestPermission();
      locOk = locPermission == LocationPermission.always || 
              locPermission == LocationPermission.whileInUse;
      if (!locOk) {
        ApiClient.showToast(PermissionDeniedError('Lokasi (GPS)').message);
      }
    } catch (e, stackTrace) {
      debugPrint("[AuthRepository requestPermissions location error]: $e\n$stackTrace");
      locOk = false;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras.first, ResolutionPreset.low);
        await controller.initialize();
        await controller.dispose();
        camOk = true;
      }
    } catch (e, stackTrace) {
      debugPrint("[AuthRepository requestPermissions camera error]: $e\n$stackTrace");
      ApiClient.showToast(PermissionDeniedError('Kamera').message);
      camOk = false;
    }

    return locOk && camOk;
  }

}
