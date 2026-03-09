import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/history_provider.dart';
import '../../core/app_theme.dart';
import '../companion/companion_view.dart';

class MoodOrbitView extends ConsumerStatefulWidget {
  const MoodOrbitView({super.key});

  @override
  ConsumerState<MoodOrbitView> createState() => _MoodOrbitViewState();
}

class _MoodOrbitViewState extends ConsumerState<MoodOrbitView> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Light Atmosphere Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFFF8FAFC),
                    Colors.white,
                  ],
                ),
              ),
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
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: const Color(0xFF0F172A),
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    'Emotional landscape of the last 7 days',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
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
              border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
            ),
          ),

          // Orbiting Mood Nodes
          for (int i = 0; i < points.length; i++)
            _buildOrbitingNode(points[i], i, points.length),
        ],
      ).animate(onPlay: (c) => c.repeat())
       .rotate(duration: 25.seconds, begin: 0, end: 1), // Sped up for visibility
    );
  }

  Widget _buildOrbitingNode(dynamic snapshot, int index, int total) {
    final angle = (index / total) * 2 * pi;
    final radius = 170.0;
    final x = radius * cos(angle);
    final y = radius * sin(angle);
    final colors = AppTheme.getMoodGradient(snapshot.mood);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 56, // Slightly larger
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
              color: colors[1].withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.blur_on_rounded, color: const Color(0xFF1E293B).withOpacity(0.4), size: 24),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(
         duration: 2.seconds, 
         curve: Curves.easeInOutSine, 
         begin: const Offset(0.9, 0.9), 
         end: const Offset(1.15, 1.15) // More prominent pulse
       )
       .shimmer(delay: (index * 200).ms, duration: 3.seconds, color: Colors.white.withOpacity(0.2)),
    );
  }

  Widget _buildCentralButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CompanionView()),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: AppTheme.glassDecoration(
              opacity: 0.1,
              shape: BoxShape.circle,
            ).copyWith(
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.mic_rounded, color: Color(0xFF0F172A), size: 52),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 1.5.seconds, curve: Curves.easeInOutCubic),
          const SizedBox(height: 32),
          Text(
            'SPEAK TO VIBE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF0F172A),
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .fadeIn(duration: 1.seconds),
        ],
      ),
    );
  }
}
