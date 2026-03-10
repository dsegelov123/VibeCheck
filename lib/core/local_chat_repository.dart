import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

final localChatRepositoryProvider = Provider<LocalChatRepository>((ref) {
  return LocalChatRepository();
});

class LocalChatRepository {
  static const String _prefix = 'chat_messages_';

  Future<void> saveMessages(String companionId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$companionId';
    
    // Convert the list of ChatMessage objects to a list of JSON strings
    final jsonList = messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(key, jsonList);
  }

  Future<List<ChatMessage>> loadMessages(String companionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$companionId';
    
    final jsonList = prefs.getStringList(key);
    if (jsonList == null) {
      return [];
    }

    // Convert the JSON strings back into ChatMessage objects
    return jsonList.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return ChatMessage.fromJson(map);
    }).toList();
  }
}
