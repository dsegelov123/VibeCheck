import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/mood_provider.dart';
import '../../core/app_theme.dart';
import '../../core/audio_service.dart';
import '../../core/sentiment_service.dart';
import '../../providers/history_provider.dart';
import '../history/reflection_view.dart';
import 'widgets/safety_nudge.dart';
import 'widgets/companion_avatar.dart';
import '../monetization/pro_paywall_view.dart';

class CompanionView extends ConsumerStatefulWidget {
  const CompanionView({super.key});

  @override
  ConsumerState<CompanionView> createState() => _CompanionViewState();
}

class _CompanionViewState extends ConsumerState<CompanionView> {
  bool _isRecording = false;
  String? _lastCompanionResponse;
  final _audioService = AudioService();
  final _sentimentService = SentimentService();

  Future<void> _handleRecordingToggle(bool isStarting) async {
    if (isStarting) {
      setState(() {
        _isRecording = true;
        _lastCompanionResponse = null;
      });
      await _audioService.startRecording();
    } else {
      setState(() => _isRecording = false);
      final path = await _audioService.stopRecording();
      if (path != null) {
        // Trigger Analysis
        final snapshot = await _sentimentService.analyzeVoice(path);
        
        // Save to History (and Supabase)
        await ref.read(historyProvider.notifier).addSnapshot(snapshot);
        
        ref.read(moodProvider.notifier).state = snapshot.mood;
        
        if (mounted) {
          setState(() {
            _lastCompanionResponse = snapshot.companionResponse;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(moodProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppTheme.getMoodGradient(mood),
                ),
              ),
            ),
          ),

          // 2. The Companion Presence
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CompanionAvatar(
                  mood: mood,
                  isRecording: _isRecording,
                  amplitudeStream: _isRecording ? _audioService.onAmplitudeChanged : null,
                ).animate(target: _isRecording ? 1 : 0)
                 .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 600.ms, curve: Curves.easeInOut),
                const SizedBox(height: 60),
                if (_lastCompanionResponse != null && !_isRecording) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: _getMoodColor(mood).withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Text(
                      '"$_lastCompanionResponse"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate(key: ValueKey('msg_$_lastCompanionResponse')).fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      _getStateMessage(mood, _isRecording),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ).animate(
                      key: ValueKey('msg_$mood$_isRecording'),
                    ).fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                  ),
                ],
              ],
            ),
          ),

          // 3. FaceTime Overlay UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, mood),
                  const Spacer(),
                  if (mood == 'sad')
                    const SafetyNudge().animate().fadeIn().slideY(begin: 0.2, end: 0),
                  const Spacer(),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String mood) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusIndicator(mood),
        Row(
          children: [
            _buildUpgradeButton(context),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReflectionView()),
              ),
              icon: const Icon(Icons.history_rounded, color: Color(0xFF1E293B), size: 28),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProPaywallView(), fullscreenDialog: true),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'PRO',
          style: TextStyle(
            color: Color(0xFF92400E),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String mood) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: AppTheme.glassDecoration(opacity: 0.4).copyWith(
            border: Border.all(color: const Color(0xFF1E293B).withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getMoodColor(mood),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
               .custom(
                 duration: 1.5.seconds,
                 builder: (context, value, child) => Container(
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     boxShadow: [
                       BoxShadow(
                         color: _getMoodColor(mood).withValues(alpha: 0.4 * (1 - value)),
                         blurRadius: 15 * value,
                         spreadRadius: 4 * value,
                       ),
                     ],
                   ),
                 ),
               ),
              const SizedBox(width: 10),
              Text(
                mood.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => _handleRecordingToggle(true),
        onTapUp: (_) => _handleRecordingToggle(false),
        onTapCancel: () => _handleRecordingToggle(false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                    color: _isRecording 
                      ? Colors.redAccent.withValues(alpha: 0.7) 
                      : Colors.white.withValues(alpha: 0.6),
                    border: Border.all(
                      color: _isRecording 
                        ? Colors.redAccent.withValues(alpha: 0.8) 
                        : const Color(0xFF1E293B).withValues(alpha: 0.1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isRecording 
                          ? Colors.redAccent.withValues(alpha: 0.3) 
                          : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.square_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.white : const Color(0xFF1E293B),
                size: 40,
              ),
            ),
          ),
        ),
      ).animate(target: _isRecording ? 1 : 0)
       .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.elasticOut),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'joy': return Colors.amber;
      case 'sad': return Colors.blue;
      case 'calm': return Colors.greenAccent;
      case 'anxious': return Colors.red;
      default: return Colors.white54;
    }
  }

  String _getStateMessage(String mood, bool isRecording) {
    if (isRecording) return 'LISTENING SYMPATHETICALLY...';
    switch (mood) {
      case 'joy': return 'TAKING IN YOUR ENERGY...';
      case 'sad': return 'HOLDING SPACE FOR YOU...';
      case 'anxious': return 'BREATHING WITH YOU...';
      default: return 'READY TO LISTEN...';
    }
  }
}
