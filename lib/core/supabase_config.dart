import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    // If keys are placeholders, skip initialization to avoid runtime errors
    if (url == 'YOUR_SUPABASE_URL' || anonKey == 'YOUR_SUPABASE_ANON_KEY') {
      debugPrint('Supabase keys not provided. Running in offline/mock mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }

  static bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }
}
