import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design_system.dart';
import '../../core/audio_service.dart';
import '../../core/sentiment_service.dart';
import '../../providers/history_provider.dart';
import '../../providers/mood_provider.dart';
import '../chat/companion_list_view.dart';
import '../../core/components/vibe_scaffold.dart';

class MoodOrbitView extends ConsumerStatefulWidget {
  const MoodOrbitView({super.key});

  @override
  ConsumerState<MoodOrbitView> createState() => _MoodOrbitViewState();
}

class _MoodOrbitViewState extends ConsumerState<MoodOrbitView> {
  final AudioService _audioService = AudioService();
  bool _isRecording = false;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isAnalyzing) return;

    if (_isRecording) {
      // STOP RECORDING & ANALYZE
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
      });
      HapticFeedback.mediumImpact();

      try {
        final path = await _audioService.stopRecording();
        if (path != null) {
          final snapshot = await ref.read(sentimentServiceProvider).analyzeVoice(path);
          
          // 1. Update the global mood provider for "Mood-Aware Responses"
          ref.read(moodProvider.notifier).state = snapshot.mood;
          
          // 2. Add to history for the Orbit visualization
          ref.read(historyProvider.notifier).addSnapshot(snapshot);
          
          // 3. Navigate to companions
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompanionListView()),
            );
          }
        }
      } catch (e) {
        debugPrint('MoodOrbit Error: $e');
      } finally {
        if (mounted) setState(() => _isAnalyzing = false);
      }
    } else {
      // START RECORDING
      await _audioService.startRecording();
      setState(() => _isRecording = true);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    
    return VibeScaffold(
      title: 'Your Universe',
      body: Stack(
        children: [
          // 1. Light Atmosphere Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: DesignSystem.orbitBackground),
            ),
          ),

          // 2. The Orbit
          _buildOrbit(history),

          // 3. Central Call to Action
          Center(
            child: _buildCentralButton(),
          ),

          // 4. Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Universe',
                    style: DesignSystem.h1,
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    'Emotional landscape of the last 7 days',
                    style: DesignSystem.label,
                  ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbit(List<dynamic> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    final points = history.take(12).toList();
    
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbital Ring (Subtle Dark Line)
          Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DesignSystem.textDeep.withValues(alpha: 0.04), width: 1.5),
            ),
          ),

          // Orbiting Mood Nodes
          for (int i = 0; i < points.length; i++)
            _buildOrbitingNode(points[i], i, points.length),
        ],
      ).animate(onPlay: (c) => c.repeat())
       .rotate(duration: 25.seconds, begin: 0, end: 1),
    );
  }

  Widget _buildOrbitingNode(dynamic snapshot, int index, int total) {
    final angle = (index / total) * 2 * pi;
    const radius = 170.0;
    final x = radius * cos(angle);
    final y = radius * sin(angle);
    final baseColor = AppTheme.getMoodColor(snapshot.mood);
    final colors = [baseColor, baseColor.withValues(alpha: 0.5)];
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[1].withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.blur_on_rounded, color: DesignSystem.textDeep.withValues(alpha: 0.4), size: 24),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(
         duration: 2.seconds, 
         curve: Curves.easeInOutSine, 
         begin: const Offset(0.9, 0.9), 
         end: const Offset(1.15, 1.15)
       )
       .shimmer(delay: (index * 200).ms, duration: 3.seconds, color: DesignSystem.onAccent.withValues(alpha: 0.2)),
    );
  }

  Widget _buildCentralButton() {
    return GestureDetector(
      onTap: _handlePress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: AppTheme.cardDecoration().copyWith(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isRecording ? DesignSystem.accent : DesignSystem.borderColor, 
                width: 2
              ),
            ),
            child: Center(
              child: _isAnalyzing 
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3, color: DesignSystem.textDeep),
                  )
                : Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded, 
                    color: _isRecording ? DesignSystem.accent : DesignSystem.textDeep, 
                    size: 52
                  ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(
              begin: const Offset(1, 1), 
              end: Offset(_isRecording ? 1.2 : 1.12, _isRecording ? 1.2 : 1.12), 
              duration: 1.5.seconds, 
              curve: Curves.easeInOutCubic
            ),
          const SizedBox(height: 32),
          Text(
            _isAnalyzing ? 'ANALYZING VIBE...' : (_isRecording ? 'TAP TO STOP' : 'SPEAK TO VIBE'),
            style: DesignSystem.label.copyWith(
              color: _isRecording ? DesignSystem.accent : DesignSystem.textDeep,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .fadeIn(duration: 1.seconds),
        ],
      ),
    );
  }
}

