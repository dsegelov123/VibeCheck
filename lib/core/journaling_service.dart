import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/emotional_snapshot.dart';
import 'api_config.dart';
import 'sentiment_service.dart';
import 'memory_service.dart';

class JournalingService {
  final SentimentService _sentimentService = SentimentService();
  final MemoryService _memoryService = MemoryService();

  Future<EmotionalSnapshot?> processJournalAudio(String audioPath) async {
    debugPrint('JournalingService: Processing journal audio at $audioPath');
    
    if (!ApiConfig.hasApiKey) {
      debugPrint('JournalingService: No API Key found, cannot transcribe or summarize journal.');
      return null; // For a real app, maybe return a mock, but Voice Journal needs AI to work decently.
    }

    try {
      // 1. Transcribe the raw audio using Whisper
      final transcript = await _sentimentService.transcribeAudioRaw(audioPath);
      debugPrint('JournalingService: Transcription complete. Length: ${transcript.length}');
      
      if (transcript.trim().isEmpty) {
        debugPrint('JournalingService: Transcript was empty.');
        return null;
      }

      // 2. Generate Summaries, Mood, and Sentiment Scores via GPT-4o-mini
      final analysis = await _generateJournalAnalysis(transcript);
      
      // 3. (Optional) Generate Embeddings for better Memory Vault search
      List<double>? embedding;
      try {
        embedding = await _sentimentService.generateEmbedding(transcript);
      } catch (e) {
        debugPrint('JournalingService: Embedding failed, skipping. $e');
      }

      // 4. Create Snapshot
      final snapshot = EmotionalSnapshot(
        id: DateTime.now().toIso8601String(),
        timestamp: DateTime.now(),
        mood: analysis['mood'] ?? 'Calmness',
        transcript: transcript,
        sentimentScores: Map<String, double>.from(analysis['scores'] ?? {}),
        moodDistribution: Map<String, double>.from(analysis['moodDistribution'] ?? {}),
        embedding: embedding,
        isJournalEntry: true,
        journalTitleSummary: analysis['journalTitleSummary'],
        journalLongSummary: analysis['journalLongSummary'],
      );

      debugPrint('JournalingService: Journal entry analyzed successfully.');
      return snapshot;

    } catch (e) {
      debugPrint('JournalingService: Processing failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _generateJournalAnalysis(String text) async {
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
            'content': 'You are an analytical and empathetic assistant for a personal audio journal. Your goal is to provide a straightforward, third-person summary of the user\'s thoughts and feelings.\n\nAnalyze the following journal transcript. Output ONLY a JSON object with the following keys:\n1. "mood" (MUST be exactly one of: Joy, Excitement, Pride, Sadness, Grief, Loneliness, Anxiety, Stress, Fear, Calmness, Reflection, Tiredness, Boredom, Anger, Frustration, Annoyance).\n2. "scores" (object with double values for "positive", "negative", "neutral" ranging from 0.0 to 1.0).\n3. "moodDistribution" (an object mapping EVERY one of the 16 moods mentioned above to a percentage value (0.0 to 1.0) based on its presence in the transcript. The sum of all 16 values MUST be exactly 1.0).\n4. "journalTitleSummary" (A very short, 3 to 5 word title in third-person that captures what the user talked about (e.g., "Feeling unseen at work").\n5. "journalLongSummary" (A straightforward, paragraph-length summary in the third-person. Use the user\'s name or "The user" if unknown. Describe their situation, feelings, and any plans or insights mentioned. Example: "{name} is feeling a little unseen at work at the moment, but they are excited about a city break to Paris this weekend.")'
          },
          {'role': 'user', 'content': text}
        ],
        'response_format': {'type': 'json_object'}
      }),
    );

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    
    if (content is String) {
      final sanitized = content
          .replaceAll(RegExp(r'^```json\s*'), '')
          .replaceAll(RegExp(r'^```\s*'), '')
          .replaceAll(RegExp(r'\s*```$'), '')
          .trim();
      return jsonDecode(sanitized);
    }
    return content;
  }
}
