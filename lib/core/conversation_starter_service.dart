import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/companion_persona.dart';
import '../models/user_profile.dart';
import 'api_config.dart';
import 'user_memory_service.dart';
import '../providers/mood_provider.dart';

// ─────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────

/// Returns 3 conversation starter strings for a given companionId.
/// Re-runs whenever the profile or mood changes.
final starterChipsProvider = FutureProvider.family<List<String>, String>(
  (ref, companionId) async {
    final service = ref.read(conversationStarterServiceProvider);
    final persona = CompanionPersona.all.firstWhere(
      (p) => p.id == companionId,
      orElse: () => CompanionPersona.maya,
    );
    final profile = ref.watch(userProfileProvider);
    final mood = ref.watch(moodProvider);

    return service.generateStarters(
      persona: persona,
      userProfile: profile.isEmpty ? null : profile,
      currentMood: mood == 'neutral' ? null : mood,
    );
  },
);

final conversationStarterServiceProvider =
    Provider<ConversationStarterService>((ref) {
  return ConversationStarterService();
});

// ─────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────

class ConversationStarterService {
  /// Generates 3 short conversation starter suggestions.
  Future<List<String>> generateStarters({
    required CompanionPersona persona,
    UserProfile? userProfile,
    String? currentMood,
  }) async {
    if (!ApiConfig.hasApiKey) {
      return _fallbackStarters(persona);
    }

    try {
      final url = Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions');

      String contextBlock = '';
      if (userProfile != null && !userProfile.isEmpty) {
        contextBlock += 'User profile:\n';
        if (userProfile.name != null) contextBlock += 'Name: ${userProfile.name}.\n';
        final memoryFacts = userProfile.activeFacts.isNotEmpty
            ? userProfile.activeFacts.map((f) => "- ${f.text}").join('\n')
            : "None";
        contextBlock += 'Known facts:\n$memoryFacts\n';
      }
      if (currentMood != null) {
        contextBlock += 'User\'s current mood: $currentMood.\n';
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are generating 3 short, natural conversation opener suggestions that a user might say to their AI companion.
Companion persona: ${persona.name} — ${persona.role}. ${persona.description}
${contextBlock}
Rules:
- Output ONLY a JSON object with a "starters" array of exactly 3 strings.
- Each starter must be ≤ 8 words.
- Write from the user's perspective (first-person).
- Make them feel warm, personal, and relevant to the companion's expertise.
- Vary the mood of the starters (one light, one medium, one deeper).''',
            },
            {
              'role': 'user',
              'content': 'Generate 3 conversation starters.',
            },
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final parsed = jsonDecode(content is String ? content : jsonEncode(content))
            as Map<String, dynamic>;
        final startersRaw = parsed['starters'];
        final List<String> starters = (startersRaw is List)
            ? startersRaw.map((s) => s.toString()).take(3).toList()
            : [];
        return starters;
      }
    } catch (e) {
      debugPrint('ConversationStarterService: Generation failed: $e');
    }

    return _fallbackStarters(persona);
  }

  List<String> _fallbackStarters(CompanionPersona persona) {
    switch (persona.role) {
      case 'The Motivation Coach':
        return ['I need a push today', 'Help me set a goal', 'I\'ve been slacking lately'];
      case 'The Mindfulness Guide':
        return ['I feel overwhelmed right now', 'Help me slow down', 'I need to breathe'];
      case 'The Career Mentor':
        return ['I have a work dilemma', 'Should I ask for a raise?', 'I\'m stuck in my career'];
      case 'The Relationship Advisor':
        return ['I had an argument today', 'I need relationship advice', 'Something\'s feeling off'];
      case 'The Fitness Coach':
        return ['Help me build a routine', 'I skipped the gym again', 'How do I sleep better?'];
      case 'The Sparring Partner':
        return ['Let\'s debate something', 'Got a wild idea to share', 'Challenge my thinking'];
      default: // Best Friend
        return ['How are you today?', 'I just need to vent', 'Something happened today'];
    }
  }
}
