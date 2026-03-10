import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'api_config.dart';

// ─────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────

final userMemoryServiceProvider = Provider<UserMemoryService>((ref) {
  return UserMemoryService();
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref.read(userMemoryServiceProvider));
});

// ─────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final UserMemoryService _service;

  UserProfileNotifier(this._service) : super(UserProfile.empty()) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.loadProfile();
  }

  Future<void> updateFromConversation(
      String userMessage, String aiReply, String companionId) async {
    final updated = await _service.extractAndUpdateProfile(
        userMessage, aiReply, state, companionId);
    state = updated;
  }
}

// ─────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────

class UserMemoryService {
  static const String _profileKey = 'user_memory_profile';

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return UserProfile.empty();
    try {
      return UserProfile.fromJsonString(raw);
    } catch (e) {
      debugPrint('UserMemoryService: Failed to parse profile: $e');
      return UserProfile.empty();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJsonString());
  }

  /// Calls GPT to extract new facts and reconcile existing ones across both Active and Archive tiers.
  Future<UserProfile> extractAndUpdateProfile(
    String userMessage,
    String aiReply,
    UserProfile current,
    String companionId,
  ) async {
    if (!ApiConfig.hasApiKey) return current;

    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month}-${now.day}";
      
      final url = Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions');
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
                  '''You are a tiered memory reconciliation agent.
Current Date: $dateStr

USER MEMORY TIERS:
- ACTIVE: Recently mentioned or highly relevant facts (injected into current chat).
- ARCHIVE: Historical facts, stale goal/deadlines, or past context (stored but not in current chat).

CURRENT MEMORY:
Active:
${current.activeFacts.asMap().entries.map((e) => "- ${e.value.text}").join('\n')}
Archive:
${current.archivedFacts.asMap().entries.map((e) => "- ${e.value.text}").join('\n')}

INSTRUCTIONS:
1. RECONCILE: Review all facts against the latest conversation.
2. PROMOTE: Move a fact from Archive to Active if it is mentioned or becomes relevant again.
3. DEMOTE: Move a fact from Active to Archive if it is stale, a passed deadline, or less relevant right now.
4. EXTRACT: Add 1-3 new significant facts to Active.
5. OPPORTUNITIES: Identify 1 explicit check-in opportunity if a significant OR emotionally charged upcoming event is mentioned (e.g. big meeting, surgery, major trip). 
    - IGNORE routine/minor things (grocery shopping, gym).
    - If none, return empty list.

Output ONLY a JSON object with:
- "name": user's name (stay null if unknown)
- "active": FINAL list of up to 12 active facts (STRINGS).
- "archived": FINAL list of up to 40 archived facts (STRINGS).
- "check_ins": List of strings describing 1 significant check-in opportunity found in the latest turn (e.g. "Presentation on Friday").''' ,
            },
            {
              'role': 'user',
              'content': '''Latest turn:
User: "$userMessage"
AI: "$aiReply"''',
            },
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final delta = jsonDecode(content is String ? content : jsonEncode(content))
            as Map<String, dynamic>;
        
        final updated = current.merge(delta, companionId);
        
        final checkIns = delta['check_ins'];
        final hasCheckIns = checkIns is List && checkIns.isNotEmpty;
        
        // Save if anything changed
        if (updated.name != current.name || 
            updated.activeFacts.length != current.activeFacts.length ||
            updated.archivedFacts.length != current.archivedFacts.length ||
            hasCheckIns) {
          await saveProfile(updated);
          debugPrint('UserMemoryService: Tiered memory reconciled. Check-ins found: $checkIns');
        }
        return updated;
      }
    } catch (e) {
      debugPrint('UserMemoryService: Tiered extraction failed: $e');
    }

    return current;
  }
}
