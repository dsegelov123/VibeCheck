enum MessageSender { user, ai }

class ChatMessage {
  final String id;
  final String companionId;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final String? synthesizedAudioPath; // For when we re-integrate TTS
  final String? extractedSentiment; // Store the mood extracted from this message (if any)

  ChatMessage({
    required this.id,
    required this.companionId,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.synthesizedAudioPath,
    this.extractedSentiment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companionId': companionId,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'synthesizedAudioPath': synthesizedAudioPath,
      'extractedSentiment': extractedSentiment,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      companionId: json['companionId'],
      sender: MessageSender.values.firstWhere((e) => e.name == json['sender']),
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      synthesizedAudioPath: json['synthesizedAudioPath'],
      extractedSentiment: json['extractedSentiment'],
    );
  }
}
