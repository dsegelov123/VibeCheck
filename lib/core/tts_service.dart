import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'api_config.dart';

class TtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  TtsService() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });
  }

  bool get isPlaying => _isPlaying;

  Stream<void> get onPlayerComplete => _audioPlayer.onPlayerComplete;

  Future<void> speak(String text) async {
    if (!ApiConfig.hasElevenLabsKey) {
      debugPrint('TtsService: No ElevenLabs API key found. Skipping TTS.');
      return;
    }

    try {
      _isPlaying = true;
      final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/${ApiConfig.elevenLabsVoiceId}');
      
      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': ApiConfig.elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_turbo_v2_5',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          }
        }),
      );

      if (response.statusCode == 200) {
        final completer = Completer<void>();
        StreamSubscription? sub;
        sub = _audioPlayer.onPlayerComplete.listen((_) {
          _isPlaying = false;
          sub?.cancel();
          if (!completer.isCompleted) completer.complete();
        });

        if (kIsWeb) {
          // On Web, we can play the audio bytes by converting them to a data URI
          final base64Audio = base64Encode(response.bodyBytes);
          final dataUri = 'data:audio/mpeg;base64,$base64Audio';
          await _audioPlayer.play(UrlSource(dataUri));
        } else {
          // On native, write to a temp file
          final dir = await getTemporaryDirectory();
          final file = File(p.join(dir.path, 'tts_response.mp3'));
          await file.writeAsBytes(response.bodyBytes);
          
          await _audioPlayer.play(DeviceFileSource(file.path));
        }
        await completer.future;
      } else {
        debugPrint('TtsService: Failed to generate TTS. Status code: ${response.statusCode}');
        debugPrint('TtsService: Response: ${response.body}');
        _isPlaying = false;
      }
    } catch (e) {
      debugPrint('TtsService: Error during TTS: $e');
      _isPlaying = false;
    }
  }

  void stop() {
    _audioPlayer.stop();
    _isPlaying = false;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
