import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meditation_session.dart';
import 'supabase_config.dart';

class ContentService {
  SupabaseClient? get _client {
    if (SupabaseConfig.isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  Future<List<MeditationSession>> fetchSessions() async {
    final client = _client;

    // Always load the asset bundle first
    final assetSessions = await _loadFromAsset();

    // Then try Supabase — only use it if it has MORE sessions than the asset bundle
    if (client != null) {
      try {
        final response = await client
            .from('meditation_sessions')
            .select()
            .order('created_at', ascending: false);

        final supabaseSessions = (response as List)
            .map((json) => MeditationSession.fromJson(json))
            .toList();

        if (supabaseSessions.length > assetSessions.length) {
          debugPrint('ContentService: Using ${supabaseSessions.length} sessions from Supabase.');
          return supabaseSessions;
        }
      } catch (e) {
        debugPrint('ContentService: Supabase fetch failed: $e. Using asset bundle.');
      }
    }

    return assetSessions;
  }

  Future<List<MeditationSession>> _loadFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString('assets/sessions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final sessions = jsonList.map((json) => MeditationSession.fromJson(json)).toList();
      debugPrint('ContentService: Loaded ${sessions.length} sessions from asset bundle.');
      return sessions;
    } catch (e) {
      debugPrint('ContentService: Asset bundle load failed: $e. Using minimal mock data.');
      return _getMockSessions();
    }
  }

  List<MeditationSession> _getMockSessions() {
    return [
      MeditationSession(
        id: 'mock-1',
        title: 'Morning Clarity',
        description: 'Start your day with purpose and focused breath.',
        durationMinutes: 5,
        category: 'Morning Ritual',
        imageUrl: '',
        audioUrl: '',
        colors: ['#FFF9C4', '#FFD54F'],
      ),
      MeditationSession(
        id: 'mock-2',
        title: 'Deep Rest',
        description: 'Unwind your mind and body for deep sleep.',
        durationMinutes: 15,
        category: 'Sleep',
        imageUrl: '',
        audioUrl: '',
        colors: ['#C5CAE9', '#7986CB'],
      ),
      MeditationSession(
        id: 'mock-3',
        title: 'Anxiety SOS',
        description: 'Quick relief for overwhelming moments.',
        durationMinutes: 3,
        category: 'Anxiety SOS',
        imageUrl: '',
        audioUrl: '',
        colors: ['#FFCCBC', '#FF8A65'],
      ),
    ];
  }
}
