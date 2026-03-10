import '../../models/companion_persona.dart';
import '../../models/user_profile.dart';
import '../../core/design_system.dart';
import '../../core/audio_service.dart';
import '../../core/sentiment_service.dart';
import '../../core/tts_service.dart';
import '../../core/user_memory_service.dart';
import '../../core/voice_call_repository.dart';
import '../../models/voice_call_log.dart';
import 'call_history_view.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';

enum CallState { connecting, listening, processing, speaking, error }

class VoiceCallView extends ConsumerStatefulWidget {
  final CompanionPersona persona;

  const VoiceCallView({super.key, required this.persona});

  @override
  ConsumerState<VoiceCallView> createState() => _VoiceCallViewState();
}

class _VoiceCallViewState extends ConsumerState<VoiceCallView> {
  CallState _callState = CallState.connecting;
  final AudioService _audioService = AudioService();
  final TtsService _ttsService = TtsService();
  StreamSubscription<Amplitude>? _amplitudeSub;
  
  bool _isMuted = false;
  bool _showTranscript = false;
  bool _isCallActive = true;
  
  String _latestUserTranscript = "";
  String _latestAiTranscript = "";
  
  final double _silenceThreshold = -60.0; // dB
  int _silenceDurationMs = 0;
  bool _isUserSpeaking = false;
  
  // Call Logging
  final DateTime _callStartTime = DateTime.now();
  final StringBuffer _transcriptBuilder = StringBuffer();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _isCallActive = false;
    _amplitudeSub?.cancel();
    _audioService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!mounted || !_isCallActive) return;
    
    setState(() => _callState = CallState.listening);
    
    if (_isMuted) return;

    await _audioService.startRecording();
    _amplitudeSub = _audioService.onAmplitudeChanged.listen((amp) {
      debugPrint('VAD Amp: ${amp.current}');
      if (amp.current > _silenceThreshold) {
        _isUserSpeaking = true;
        _silenceDurationMs = 0;
      } else {
        if (_isUserSpeaking) {
          _silenceDurationMs += 50; 
          if (_silenceDurationMs > 1500) { 
            _stopListeningAndProcess();
          }
        }
      }
    });
  }

  Future<void> _stopListeningAndProcess() async {
    _amplitudeSub?.cancel();
    _isUserSpeaking = false;
    _silenceDurationMs = 0;
    
    if (!mounted || !_isCallActive) return;
    
    setState(() => _callState = CallState.processing);

    final path = await _audioService.stopRecording();
    if (path != null) {
      try {
        final sentimentService = ref.read(sentimentServiceProvider);
        final transcript = await sentimentService.transcribeAudioRaw(path);

        if (transcript.trim().isEmpty) {
          if (_isCallActive && mounted) _startListening();
          return;
        }

        if (mounted) setState(() => _latestUserTranscript = transcript);

        // Append to running transcript
        _transcriptBuilder.writeln("User: $transcript");

        // Generate context-aware response without saving to chat history
        final aiResponse = await sentimentService.generateChatResponse(
          persona: widget.persona,
          history: [], // We represent this as a discrete one-off call block
          userProfile: ref.read(userProfileProvider),
          currentMood: null,
        );

        if (!mounted || !_isCallActive) return;
        
        _transcriptBuilder.writeln("Maya: $aiResponse\n");

        setState(() {
          _latestAiTranscript = aiResponse;
          _callState = CallState.speaking;
        });

        await _ttsService.speak(aiResponse);

      } catch (e) {
        debugPrint('VoiceCall Error: $e');
        if (mounted) {
           setState(() => _callState = CallState.error);
           await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    if (mounted && _isCallActive && !_isMuted) {
      _startListening();
    }
  }

  Future<void> _endCall() async {
    _isCallActive = false;
    HapticFeedback.mediumImpact();
    _amplitudeSub?.cancel();
    _ttsService.stop();
    _ttsService.dispose();
    _audioService.dispose();
    
    // Save the compiled transcript
    if (_transcriptBuilder.isNotEmpty) {
      final repo = ref.read(voiceCallRepositoryProvider);
      final log = VoiceCallLog(
        id: const Uuid().v4(),
        companionId: widget.persona.id,
        startTime: _callStartTime,
        duration: DateTime.now().difference(_callStartTime),
        fullTranscript: _transcriptBuilder.toString(),
      );
      await repo.saveCallLog(log);
      ref.invalidate(voiceCallLogsProvider(widget.persona.id));
    }
    
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainUI(),
            if (_showTranscript) _buildTranscriptOverlay(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           // Status Text Top
           Text(
             _getStatusText(),
             style: DesignSystem.labelBold.copyWith(
               color: DesignSystem.textSlateMuted,
               fontSize: 14,
             ),
           ).animate(key: ValueKey('status_$_callState')).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
           
           const SizedBox(height: 60),
           
           // Avatar Area
           GestureDetector(
             onTap: () {
               if (_callState == CallState.listening) {
                  HapticFeedback.lightImpact();
                  _stopListeningAndProcess();
               }
             },
             child: Stack(
               alignment: Alignment.center,
               children: [
                 if (_callState == CallState.speaking) ...[
                   Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignSystem.vibeRed.withValues(alpha: 0.05),
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms, curve: Curves.easeOut)
                     .fadeOut(duration: 1000.ms),
                 ],
                 if (_callState == CallState.listening) ...[
                   Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignSystem.surface,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeInOutSine),
                 ],
                 
                 Hero(
                    tag: 'avatar_${widget.persona.id}',
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignSystem.vibeRedLight,
                        border: Border.all(
                          color: _callState == CallState.processing 
                              ? DesignSystem.vibeRed.withValues(alpha: 0.5) 
                              : DesignSystem.vibeRed.withValues(alpha: 0.1), 
                          width: _callState == CallState.processing ? 4 : 2
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: DesignSystem.vibeRed.withValues(alpha: 0.1),
                             blurRadius: 30,
                             spreadRadius: 10,
                           )
                        ],
                      ),
                      child: const Icon(Icons.person, size: 80, color: DesignSystem.vibeRed),
                    ),
                  ).animate(target: _callState == CallState.processing ? 1 : 0)
                   .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5)),
               ],
             ),
           ),
           
           const SizedBox(height: 60),
           
           // Empathetic Status
           Text(
             kIsWeb && _callState == CallState.listening 
                 ? "Tap Maya when you are done speaking." 
                 : _getEmpatheticStatus(),
             textAlign: TextAlign.center,
             style: DesignSystem.bodyMedium.copyWith(
               color: DesignSystem.textSlateDeep,
               fontStyle: FontStyle.italic,
             ),
           ).animate(key: ValueKey('empathy_$_callState')).fadeIn(duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isMuted = !_isMuted);
              if (_isMuted) {
                 _amplitudeSub?.cancel();
                 _audioService.stopRecording();
              } else if (_callState == CallState.listening) {
                 _startListening();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isMuted ? DesignSystem.textSlateDeep : DesignSystem.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: _isMuted ? Colors.white : DesignSystem.textSlateDeep,
              ),
            ),
          ),
          
          // End Call
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: DesignSystem.errorRed,
                shape: BoxShape.circle,
                boxShadow: DesignSystem.softShadow,
              ),
              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
            ),
          ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 600.ms),
          
          // Transcript Toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showTranscript = !_showTranscript);
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _showTranscript ? DesignSystem.vibeRed.withValues(alpha: 0.1) : DesignSystem.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.subtitles_rounded,
                color: _showTranscript ? DesignSystem.vibeRed : DesignSystem.textSlateDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptOverlay() {
    return Positioned(
      bottom: 140,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: DesignSystem.glassClear.copyWith(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_latestUserTranscript.isNotEmpty) ...[
              Text(
                "You",
                style: DesignSystem.labelBold.copyWith(color: DesignSystem.textSlateMuted, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                _latestUserTranscript,
                style: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateDeep),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.persona.name,
              style: DesignSystem.labelBold.copyWith(color: DesignSystem.vibeRed, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              _latestAiTranscript.isEmpty ? "..." : _latestAiTranscript,
              style: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateDeep, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }

  String _getStatusText() {
    switch (_callState) {
      case CallState.connecting:
        return "CONNECTING...";
      case CallState.listening:
        return "LISTENING";
      case CallState.processing:
        return "PROCESSING";
      case CallState.speaking:
        return widget.persona.name.toUpperCase();
      case CallState.error:
        return "CONNECTION LOST";
    }
  }
  
  String _getEmpatheticStatus() {
    switch (_callState) {
      case CallState.connecting:
        return "Waking up ${widget.persona.name}...";
      case CallState.listening:
        return "I'm here. Take your time.";
      case CallState.processing:
        return "${widget.persona.name} is formulating a thought...";
      case CallState.speaking:
        return "";
      case CallState.error:
        return "Reconnecting...";
    }
  }
}
