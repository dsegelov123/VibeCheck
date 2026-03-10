import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/meditation_audio_service.dart';

/// A single shared MeditationAudioService instance for the whole app.
/// This lets audio continue if the user briefly navigates away, and
/// ensures only one session plays at a time.
final meditationAudioProvider = ChangeNotifierProvider<MeditationAudioService>(
  (ref) {
    final service = MeditationAudioService();
    ref.onDispose(service.dispose);
    return service;
  },
);
