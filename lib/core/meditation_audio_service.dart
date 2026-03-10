import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/meditation_session.dart';
import 'api_config.dart';

enum AudioState { idle, loading, playing, paused, error }

class MeditationAudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  AudioState _state = AudioState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;
  String? _currentSessionId;

  // In-memory cache for web (sessionId → base64 data URI)
  final Map<String, String> _webCache = {};

  AudioState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _state == AudioState.playing;
  bool get isLoading => _state == AudioState.loading;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionLabel => _formatDuration(_position);
  String get durationLabel => _formatDuration(_duration);

  MeditationAudioService() {
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    _player.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.playing) {
        _state = AudioState.playing;
      } else if (playerState == PlayerState.paused) {
        _state = AudioState.paused;
      } else if (playerState == PlayerState.completed) {
        _state = AudioState.idle;
        _position = Duration.zero;
      }
      notifyListeners();
    });
  }

  Future<void> play(MeditationSession session) async {
    if (_currentSessionId == session.id && _state == AudioState.paused) {
      await _player.resume();
      return;
    }

    if (_currentSessionId != session.id) {
      await _player.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
    }

    _currentSessionId = session.id;
    final script = session.script;

    if (script == null || script.isEmpty) {
      _setError('No script available for this session.');
      return;
    }

    if (!ApiConfig.hasElevenLabsKey) {
      _setError('ElevenLabs API key not configured.');
      return;
    }

    // On web, ElevenLabs API calls are blocked by CORS.
    // Audio generation works fully on iOS and Android.
    if (kIsWeb) {
      _setError('audio_web_cors');
      return;
    }
    _state = AudioState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check native file cache first
      if (!kIsWeb) {
        final cachedFile = await _getCachedFile(session.id);
        if (cachedFile != null && await cachedFile.exists()) {
          debugPrint('MeditationAudioService: Playing from cache: ${cachedFile.path}');
          await _player.play(DeviceFileSource(cachedFile.path));
          return;
        }
      }

      // Check web in-memory cache
      if (kIsWeb && _webCache.containsKey(session.id)) {
        debugPrint('MeditationAudioService: Playing from web memory cache.');
        await _player.play(UrlSource(_webCache[session.id]!));
        return;
      }

      // Generate via ElevenLabs
      debugPrint('MeditationAudioService: Generating audio via ElevenLabs...');
      final audioBytes = await _generateAudio(script);

      if (audioBytes == null) {
        _setError('Failed to generate audio. Please try again.');
        return;
      }

      if (kIsWeb) {
        final dataUri = 'data:audio/mpeg;base64,${base64Encode(audioBytes)}';
        _webCache[session.id] = dataUri;
        await _player.play(UrlSource(dataUri));
      } else {
        final file = await _getCachedFile(session.id);
        await file!.parent.create(recursive: true);
        await file.writeAsBytes(audioBytes);
        debugPrint('MeditationAudioService: Cached to ${file.path}');
        await _player.play(DeviceFileSource(file.path));
      }
    } catch (e) {
      debugPrint('MeditationAudioService: Error: $e');
      _setError('Playback error. Please try again.');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlayPause(MeditationSession session) async {
    if (_state == AudioState.playing) {
      await pause();
    } else {
      await play(session);
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipBack10() async {
    final target = _position - const Duration(seconds: 10);
    await seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> skipForward30() async {
    final target = _position + const Duration(seconds: 30);
    await seek(target > _duration ? _duration : target);
  }

  Future<void> stop() async {
    await _player.stop();
    _state = AudioState.idle;
    _position = Duration.zero;
    _currentSessionId = null;
    notifyListeners();
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Future<Uint8List?> _generateAudio(String text) async {
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/${ApiConfig.elevenLabsVoiceId}',
    );
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
          'stability': 0.65,       // Slightly more stable for meditative tone
          'similarity_boost': 0.80,
          'style': 0.20,           // Subtle expressiveness
          'use_speaker_boost': true,
        },
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      debugPrint('ElevenLabs error ${response.statusCode}: ${response.body}');
      return null;
    }
  }

  Future<File?> _getCachedFile(String sessionId) async {
    if (kIsWeb) return null;
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/session_audio/$sessionId.mp3');
  }

  void _setError(String message) {
    _state = AudioState.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
