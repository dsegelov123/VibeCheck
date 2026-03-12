import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'providers/mood_provider.dart';
import 'features/home/dashboard_view.dart';
import 'core/supabase_config.dart';
import 'core/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/onboarding_view.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/security_lock_screen.dart';
import 'core/subscription_service.dart';
import 'core/auth_service.dart';
import 'core/security_service.dart';

import 'core/providers.dart';
import 'features/navigation/main_navigation_wrapper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
    await NotificationService().init();

    runApp(
    const ProviderScope(
      child: VibeCheckApp(),
    ),
  );
  } catch (e, stack) {
    debugPrint('VibeCheck: CRITICAL STARTUP ERROR: $e');
    debugPrint('VibeCheck: STACK TRACE: $stack');
    rethrow;
  }
}

class VibeCheckApp extends ConsumerWidget {
  const VibeCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize RevenueCat here
    ref.read(subscriptionServiceProvider).init();
    
    final onboardingDone = ref.watch(onboardingProvider);
    final authState = ref.watch(authServiceProvider);

    Widget home;
    if (onboardingDone) {
      debugPrint('VibeCheckApp: Rendering OnboardingView');
      home = const OnboardingView();
    } else {
      if (authState == AuthStatus.unauthenticated) {
        debugPrint('VibeCheckApp: Rendering AuthScreen');
        home = const AuthScreen();
      } else {
        debugPrint('VibeCheckApp: Rendering MainNavigationWrapper (Status: ${authState.name})');
        home = MainNavigationWrapper();
      }
    }

    return MaterialApp(
      title: 'VibeCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: home,
    );
  }
}


