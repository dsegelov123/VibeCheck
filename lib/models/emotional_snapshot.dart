class EmotionalSnapshot {
  final String id;
  final DateTime timestamp;
  final String? transcript;
  final String mood;
  final String? audioUrl;
  final Map<String, double>? sentimentScores;
  final Map<String, double>? moodDistribution; // New granular data
  final String? companionResponse;
  final List<double>? embedding;
  final bool isJournalEntry;
  final String? journalTitleSummary;
  final String? journalLongSummary;

  final String? behavioralTrigger; // Pattern detection (e.g. "Work Stress")

  EmotionalSnapshot({
    required this.id,
    required this.timestamp,
    this.transcript,
    required this.mood,
    this.audioUrl,
    this.sentimentScores,
    this.moodDistribution,
    this.companionResponse,
    this.embedding,
    this.isJournalEntry = false,
    this.journalTitleSummary,
    this.journalLongSummary,
    this.behavioralTrigger,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'transcript': transcript,
      'mood': mood,
      'audioUrl': audioUrl,
      'sentimentScores': sentimentScores,
      'moodDistribution': moodDistribution,
      'companionResponse': companionResponse,
      'embedding': embedding,
      'is_journal_entry': isJournalEntry,
      'journal_title_summary': journalTitleSummary,
      'journal_long_summary': journalLongSummary,
      'behavioral_trigger': behavioralTrigger,
    };
  }

  factory EmotionalSnapshot.fromJson(Map<String, dynamic> json) {
    return EmotionalSnapshot(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      transcript: json['transcript']?.toString(),
      mood: json['mood']?.toString() ?? 'Calmness',
      audioUrl: json['audioUrl']?.toString(),
      sentimentScores: _parseMap(json['sentimentScores']),
      moodDistribution: _parseMap(json['moodDistribution']),
      companionResponse: json['companionResponse']?.toString(),
      embedding: _parseEmbedding(json['embedding']),
      isJournalEntry: json['is_journal_entry'] == true, 
      journalTitleSummary: json['journal_title_summary']?.toString(),
      journalLongSummary: json['journal_long_summary']?.toString(),
      behavioralTrigger: json['behavioral_trigger']?.toString(),
    );
  }

  static Map<String, double>? _parseMap(dynamic data) {
    if (data is! Map) return null;
    return Map<String, double>.from(
      data.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }

  static List<double>? _parseEmbedding(dynamic embedding) {
    if (embedding is! List) return null;
    return List<double>.from(
      embedding.map((x) => (x as num).toDouble()),
    );
  }
}
