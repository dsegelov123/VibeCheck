import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/meditation_session.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';

class MeditationDetailView extends ConsumerStatefulWidget {
  final MeditationSession session;

  const MeditationDetailView({super.key, required this.session});

  @override
  ConsumerState<MeditationDetailView> createState() => _MeditationDetailViewState();
}

class _MeditationDetailViewState extends ConsumerState<MeditationDetailView> {
  bool _isPlaying = false;
  double _progress = 0.0;
  late final String _title;
  late final String _duration;
  late final Color _baseColor;

  @override
  void initState() {
    super.initState();
    _title = widget.session.title;
    _duration = '${widget.session.durationMinutes} min';
    final hexString = widget.session.colors.isNotEmpty ? widget.session.colors.first : '#F02D3A';
    _baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // 1. Dynamic Background
          Positioned.fill(
            child: AnimatedContainer(
              duration: 2.seconds,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _baseColor.withValues(alpha: 0.03),
                    DesignSystem.background,
                  ],
                ),
              ),
            ),
          ),

          // 2. Immersive Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildHeader(context),
                  const Spacer(),
                  _buildVisualizer(),
                  const Spacer(),
                  _buildSessionInfo(),
                  const SizedBox(height: 48),
                  _buildControls(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: DesignSystem.textSlateDeep, size: 30),
        ),
        IconButton(
          onPressed: () {
             HapticFeedback.selectionClick();
          },
          icon: const Icon(Icons.favorite_border_rounded, color: DesignSystem.textSlateDeep),
        ),
      ],
    );
  }

  Widget _buildVisualizer() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulsing Rings
          ...List.generate(3, (index) {
            return Container(
              width: 200 + (index * 40).toDouble(),
              height: 200 + (index * 40).toDouble(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _baseColor.withValues(alpha: 0.1 - (index * 0.03)),
                  width: 2,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(
               begin: const Offset(1, 1), 
               end: Offset(1.1 + (index * 0.05), 1.1 + (index * 0.05)), 
               duration: (3 + index).seconds, 
               curve: Curves.easeInOutSine
             );
          }),
          
          // Main Orb
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignSystem.background,
              boxShadow: [
                BoxShadow(
                  color: _baseColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(color: _baseColor.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(Icons.spa_rounded, color: _baseColor, size: 48),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Column(
      children: [
        Text(
          _title,
          textAlign: TextAlign.center,
          style: DesignSystem.titleLarge.copyWith(fontSize: 32, height: 1.1),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 16),
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
              color: DesignSystem.vibeRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
           ),
           child: Text(
            'GUIDED SESSION • $_duration',
            style: DesignSystem.labelBold.copyWith(
              fontSize: 10,
              color: DesignSystem.vibeRed,
              letterSpacing: 1.5,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Progress Bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: DesignSystem.vibeRed,
            inactiveTrackColor: DesignSystem.vibeRed.withValues(alpha: 0.1),
            thumbColor: DesignSystem.vibeRed,
          ),
          child: Slider(
            value: _progress,
            onChanged: (v) => setState(() => _progress = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('02:45', style: DesignSystem.labelMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
              Text('13:00', style: DesignSystem.labelMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 36),
              color: DesignSystem.textSlateDeep,
              onPressed: () {},
            ),
            const SizedBox(width: 32),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _isPlaying = !_isPlaying);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.vibeRed,
                  boxShadow: [
                    BoxShadow(
                      color: DesignSystem.vibeRed.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 36),
              color: DesignSystem.textSlateDeep,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}
