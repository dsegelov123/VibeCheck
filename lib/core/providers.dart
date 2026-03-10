import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) => OnboardingNotifier());

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = !(prefs.getBool('has_completed_onboarding') ?? false);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    state = false;
  }
}
