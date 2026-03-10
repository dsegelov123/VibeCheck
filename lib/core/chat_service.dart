import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../../models/companion_persona.dart';
import 'sentiment_service.dart';
import 'local_chat_repository.dart';

// Provides the list of chat messages for a specific companion
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, List<ChatMessage>, String>((ref, companionId) {
  return ChatMessagesNotifier(
    companionId, 
    ref.read(sentimentServiceProvider),
    ref.read(localChatRepositoryProvider),
  );
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String companionId;
  final SentimentService _sentimentService;
  final LocalChatRepository _chatRepository;

  ChatMessagesNotifier(this.companionId, this._sentimentService, this._chatRepository) : super([]) {
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    // 1. Try to load existing history
    final history = await _chatRepository.loadMessages(companionId);
    
    if (history.isNotEmpty) {
      state = history;
      return;
    }

    // 2. Fallback to mock initial greeting if no history exists
    state = [
      ChatMessage(
        id: 'init_$companionId',
        companionId: companionId,
        sender: MessageSender.ai,
        text: _getGreetingForPersona(companionId),
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
    
    // Save the initial greeting
    await _chatRepository.saveMessages(companionId, state);
  }

  String _getGreetingForPersona(String id) {
    switch (id) {
      case 'riley':
        return "Hey! Ready to crush some goals today? What's on your mind?";
      case 'sage':
        return "Greetings. How is your spirit feeling in this moment?";
      case 'finn':
      default:
        return "Hi there. I'm here. How are you feeling today?";
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

    // 2. Send to OpenAI for Chat Completion using persona.systemPrompt
    final responseText = await _sentimentService.generateChatResponse(
      persona: persona,
      history: state,
    );

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      companionId: companionId,
      sender: MessageSender.ai,
      text: responseText,
      timestamp: DateTime.now(),
    );

    state = [...state, aiMsg];
    
    // 3. Persist the updated conversation
    await _chatRepository.saveMessages(companionId, state);

    // 4. TODO: Run sentiment extraction on the user's message in the background to update the Mood Orbit
  }
}
