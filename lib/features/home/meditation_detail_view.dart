import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/meditation_session.dart';

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
    final hexString = widget.session.colors.isNotEmpty ? widget.session.colors.first : '#B5A5FF';
    _baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    _baseColor.withValues(alpha: 0.05),
                    Colors.white,
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
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 30),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFF0F172A)),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _baseColor,
                  _baseColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _baseColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 48),
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
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -1,
          ),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'GUIDED SESSION • $_duration',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 2,
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
            activeTrackColor: _baseColor,
            inactiveTrackColor: _baseColor.withValues(alpha: 0.1),
            thumbColor: _baseColor,
          ),
          child: Slider(
            value: _progress,
            onChanged: (v) => setState(() => _progress = v),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('02:45', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              Text('13:00', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 36),
              color: const Color(0xFF0F172A),
              onPressed: () {},
            ),
            const SizedBox(width: 32),
            GestureDetector(
              onTap: () => setState(() => _isPlaying = !_isPlaying),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
              color: const Color(0xFF0F172A),
              onPressed: () {},
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}
