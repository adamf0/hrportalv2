import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/mediator/mediator.dart';
import '../application/check_token/check_token_query.dart';
import '../application/login/login_command.dart';
import '../application/logout/logout_command.dart';
import '../application/permissions/check_permissions_query.dart';
import '../application/permissions/request_permissions_command.dart';
import '../../../../core/sso_helper.dart';
import '../domain/auth.dart';

class AuthBloc extends ChangeNotifier {
  final Mediator _mediator = Mediator();

  AuthSession? _session;
  AuthSession? get session => _session;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isLoggedIn => _session != null;

  bool _isPermissionsGranted = false;
  bool get isPermissionsGranted => _isPermissionsGranted;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Timer? _tokenRefreshTimer;

  AuthBloc() {
    _startTokenRefreshTimer();
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> checkSessionAndPermissions() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _session = await _mediator.send(CheckTokenQuery());
      _isPermissionsGranted = await _mediator.send(CheckPermissionsQuery());
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final sessionResult = await _mediator.send(
        LoginCommand(username: username, password: password),
      );
      if (sessionResult != null) {
        _session = sessionResult;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Gagal masuk via SSO.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> loginWithSso() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final ssoData = await SsoHelper.loginWithSso();
      if (ssoData != null) {
        final sessionData = await SsoHelper.getSession();
        if (sessionData != null) {
          _session = AuthSession(
            name: sessionData['name'] ?? '',
            nip: sessionData['nip'] ?? '',
            email: sessionData['email'] ?? '',
            role: sessionData['role'] ?? '',
            groups: sessionData['groups'] != null
                ? (sessionData['groups'] as List).map((e) => e.toString()).toList()
                : [],
            token: sessionData['token'] ?? '',
          );
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Gagal masuk via SSO.';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _mediator.send(LogoutCommand());
      _session = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPermissions() async {
    try {
      _isPermissionsGranted = await _mediator.send(CheckPermissionsQuery());
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> requestAllPermissions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final granted = await _mediator.send(RequestPermissionsCommand());
      _isPermissionsGranted = granted;
      notifyListeners();
      return granted;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (isLoggedIn) {
        try {
          final activeSession = await _mediator.send(CheckTokenQuery());
          if (activeSession == null) {
            await logout();
          }
        } catch (_) {
          await logout();
        }
      }
    });
  }
}
