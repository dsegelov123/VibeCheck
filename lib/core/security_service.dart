import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityServiceProvider = Provider<SecurityService>((ref) => SecurityService());

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _securityEnabledKey = 'security_enabled';

  /// Returns true if the user has opted into native security.
  Future<bool> isSecurityEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_securityEnabledKey) ?? false;
  }

  /// Enables or disables native security based on user preference.
  Future<void> setSecurityEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_securityEnabledKey, enabled);
  }

  /// Checks if the device supports biometrics or passcode.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('SecurityService: Error checking biometrics: $e');
      return false;
    }
  }

  /// Triggers the native biometric/passcode prompt.
  /// Returns true if authentication succeeded.
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock VibeCheck',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows fallback to passcode
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('SecurityService: Authentication error: $e');
      return false;
    }
  }
}
