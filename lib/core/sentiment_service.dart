import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/emotional_snapshot.dart';
import '../core/api_config.dart';

class SentimentService {
  final _random = Random();

  /// Analyzes audio for emotional content. 
  /// Uses OpenAI if a key is available, otherwise falls back to refined mock logic.
  Future<EmotionalSnapshot> analyzeVoice(String audioPath) async {
    debugPrint('SentimentService: Analyzing audio at $audioPath');
    
    if (ApiConfig.hasApiKey) {
      debugPrint('SentimentService: OpenAI Key detected. Attempting AI Analysis...');
      try {
        // 1. Transcription via Whisper
        final transcript = await _transcribeAudio(audioPath);
        debugPrint('SentimentService: Transcription success: "$transcript"');
        
        // 2. Sentiment Extraction via GPT-4o Mini
        final analysis = await _extractSentiment(transcript);
        debugPrint('SentimentService: GPT Analysis success: $analysis');
        
        return EmotionalSnapshot(
          id: DateTime.now().toIso8601String(),
          timestamp: DateTime.now(),
          mood: analysis['mood'] ?? 'calm',
          transcript: transcript,
          sentimentScores: Map<String, double>.from(analysis['scores'] ?? {}),
          companionResponse: analysis['response'],
        );
      } catch (e) {
        debugPrint('SentimentService: AI Analysis failed with error: $e');
        debugPrint('SentimentService: Falling back to mock logic.');
      }
    } else {
      debugPrint('SentimentService: No OpenAI Key found in api_config.dart. Using mock.');
    }

    // --- Mock Fallback Logic ---
    await Future.delayed(const Duration(seconds: 2)); // Simulate network
    
    final moods = ['joy', 'calm', 'sad', 'anxious'];
    final selectedMood = moods[_random.nextInt(moods.length)];

    final map = {
      'joy': [
        "I'm feeling incredibly productive today! Everything finally clicked.",
        "Had a great call with my family. Feeling very connected.",
        "The sun is out and I just feel light. Ready to take on anything."
      ],
      'calm': [
        "Just finished a long walk. My mind feel still and clear.",
        "Looking at the rain outside with a cup of tea. Peaceful.",
        "The morning meditation really helped me center myself."
      ],
      'sad': [
        "Feeling a bit heavy today. Not sure why, just low energy.",
        "I miss home. Sometimes the city feels a bit isolating.",
        "Things didn't go as planned and I'm feeling the weight of it."
      ],
      'anxious': [
        "There's so much on my plate and I don't know where to start.",
        "My heart is racing a bit. Worried about the presentation tomorrow.",
        "Just feeling on edge. Everything feels a bit too loud today."
      ]
    };

    final responses = map[selectedMood]!;
    final transcript = responses[_random.nextInt(responses.length)];
    
    final responseMap = {
      'joy': "I'm so glad to hear that! It's radiating exactly the right energy.",
      'calm': "That sounds incredibly peaceful. It's good to pause.",
      'sad': "I hear you. It's completely okay to feel that weight today.",
      'anxious': "Take a deep breath. We can navigate this together step by step.",
    };
    final companionResp = responseMap[selectedMood];

    return EmotionalSnapshot(
      id: DateTime.now().toIso8601String(),
      timestamp: DateTime.now(),
      mood: selectedMood,
      transcript: transcript,
      sentimentScores: {
        'positive': selectedMood == 'joy' ? 0.9 : 0.2,
        'negative': selectedMood == 'sad' ? 0.8 : 0.1,
        'neutral': selectedMood == 'calm' ? 0.9 : 0.3,
      },
      companionResponse: companionResp,
    );
  }

  Future<String> _transcribeAudio(String path) async {
    final url = Uri.parse('${ApiConfig.openAiBaseUrl}/audio/transcriptions');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${ApiConfig.openAiApiKey}'
      ..fields['model'] = 'whisper-1';

    List<int> bytes;
    if (kIsWeb) {
      debugPrint('SentimentService: Detected Web. Fetching bytes from blob $path');
      final response = await http.get(Uri.parse(path));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch local audio blob: ${response.statusCode}');
      }
      bytes = response.bodyBytes;
    } else {
      // On mobile, we can use the File class since kIsWeb is false
      // and we are not in a web context.
      final file = File(path);
      bytes = await file.readAsBytes();
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: 'audio.m4a',
      contentType: MediaType('audio', 'm4a'),
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('OpenAI Authentication failed. Please check your API key in api_config.dart.');
      }
      throw Exception('Whisper failed (HTTP ${response.statusCode}): $responseBody');
    }

    final data = jsonDecode(responseBody);
    return data['text'] ?? '';
  }

  Future<Map<String, dynamic>> _extractSentiment(String text) async {
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
            'content': 'Analyze the following emotional reflection. Output ONLY a JSON object with: "mood" (one of: joy, calm, sad, anxious), "scores" (object with double values for "positive", "negative", "neutral" ranging from 0.0 to 1.0), and "response" (a short, empathetic 1-sentence response as an AI companion named Finn).'
          },
          {'role': 'user', 'content': text}
        ],
        'response_format': {'type': 'json_object'}
      }),
    );

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    
    if (content is String) {
      // Remove possible markdown formatting from GPT output
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
