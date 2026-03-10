import 'dart:convert';

class VoiceCallLog {
  final String id;
  final String companionId;
  final DateTime startTime;
  final Duration duration;
  final String fullTranscript;

  VoiceCallLog({
    required this.id,
    required this.companionId,
    required this.startTime,
    required this.duration,
    required this.fullTranscript,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companionId': companionId,
      'startTime': startTime.toIso8601String(),
      'duration': duration.inSeconds,
      'fullTranscript': fullTranscript,
    };
  }

  factory VoiceCallLog.fromMap(Map<String, dynamic> map) {
    return VoiceCallLog(
      id: map['id'],
      companionId: map['companionId'],
      startTime: DateTime.parse(map['startTime']),
      duration: Duration(seconds: map['duration'] as int),
      fullTranscript: map['fullTranscript'],
    );
  }

  String toJson() => json.encode(toMap());

  factory VoiceCallLog.fromJson(String source) => VoiceCallLog.fromMap(json.decode(source));
}
