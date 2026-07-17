import 'auth.dart';

abstract class IAuthRepository {
  Future<AuthSession?> login(String username, String password);
  Future<void> logout();
  Future<AuthSession?> checkValidSession();
  Future<bool> checkPermissionsGranted();
  Future<bool> requestPermissions();
}
