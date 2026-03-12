import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/emotional_snapshot.dart';
import '../core/api_config.dart';
import 'memory_service.dart';
import '../models/companion_persona.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sentimentServiceProvider = Provider<SentimentService>((ref) {
  return SentimentService();
});

class SentimentService {
  final _random = Random();
  final _memoryService = MemoryService();

  /// Analyzes audio for emotional content. 
  /// Uses OpenAI if a key is available, otherwise falls back to refined mock logic.
  Future<EmotionalSnapshot> analyzeVoice(String audioPath) async {
    debugPrint('SentimentService: Analyzing audio at $audioPath');
    
    if (ApiConfig.hasApiKey) {
      debugPrint('SentimentService: OpenAI Key detected. Attempting AI Analysis...');
      try {
        // 1. Transcription via Whisper
        final transcript = await transcribeAudioRaw(audioPath);
        debugPrint('SentimentService: Transcription success: "$transcript"');
        // 2. Generate Embedding for the transcript
        List<double>? embedding;
        String memoryContext = "";
        
        try {
          embedding = await generateEmbedding(transcript);
          
          if (embedding != null) {
             // 3. Fetch similar past snapshots
             final similarPast = await _memoryService.findSimilarVibes(embedding);
             if (similarPast.isNotEmpty) {
                memoryContext = "Here is relevant past context about the user:\n";
                for (var snap in similarPast) {
                  memoryContext += "- On ${snap.timestamp.toLocal().toString().split(' ')[0]}, they felt ${snap.mood} and said: '${snap.transcript}'. Finn replied: '${snap.companionResponse}'\n";
                }
             }
          }
        } catch (e) {
          debugPrint('SentimentService: Embedding/Memory fetch failed (Continuing without context): $e');
        }

        // 4. Sentiment Extraction via GPT-4o Mini
        final analysis = await _extractSentiment(transcript, context: memoryContext);
        debugPrint('SentimentService: GPT Analysis success: $analysis');
        
        return EmotionalSnapshot(
          id: DateTime.now().toIso8601String(),
          timestamp: DateTime.now(),
          mood: analysis['mood'] ?? 'Calmness',
          transcript: transcript,
          sentimentScores: Map<String, double>.from(analysis['scores'] ?? {}),
          moodDistribution: Map<String, double>.from(analysis['moodDistribution'] ?? {}),
          companionResponse: analysis['response'],
          embedding: embedding,
          behavioralTrigger: analysis['behavioralTrigger'],
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
    
    final moods = [
      'Joy', 'Excitement', 'Pride',
      'Sadness', 'Grief', 'Loneliness',
      'Anxiety', 'Stress', 'Fear',
      'Calmness', 'Reflection', 'Tiredness', 'Boredom',
      'Anger', 'Frustration', 'Annoyance'
    ];
    final selectedMood = moods[_random.nextInt(moods.length)];

    final map = {
      'joy': ["I'm feeling incredibly productive today! Everything finally clicked."],
      'excited': ["I can't wait for the trip this weekend! It's going to be amazing."],
      'proud': ["I finally finished that massive project. Feels so good to be done."],
      
      'sad': ["Feeling a bit heavy today. Not sure why, just low energy."],
      'grieving': ["I'm just really missing my grandfather today."],
      'lonely': ["It feels like everyone is busy lately. Kinda wishing I had someone to talk to."],
      
      'anxious': ["There's so much on my plate and I don't know where to start."],
      'overwhelmed': ["My inbox just keeps growing. I can't keep up with all the demands right now."],
      'fearful': ["I have my performance review tomorrow and I'm really scared about what they'll say."],
      
      'calm': ["Just finished a long walk. My mind feels still and clear."],
      'reflective': ["I was just thinking about how much I've changed over the last year."],
      'tired': ["Didn't sleep well at all. I'm just dragging through the day."],
      'bored': ["Nothing seems interesting right now. Just scrolling mindlessly."],
      
      'angry': ["I cannot believe they canceled the meeting again without telling me!"],
      'frustrated': ["I've been trying to fix this bug for hours and it makes no sense!"],
      'annoyed': ["The neighbor's dog has been barking all morning and I can't concentrate."]
    };

    final responses = map[selectedMood]!;
    final transcript = responses[_random.nextInt(responses.length)];
    
    final responseMap = {
      'joy': "I'm so glad to hear that! It's radiating exactly the right energy.",
      'excited': "That is amazing! I love hearing you so fired up.",
      'proud': "You absolutely should be! That's a huge accomplishment.",
      
      'sad': "I hear you. It's completely okay to feel that weight today.",
      'grieving': "I'm so sorry. Take all the time you need to process that.",
      'lonely': "I'm right here with you. You aren't alone.",
      
      'anxious': "Take a deep breath. We can navigate this together step by step.",
      'overwhelmed': "Let's pause. We just need to focus on the very next step, nothing else.",
      'fearful': "It's natural to be scared, but you are strong enough to handle this.",
      
      'calm': "That sounds incredibly peaceful. It's good to pause.",
      'reflective': "That's a beautiful perspective to have on your journey.",
      'tired': "Rest is productive too. Please be gentle with yourself today.",
      'bored': "Sometimes the mind just needs a break from constant stimulation.",
      
      'angry': "That is completely valid. You have every right to feel that way.",
      'frustrated': "I completely understand why that's driving you crazy.",
      'annoyed': "Ugh, that sounds incredibly draining. I'm sorry you have to deal with that."
    };
    final companionResp = responseMap[selectedMood.toLowerCase()];

    // Generate a mock distribution that sums to 1.0 (100%)
    final Map<String, double> mockDistribution = {};
    mockDistribution[selectedMood] = 0.6; // Dominant mood
    final secondMood = moods[(moods.indexOf(selectedMood) + 1) % moods.length];
    final thirdMood = moods[(moods.indexOf(selectedMood) + 2) % moods.length];
    mockDistribution[secondMood] = 0.25;
    mockDistribution[thirdMood] = 0.15;

    return EmotionalSnapshot(
      id: DateTime.now().toIso8601String(),
      timestamp: DateTime.now(),
      mood: selectedMood,
      transcript: transcript,
      sentimentScores: {
        'positive': ['Joy', 'Excitement', 'Pride', 'Calmness'].contains(selectedMood) ? 0.9 : 0.2,
        'negative': ['Sadness', 'Grief', 'Loneliness', 'Anxiety', 'Fear', 'Anger', 'Frustration'].contains(selectedMood) ? 0.8 : 0.1,
        'neutral': ['Reflection', 'Tiredness', 'Boredom'].contains(selectedMood) ? 0.9 : 0.3,
      },
      moodDistribution: mockDistribution,
      companionResponse: companionResp,
      behavioralTrigger: 'Mock Insight',
    );
  }

  Future<String> transcribeAudioRaw(String path) async {
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

  Future<List<double>?> generateEmbedding(String text) async {
    final url = Uri.parse('${ApiConfig.openAiBaseUrl}/embeddings');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'text-embedding-3-small',
        'input': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> embeddingArray = data['data'][0]['embedding'];
      return List<double>.from(embeddingArray.map((x) => (x as num).toDouble()));
    } else {
       throw Exception('Failed to generate embedding: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _extractSentiment(String text, {String context = ""}) async {
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
            'content': 'Analyze the following emotional reflection. Output ONLY a JSON object with: "mood" (MUST be exactly one of: Joy, Excitement, Pride, Sadness, Grief, Loneliness, Anxiety, Stress, Fear, Calmness, Reflection, Tiredness, Boredom, Anger, Frustration, Annoyance), "scores" (object with double values for "positive", "negative", "neutral" ranging from 0.0 to 1.0), "moodDistribution" (an object mapping EVERY one of the 16 moods mentioned above to a percentage value (0.0 to 1.0). The sum of all 16 values MUST be exactly 1.0), "behavioralTrigger" (a short 2-3 word string identifying the root pattern, e.g. "Work Stress", "Social Connection", "Lack of Sleep"), and "response" (a short, empathetic 1-sentence response as an AI companion named Finn).\n\n$context'
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

  /// Public method to analyze text and return a full sentiment profile.
  Future<Map<String, dynamic>> analyzeText(String text, {String context = ""}) async {
     return await _extractSentiment(text, context: context);
  }

  /// Generates a conversational response based on persona and chat history.
  /// Optionally injects [userProfile] (long-term memory) and [currentMood]
  /// into the system prompt to make replies personal and tone-aware.
  Future<String> generateChatResponse({
    required CompanionPersona persona,
    required List<ChatMessage> history,
    UserProfile? userProfile,
    String? currentMood,
  }) async {
    if (!ApiConfig.hasApiKey) {
      await Future.delayed(const Duration(seconds: 1));
      return "(Mock Response) I am functioning in offline mode. My API key is not configured.";
    }

    final url = Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions');

    // ── Build contextual prefix ───────────────────────────────────────────
    final buffer = StringBuffer();

    // Long-term memory block
    if (userProfile != null && !userProfile.isEmpty) {
      buffer.writeln('[Memory about this user]');
      if (userProfile.name != null) {
        buffer.writeln('Name: ${userProfile.name}');
      }
      if (userProfile.activeFacts.isNotEmpty) {
        buffer.writeln('Active context:');
        for (final fact in userProfile.activeFacts) {
          buffer.writeln('- ${fact.text}');
        }
      }
      buffer.writeln();
    }

    // Mood-aware tone block
    if (currentMood != null && currentMood.isNotEmpty && currentMood != 'neutral') {
      buffer.writeln('[User\'s current emotional state]');
      buffer.writeln(
          'The user was recently detected as feeling: $currentMood. '
          'Adjust your tone and opening accordingly — be empathetic to this emotional state.');
      buffer.writeln();
    }

    // Check-in & Scheduling Management (Phase 24)
    final now = DateTime.now();
    buffer.writeln('[Check-in Management]');
    buffer.writeln('Current Date/Time: ${now.toIso8601String()}');
    if (userProfile != null && userProfile.pendingCheckIns.isNotEmpty) {
      buffer.writeln('Upcoming events found in user memory that might need a follow-up:');
      for (final event in userProfile.pendingCheckIns) {
        buffer.writeln('- $event');
      }
      buffer.writeln('INSTRUCTION: If the user hasn\'t been asked yet, gently ask for permission to check in after ONE of these events (e.g., "I\'d love to check in with you after your meeting. Would that be okay?").');
    }
    buffer.writeln('SCHEDULING RULES:');
    buffer.writeln('1. If the user asks for a check-in or says "Yes" to your offer, but hasn\'t provided a TIME, you MUST ask: "What time should I reach out?"');
    buffer.writeln('2. If a specific time/date is agreed upon, generate your response and APPEND this hidden trigger at the very end: [SCHEDULE_NOTIF: ISO_TIMESTAMP].');
    buffer.writeln('3. Calculate the ISO_TIMESTAMP to be shortly after the event (e.g. +1 hour).');
    buffer.writeln();

    final contextPrefix = buffer.toString();
    final fullSystemPrompt = contextPrefix.isNotEmpty
        ? '$contextPrefix${persona.systemPrompt}'
        : persona.systemPrompt;

    // Convert our internal history to OpenAI format
    final messages = [
      {'role': 'system', 'content': fullSystemPrompt},
      // Take the last 40 messages for context window management
      ...history.reversed.take(40).toList().reversed.map((msg) => {
        'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
        'content': msg.text,
      }).toList(),
    ];

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          // We can adjust temperature per persona later for more/less creativity
          'temperature': 0.7, 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('SentimentService Chat Error: ${response.statusCode} - ${response.body}');
        return "I'm having a little trouble connecting right now.";
      }
    } catch (e) {
      debugPrint('SentimentService Chat Exception: $e');
      return "Something went wrong on my end. Can we try that again?";
    }
  }

  /// Quickly analyzes the mood of a text message.
  Future<String?> analyzeTextSentiment(String text) async {
    if (!ApiConfig.hasApiKey) return null;

    try {
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
              'content': 'Analyze the mood of the following user message. Output ONLY a single word mood from this list: Joy, Excitement, Pride, Sadness, Grief, Loneliness, Anxiety, Stress, Fear, Calmness, Reflection, Tiredness, Boredom, Anger, Frustration, Annoyance, neutral. Only return neutral if no strong emotion is present.'
            },
            {'role': 'user', 'content': text}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().toLowerCase().trim();
        return content == 'neutral' ? null : content;
      }
    } catch (e) {
      debugPrint('SentimentService: Text sentiment analysis failed: $e');
    }
    return null;
  }
}
