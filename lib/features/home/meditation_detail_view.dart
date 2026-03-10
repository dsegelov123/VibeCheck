import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/meditation_session.dart';
import '../../core/design_system.dart';
import '../../core/meditation_audio_service.dart';
import '../../providers/audio_provider.dart';
import 'dart:ui';

class MeditationDetailView extends ConsumerStatefulWidget {
  final MeditationSession session;

  const MeditationDetailView({super.key, required this.session});

  @override
  ConsumerState<MeditationDetailView> createState() => _MeditationDetailViewState();
}

class _MeditationDetailViewState extends ConsumerState<MeditationDetailView> {
  late final Color _baseColor;

  @override
  void initState() {
    super.initState();
    final hexString = widget.session.colors.isNotEmpty ? widget.session.colors.first : '#F02D3A';
    _baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));
  }

  @override
  void deactivate() {
    // Stop audio only if navigating away (not just re-building)
    // We keep the service alive so resuming on back-nav works
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(meditationAudioProvider);

    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // 1. Dynamic gradient background
          Positioned.fill(
            child: AnimatedContainer(
              duration: 3.seconds,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _baseColor.withValues(alpha: 0.1),
                    DesignSystem.background,
                    _baseColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // 2. Mesh glow orb
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _baseColor.withValues(alpha: 0.08),
              ),
            ).animate(onPlay: (c) => c.repeat()).blur(begin: const Offset(40, 40), end: const Offset(60, 60), duration: 10.seconds),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _buildVisualizer(audio),
                        const Spacer(flex: 2),
                        _buildSessionInfo(),
                        const Spacer(flex: 3),
                        _buildControls(context, audio),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DesignSystem.textSlateDeep, size: 36),
          ),
          Text(
            widget.session.category.toUpperCase(),
            style: DesignSystem.labelBold.copyWith(letterSpacing: 2, color: DesignSystem.textSlateMuted, fontSize: 10),
          ),
          IconButton(
            onPressed: () => HapticFeedback.selectionClick(),
            icon: const Icon(Icons.more_vert_rounded, color: DesignSystem.textSlateDeep),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizer(MeditationAudioService audio) {
    final isActive = audio.isPlaying || audio.isLoading;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing rings — faster when playing
          ...List.generate(4, (index) {
            return Container(
              width: 220 + (index * 40).toDouble(),
              height: 220 + (index * 40).toDouble(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _baseColor.withValues(alpha: isActive ? 0.12 - (index * 0.02) : 0.06 - (index * 0.01)),
                  width: 1.5,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(
               begin: const Offset(1, 1),
               end: Offset(isActive ? 1.15 + (index * 0.04) : 1.05, isActive ? 1.15 + (index * 0.04) : 1.05),
               duration: (isActive ? 3 + index : 5 + index).seconds,
               curve: Curves.easeInOutSine,
             );
          }),

          // Central orb — shows loading spinner or icon
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, DesignSystem.background],
              ),
              boxShadow: [
                BoxShadow(
                  color: _baseColor.withValues(alpha: 0.15),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
              border: Border.all(color: _baseColor.withValues(alpha: 0.15), width: 1.5),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: audio.isLoading
                      ? SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _baseColor,
                          ),
                        )
                      : Icon(
                          audio.isPlaying ? Icons.graphic_eq_rounded : Icons.bubble_chart_rounded,
                          color: _baseColor,
                          size: 56,
                        ),
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 2.seconds, curve: Curves.easeInOutSine),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Column(
      children: [
        Text(
          widget.session.title,
          textAlign: TextAlign.center,
          style: DesignSystem.titleLarge.copyWith(fontSize: 34, height: 1.1, fontWeight: FontWeight.w900),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 12),
        Text(
          widget.session.description,
          textAlign: TextAlign.center,
          style: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateMuted),
        ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
      ],
    );
  }

  Widget _buildControls(BuildContext context, MeditationAudioService audio) {
    // On web: CORS blocks ElevenLabs — show script reader instead
    if (audio.state == AudioState.error && audio.errorMessage == 'audio_web_cors') {
      return _buildScriptReader();
    }

    // On other errors: show snackbar once
    if (audio.state == AudioState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(audio.errorMessage ?? 'Playback error'),
              backgroundColor: DesignSystem.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          audio.stop(); // Reset state
        }
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: DesignSystem.textSlateDeep.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: DesignSystem.textSlateDeep.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              // Progress bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  activeTrackColor: _baseColor,
                  inactiveTrackColor: _baseColor.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: audio.progress,
                  onChanged: audio.duration.inSeconds > 0
                      ? (v) {
                          final target = Duration(milliseconds: (v * audio.duration.inMilliseconds).round());
                          audio.seek(target);
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(audio.positionLabel, style: DesignSystem.labelMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text(
                    audio.duration.inSeconds > 0 ? audio.durationLabel : '${widget.session.durationMinutes}:00',
                    style: DesignSystem.labelMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replay -10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 32),
                    color: DesignSystem.textSlateDeep,
                    onPressed: audio.duration.inSeconds > 0 ? () => audio.skipBack10() : null,
                  ),
                  const SizedBox(width: 24),
                  // Play / Pause
                  GestureDetector(
                    onTap: audio.isLoading
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            audio.togglePlayPause(widget.session);
                          },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: audio.isLoading ? _baseColor.withValues(alpha: 0.4) : _baseColor,
                        boxShadow: [
                          BoxShadow(
                            color: _baseColor.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: audio.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(
                              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Forward +30s
                  IconButton(
                    icon: const Icon(Icons.forward_30_rounded, size: 32),
                    color: DesignSystem.textSlateDeep,
                    onPressed: audio.duration.inSeconds > 0 ? () => audio.skipForward30() : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 1.seconds).slideY(begin: 0.2, end: 0);
  }

  Widget _buildScriptReader() {
    final script = widget.session.script;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DesignSystem.textSlateDeep.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: DesignSystem.textSlateDeep.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _baseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headphones_rounded, size: 12, color: _baseColor),
                        const SizedBox(width: 4),
                        Text(
                          'Audio on iOS & Android',
                          style: DesignSystem.labelBold.copyWith(color: _baseColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('Read along', style: DesignSystem.labelMuted.copyWith(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: SingleChildScrollView(
                  child: Text(
                    script ?? widget.session.description,
                    style: DesignSystem.bodyMedium.copyWith(
                      color: DesignSystem.textSlateDeep.withValues(alpha: 0.8),
                      height: 1.7,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 1.seconds).slideY(begin: 0.2, end: 0);
  }
}
