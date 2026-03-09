import 'package:flutter/foundation.dart';
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
    
    // Fallback to mock data if not initialized or offline
    if (client == null) {
      debugPrint('ContentService: Supabase not initialized. Using mock sessions.');
      return _getMockSessions();
    }

    try {
      final response = await client
          .from('meditation_sessions')
          .select()
          .order('created_at', ascending: false);
      
      final sessions = (response as List)
          .map((json) => MeditationSession.fromJson(json))
          .toList();
      
      if (sessions.isEmpty) return _getMockSessions();
      return sessions;
    } catch (e) {
      debugPrint('ContentService: Failed to fetch sessions from Supabase: $e');
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
        category: 'Focus',
        imageUrl: '',
        audioUrl: '', // Audio playback not fully implemented for mocks yet
        colors: ['#FFE0B2', '#FFCC80'],
      ),
      MeditationSession(
        id: 'mock-2',
        title: 'Deep Rest',
        description: 'Unwind your mind and body for deep sleep.',
        durationMinutes: 15,
        category: 'Sleep',
        imageUrl: '',
        audioUrl: '',
        colors: ['#C5CAE9', '#9FA8DA'],
      ),
      MeditationSession(
        id: 'mock-3',
        title: 'Anxiety SOS',
        description: 'Quick relief for overwhelming moments.',
        durationMinutes: 3,
        category: 'Relief',
        imageUrl: '',
        audioUrl: '',
        colors: ['#FFCDD2', '#EF9A9A'],
      ),
    ];
  }
}
