import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../models/chat_message.dart';
import '../../models/companion_persona.dart';
import '../../models/user_profile.dart';
import 'sentiment_service.dart';
import 'local_chat_repository.dart';
import 'user_memory_service.dart';
import 'notification_service.dart';
import '../../providers/mood_provider.dart';
import '../../providers/history_provider.dart';
import '../../models/emotional_snapshot.dart';

// Provides suggested topics to start a conversation with a specific persona
final starterChipsProvider = FutureProvider.family<List<String>, String>((ref, companionId) async {
  final persona = CompanionPersona.all.firstWhere(
    (p) => p.id == companionId,
    orElse: () => CompanionPersona.maya,
  );
  
  // Simulated delay for "AI thinking"
  await Future.delayed(const Duration(milliseconds: 500));
  
  switch (persona.role) {
    case 'The Motivation Coach':
      return ["How do I stay consistent?", "Help me plan my day", "I'm feeling discouraged"];
    case 'The Mindfulness Guide':
      return ["Guided breathing", "Dealing with stress", "Finding peace"];
    case 'The Career Mentor':
      return ["Negotiating a raise", "Conflict with a coworker", "Career pivot advice"];
    case 'The Relationship Advisor':
      return ["Communication tips", "Setting boundaries", "First date jitters"];
    default:
      return ["How are you?", "What's on your mind?", "Tell me a story"];
  }
});
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, List<ChatMessage>, String>((ref, companionId) {
  return ChatMessagesNotifier(
    companionId,
    ref,
    ref.read(sentimentServiceProvider),
    ref.read(localChatRepositoryProvider),
  );
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String companionId;
  final Ref _ref;
  final SentimentService _sentimentService;
  final LocalChatRepository _chatRepository;

  ChatMessagesNotifier(this.companionId, this._ref, this._sentimentService, this._chatRepository) : super([]) {
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    // 1. Try to load existing history
    final history = await _chatRepository.loadMessages(companionId);

    if (history.isNotEmpty) {
      state = history;
      return;
    }

    // 2. Fallback to companion-specific greeting if no history exists
    state = [
      ChatMessage(
        id: 'init_$companionId',
        companionId: companionId,
        sender: MessageSender.ai,
        text: _getGreetingForPersona(companionId),
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];

    await _chatRepository.saveMessages(companionId, state);
  }

  String _getGreetingForPersona(String id) {
    final persona = CompanionPersona.all.firstWhere(
      (p) => p.id == id,
      orElse: () => CompanionPersona.maya,
    );
    switch (persona.role) {
      case 'The Motivation Coach':
        return "Hey! Ready to crush some goals today? What's on your mind?";
      case 'The Mindfulness Guide':
        return "Welcome. Take a breath. How is your spirit feeling in this moment?";
      case 'The Career Mentor':
        return "Good to see you. What's on your professional radar today?";
      case 'The Relationship Advisor':
        return "Hi there. I'm all ears. What's been going on in your world?";
      case 'The Fitness Coach':
        return "Hey! How's the body feeling today? Ready to build some good habits?";
      case 'The Sparring Partner':
        return "Great, you're here! I've been thinking — got something to debate?";
      default: // Best Friend
        return "Hey! So good to hear from you. What's going on?";
    }
  }

  Future<void> sendMessage(String text, CompanionPersona persona) async {
    // 1. Add User Message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companionId: companionId,
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // 2. Read memory and current mood to enrich the AI context
    final UserProfile userProfile = _ref.read(userProfileProvider);
    
    // 2b. Real-time mood detection and snapshot creation (Phase 29)
    try {
      final analysis = await _sentimentService.analyzeText(text);
      final snapshot = EmotionalSnapshot(
        id: DateTime.now().toIso8601String(),
        timestamp: DateTime.now(),
        mood: analysis['mood'] ?? 'Calmness',
        transcript: text,
        sentimentScores: Map<String, double>.from(analysis['scores'] ?? {}),
        moodDistribution: Map<String, double>.from(analysis['moodDistribution'] ?? {}),
        companionResponse: analysis['response'],
        isJournalEntry: false,
      );

      // Add to history (this also triggers weather updates)
      await _ref.read(historyProvider.notifier).addSnapshot(snapshot);
      
      // Update current mood for immediate chat tone adjustment
      _ref.read(moodProvider.notifier).state = snapshot.mood;
    } catch (e) {
      debugPrint('ChatService: Sentiment analysis failed: $e');
    }
    
    final String currentMood = _ref.read(moodProvider);

    // 3. Send to OpenAI with full context (persona + memory + mood)
    final responseText = await _sentimentService.generateChatResponse(
      persona: persona,
      history: state,
      userProfile: userProfile.isEmpty ? null : userProfile,
      currentMood: currentMood == 'neutral' ? null : currentMood,
    );

    String cleanedResponse = responseText;
    final scheduleRegex = RegExp(r'\[SCHEDULE_NOTIF:\s*([^\]]+)\]');
    final match = scheduleRegex.firstMatch(responseText);
    
    if (match != null) {
      final isoString = match.group(1)?.trim();
      if (isoString != null) {
        try {
          final scheduledTime = DateTime.parse(isoString);
          cleanedResponse = responseText.replaceFirst(match.group(0)!, '').trim();
          
          // Schedule the notification
          NotificationService().schedulePersonaCheckIn(
            personaName: persona.name,
            scheduledTime: scheduledTime,
            context: "You asked me to follow up with you around now",
          );
        } catch (e) {
          debugPrint('ChatService: Failed to parse schedule date: $isoString');
        }
      }
    }

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      companionId: companionId,
      sender: MessageSender.ai,
      text: cleanedResponse,
      timestamp: DateTime.now(),
    );

    state = [...state, aiMsg];

    // 4. Persist the updated conversation
    await _chatRepository.saveMessages(companionId, state);

    // 5. Extract & update long-term memory in the background (non-blocking)
    _ref.read(userProfileProvider.notifier).updateFromConversation(text, responseText, companionId);
  }
}

