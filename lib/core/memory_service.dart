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
        
        history = (response as List)
            .map((json) => EmotionalSnapshot.fromJson(json))
            .toList();
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
    // This would call a RPC function in Supabase for pgvector matching
    return [];
  }
}
