import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../providers/mood_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/history_provider.dart';
import '../../core/app_theme.dart';
import '../companion/companion_view.dart';
import '../history/trends_view.dart';
import 'meditation_detail_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMood = ref.watch(moodProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildMoodSelector(context, ref, currentMood),
                  const SizedBox(height: 32),
                  _buildCompanionCard(context, currentMood),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Emotional Trend'),
                  const SizedBox(height: 16),
                  _buildTrendChart(context, ref),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Guided for you'),
                  const SizedBox(height: 16),
                  _buildMeditationScroller(context, ref),
                  const SizedBox(height: 120), // Space for floating dock
                ],
              ),
            ),
          ),

          // 2. Floating Bottom Navigation
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: _buildFloatingDock(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Alex',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    color: const Color(0xFF0F172A),
                  ),
            ),
          ],
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: AssetImage('images/avatar_female.png'),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.black12, width: 2),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildMoodSelector(BuildContext context, WidgetRef ref, String currentMood) {
    final moods = [
      {'id': 'joy', 'label': 'Excited', 'emoji': '🎉'},
      {'id': 'calm', 'label': 'Calm', 'emoji': '🍃'},
      {'id': 'anxious', 'label': 'Stressed', 'emoji': '😰'},
      {'id': 'sad', 'label': 'Down', 'emoji': '☁️'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: moods.map((m) {
              final isSelected = currentMood == m['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(moodProvider.notifier).state = m['id']!;
                  },
                  child: AnimatedContainer(
                    duration: 300.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFB5A5FF).withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFB5A5FF).withValues(alpha: 0.5) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(m['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          m['label']!,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 800.ms);
  }

  Widget _buildCompanionCard(BuildContext context, String mood) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CompanionView()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Deep Indigo
              Color(0xFF818CF8), // Medium Indigo
              Color(0xFFB5A5FF), // Pastel Purple
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Noise/Texture Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.05),
                ),
              ),
              
              // Decorative Blobs
              Positioned(
                right: -50,
                bottom: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 4.seconds, curve: Curves.easeInOut),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'FINN IS LISTENING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Need a breath?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Vibe Assistant is ready for a deep conversation.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Hero(
                      tag: 'companion_avatar',
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.psychology_rounded, size: 50, color: Colors.white),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOutSine),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 400.ms, duration: 800.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutCubic),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const Text(
          'See all',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6366F1),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildMeditationScroller(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(meditationSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('No sessions available.', style: TextStyle(color: Colors.grey)));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: sessions.map((session) {
              final String hexString = session.colors.isNotEmpty ? session.colors.first : '#B5A5FF';
              final Color baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));

              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MeditationDetailView(session: session),
                  ),
                ),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: baseColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                        child: const Icon(Icons.spa_rounded, color: Color(0xFF1E293B), size: 20),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        session.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.durationMinutes} min',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1, end: 0);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Text('Failed to load library: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildFloatingDock(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDockItem(Icons.home_rounded, true),
              _buildDockItem(Icons.grid_view_rounded, false),
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompanionView()),
                  );
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB5A5FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFFB5A5FF), blurRadius: 15, spreadRadius: -2),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                ),
              ),
              GestureDetector(
                 onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TrendsView()),
                  ),
                child: _buildDockItem(Icons.bar_chart_rounded, false),
              ),
              _buildDockItem(Icons.person_rounded, false),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.5, end: 0);
  }

  Widget _buildDockItem(IconData icon, bool active) {
    return Icon(
      icon,
      color: active ? Colors.white : Colors.white38,
      size: 28,
    );
  }

  Widget _buildTrendChart(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final now = DateTime.now();

    final List<Map<String, dynamic>> weeklyData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayHistory = history.where((s) => 
        s.timestamp.year == date.year && 
        s.timestamp.month == date.month && 
        s.timestamp.day == date.day
      ).toList();
      
      double heightFactor = 0.1;
      Color color = Colors.grey.shade300;
      
      if (dayHistory.isNotEmpty) {
        final latest = dayHistory.first; 
        heightFactor = (0.2 + (dayHistory.length * 0.15)).clamp(0.2, 1.0);
        color = AppTheme.getMoodColor(latest.mood);
      }
      return {
        'label': _getDayLabel(date),
        'heightFactor': heightFactor,
        'color': color,
      };
    });

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TrendsView()),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Overview',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Last 7 Days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeklyData.map((data) {
                  return _buildHatchedBar(data['label'], data['heightFactor'], data['color']);
                }).toList(),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
    );
  }

  String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }


  Widget _buildHatchedBar(String label, double heightFactor, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: HatchedPainter(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
          ).animate().scaleY(begin: 0, end: 1, duration: 1.seconds, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class NoisePainter extends CustomPainter {
  final double opacity;
  NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final random = Random();
    for (int i = 0; i < 1000; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HatchedPainter extends CustomPainter {
  final Color color;
  HatchedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const spacing = 8.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
