class EmotionalSnapshot {
  final String id;
  final DateTime timestamp;
  final String? transcript;
  final String mood;
  final String? audioUrl;
  final Map<String, double>? sentimentScores;
  final String? companionResponse;
  final List<double>? embedding;

  EmotionalSnapshot({
    required this.id,
    required this.timestamp,
    this.transcript,
    required this.mood,
    this.audioUrl,
    this.sentimentScores,
    this.companionResponse,
    this.embedding,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'transcript': transcript,
      'mood': mood,
      'audioUrl': audioUrl,
      'sentimentScores': sentimentScores,
      'companionResponse': companionResponse,
      'embedding': embedding,
    };
  }

  factory EmotionalSnapshot.fromJson(Map<String, dynamic> json) {
    return EmotionalSnapshot(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      transcript: json['transcript'],
      mood: json['mood'],
      audioUrl: json['audioUrl'],
      sentimentScores: json['sentimentScores'] != null 
          ? Map<String, double>.from(json['sentimentScores']) 
          : null,
      companionResponse: json['companionResponse'],
      embedding: json['embedding'] != null 
          ? List<double>.from((json['embedding'] as List).map((x) => (x as num).toDouble()))
          : null,
    );
  }
}
