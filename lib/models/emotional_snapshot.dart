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
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      transcript: json['transcript']?.toString(),
      mood: json['mood']?.toString() ?? 'calm',
      audioUrl: json['audioUrl']?.toString(),
      sentimentScores: _parseSentimentScores(json['sentimentScores']),
      companionResponse: json['companionResponse']?.toString(),
      embedding: _parseEmbedding(json['embedding']),
    );
  }

  static Map<String, double>? _parseSentimentScores(dynamic scores) {
    if (scores is! Map) return null;
    return Map<String, double>.from(
      scores.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }

  static List<double>? _parseEmbedding(dynamic embedding) {
    if (embedding is! List) return null;
    return List<double>.from(
      embedding.map((x) => (x as num).toDouble()),
    );
  }
}
