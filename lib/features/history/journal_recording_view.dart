import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import '../../core/audio_service.dart';
import '../../core/design_system.dart';
import '../../core/journaling_service.dart';
import '../../providers/history_provider.dart';
import '../../models/emotional_snapshot.dart';
import 'journal_detail_view.dart';

class JournalRecordingView extends ConsumerStatefulWidget {
  const JournalRecordingView({super.key});

  @override
  ConsumerState<JournalRecordingView> createState() => _JournalRecordingViewState();
}

class _JournalRecordingViewState extends ConsumerState<JournalRecordingView> {
  final AudioService _audioService = AudioService();
  final JournalingService _journalingService = JournalingService();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  double _amplitude = -160.0;
  StreamSubscription? _amplitudeSub;

  @override
  void initState() {
    super.initState();
    _startRecordingFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _startRecordingFlow() async {
    try {
      await _audioService.startRecording();
      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _duration = Duration(seconds: timer.tick));
      });

      _amplitudeSub = _audioService.onAmplitudeChanged.listen((amp) {
        setState(() => _amplitude = amp.current);
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _stopAndProcess() async {
    if (!_isRecording) return;
    
    _timer?.cancel();
    _amplitudeSub?.cancel();
    
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final path = await _audioService.stopRecording();
    
    if (path != null) {
      final snapshot = await _journalingService.processJournalAudio(path);
      if (mounted) {
        if (snapshot != null) {
          // Add to history so it appears in the list and updates weather
          await ref.read(historyProvider.notifier).addSnapshot(snapshot);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => JournalDetailView(snapshot: snapshot),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process journal. Please try again.')),
          );
          Navigator.pop(context);
        }
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalize amplitude for visualization (approx -60 to 0 range)
    double volumeScale = ((_amplitude + 60) / 60).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    DesignSystem.accent.withValues(alpha: 0.05 * volumeScale),
                    DesignSystem.background.withValues(alpha: 0.0),
                  ],
                  radius: 1.5,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  _isProcessing ? 'UNDERSTANDING...' : 'LISTENING',
                  style: DesignSystem.label.copyWith(
                    color: DesignSystem.accent,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .fadeIn(duration: 1.seconds)
                 .then()
                 .fadeOut(duration: 1.seconds),
                
                const Spacer(),
                
                // Pulsing Center Orb
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings
                      ...List.generate(3, (index) {
                        return Container(
                          width: 200 + (index * 40),
                          height: 200 + (index * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DesignSystem.accent.withValues(alpha: 0.1 / (index + 1)),
                              width: 2,
                            ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .scale(
                           begin: const Offset(1, 1),
                           end: Offset(1.2 + (volumeScale * 0.2), 1.2 + (volumeScale * 0.2)),
                           duration: Duration(milliseconds: 1000 + (index * 200)),
                           curve: Curves.easeOut,
                         ).fadeOut();
                      }),
                      
                      // Main Microphone / Processing Orb
                      GestureDetector(
                        onTap: _isProcessing ? null : _stopAndProcess,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: DesignSystem.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DesignSystem.accent.withValues(alpha: 0.3 * volumeScale),
                                blurRadius: 30,
                                spreadRadius: 10 * volumeScale,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isProcessing ? Icons.auto_awesome_rounded : Icons.stop_rounded,
                            color: DesignSystem.surface,
                            size: 48,
                          ),
                        ),
                      ).animate(target: _isProcessing ? 1 : 0)
                       .custom(
                         duration: 2.seconds,
                         builder: (context, value, child) => Transform.rotate(
                           angle: value * 6.28,
                           child: child,
                         ),
                       ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Timer
                Text(
                  _formatDuration(_duration),
                  style: DesignSystem.h1.copyWith(
                    fontSize: 32,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                
                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Text(
                    _isProcessing 
                      ? 'Combining your thoughts with the emotional weather...' 
                      : 'Speak freely. We are listening with understanding and care.',
                    textAlign: TextAlign.center,
                    style: DesignSystem.body,
                  ),
                ),
                
                if (!_isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: DesignSystem.label,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
