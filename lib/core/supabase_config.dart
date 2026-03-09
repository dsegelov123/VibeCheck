import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://ifvmtbtnybrmkoaazfto.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlmdm10YnRueWJybWtvYWF6ZnRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzExNjksImV4cCI6MjA4ODY0NzE2OX0.-m613mRExKVAq2-GOVfiJWx5JMVU8wltWGBU4fX88WU';

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
