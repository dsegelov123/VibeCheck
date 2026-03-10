import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emotional_snapshot.dart';

import 'supabase_config.dart';

class MemoryService {
  SupabaseClient? get _client {
    if (SupabaseConfig.isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  Future<void> saveSnapshot(EmotionalSnapshot snapshot) async {
    final client = _client;
    if (client == null) {
      print('MemoryService: Supabase not initialized. Skipping save.');
      return;
    }
    try {
      await client
          .from('emotional_snapshots')
          .insert(snapshot.toJson());
    } catch (e) {
      print('Failed to save snapshot: $e');
      // Fallback: Local persistence logic could go here
    }
  }

  Future<List<EmotionalSnapshot>> getHistory() async {
    final client = _client;
    
    List<EmotionalSnapshot> history = [];
    if (client != null) {
      try {
        final response = await client
            .from('emotional_snapshots')
            .select()
            .order('timestamp', ascending: false);
        
        if (response is List) {
          history = response
              .whereType<Map<String, dynamic>>()
              .map((json) => EmotionalSnapshot.fromJson(json))
              .toList();
        }
      } catch (e) {
        print('Failed to fetch history: $e');
      }
    }

    // Prototype Fallback: If history is empty (or no client), provide rich mock data
    if (history.isEmpty) {
      history = _getMockHistory();
    }
    
    return history;
  }

  List<EmotionalSnapshot> _getMockHistory() {
    final now = DateTime.now();
    return [
      EmotionalSnapshot(
        id: 'mock-1',
        timestamp: now.subtract(const Duration(hours: 2)),
        mood: 'calm',
        transcript: "The morning walk in the park was incredibly grounding. I feel ready for the week.",
        companionResponse: "That sounds so grounding. Nature has a wonderful way of helping us reset.",
      ),
      EmotionalSnapshot(
        id: 'mock-2',
        timestamp: now.subtract(const Duration(days: 1, hours: 4)),
        mood: 'joy',
        transcript: "So grateful for the surprise visit! It reminded me how important community is.",
        companionResponse: "Community is truly a gift. I'm glad you had that joyful connection.",
      ),
      EmotionalSnapshot(
        id: 'mock-3',
        timestamp: now.subtract(const Duration(days: 2, hours: 1)),
        mood: 'anxious',
        transcript: "The deadline is looming. I need to break this down into smaller steps to stay focused.",
        companionResponse: "Deadlines can be overwhelming. Taking it one small step at a time is a great strategy.",
      ),
      EmotionalSnapshot(
        id: 'mock-4',
        timestamp: now.subtract(const Duration(days: 3, hours: 6)),
        mood: 'sad',
        transcript: "A bit of a lonely evening. Listening to some slow jazz to help process the quiet.",
        companionResponse: "It's okay to feel lonely sometimes. I'm here holding space for you.",
      ),
    ];
  }

  /// Vector search for similar emotional states (Conceptual)
  Future<List<EmotionalSnapshot>> findSimilarVibes(List<double> vector) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc('match_snapshots', params: {
        'query_embedding': vector,
        'match_threshold': 0.70, // 0 to 1, higher means stricter match
        'match_count': 3,
      });

      if (response is List) {
        return response.whereType<Map<String, dynamic>>().map((json) {
          return EmotionalSnapshot(
            id: json['id']?.toString() ?? '',
            timestamp: DateTime.now(), // We don't query timestamp in the RPC back, just the context
            transcript: json['transcript']?.toString(),
            mood: json['mood']?.toString() ?? 'calm',
            companionResponse: json['companion_response']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('MemoryService: Failed to find similar vibes: $e');
      return [];
    }
  }
}
