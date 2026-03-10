import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unauthenticated, authenticated, skipped }

final authServiceProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier() : super(AuthStatus.unauthenticated) {
    _init();
  }

  static const String _authStatusKey = 'auth_status';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final statusStr = prefs.getString(_authStatusKey);
    debugPrint('AuthService: Loading status from prefs: "$statusStr"');
    if (statusStr == 'authenticated') {
      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> setStatus(AuthStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('AuthService: Transitioning to status: ${status.name}');
    
    if (status == AuthStatus.authenticated) {
      await prefs.setString(_authStatusKey, status.name);
    } else {
      await prefs.remove(_authStatusKey);
    }
    state = status;
  }

  Future<void> login() async {
    await setStatus(AuthStatus.authenticated);
  }

  Future<void> skipAuth() async {
    await setStatus(AuthStatus.skipped);
  }

  Future<void> logout() async {
    await setStatus(AuthStatus.unauthenticated);
  }
}

class AuthService {
  // Legacy placeholder if needed, but we'll use AuthNotifier
}
