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
import '../../core/design_system.dart';
import '../chat/companion_list_view.dart';
import '../history/trends_view.dart';
import 'meditation_detail_view.dart';
import '../profile/memory_vault_view.dart';
import '../../core/user_memory_service.dart';
import '../../models/user_profile.dart';
import '../../core/auth_service.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final currentMood = ref.watch(moodProvider);
        final profile = ref.watch(userProfileProvider);

        return Scaffold(
          backgroundColor: DesignSystem.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context, ref, profile),
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
                  const SizedBox(height: 140), // Space for global navigation
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: DesignSystem.labelMuted,
            ),
            const SizedBox(height: 4),
            Text(
              profile.name ?? 'Friend',
              style: DesignSystem.displayLarge,
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: 52,
            height: 52,
            decoration: AppTheme.cardDecoration(
              shape: BoxShape.circle,
            ).copyWith(
              image: const DecorationImage(
                image: AssetImage('images/avatar_female.png'),
                fit: BoxFit.cover,
              ),
            ),
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
      {'id': 'open', 'label': 'Open', 'emoji': '✨'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: DesignSystem.titleLarge,
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
                      color: isSelected ? DesignSystem.vibeRed.withValues(alpha: 0.1) : DesignSystem.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? DesignSystem.vibeRed.withValues(alpha: 0.3) : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [] : DesignSystem.softShadow,
                    ),
                    child: Row(
                      children: [
                        Text(m['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          m['label']!,
                          style: DesignSystem.bodyMedium.copyWith(
                            color: isSelected ? DesignSystem.vibeRed : DesignSystem.textSlateDeep,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
          MaterialPageRoute(builder: (_) => const CompanionListView()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: AppTheme.cardDecoration(color: DesignSystem.background).copyWith(
          border: Border.all(color: DesignSystem.vibeRed.withValues(alpha: 0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignSystem.vibeRed.withValues(alpha: 0.05),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 5.seconds, curve: Curves.easeInOut),
              ),
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
                              color: DesignSystem.vibeRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'FINN IS LISTENING',
                              style: DesignSystem.labelBold.copyWith(fontSize: 10),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Need a breath?',
                            style: DesignSystem.displayLarge.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Vibe Assistant is ready for a deep conversation.',
                            style: DesignSystem.labelMuted,
                          ),
                        ],
                      ),
                    ),
                    const Hero(
                      tag: 'companion_avatar',
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: DesignSystem.vibeRedLight,
                        child: Icon(Icons.psychology_rounded, size: 50, color: DesignSystem.vibeRed),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOutSine),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 400.ms, duration: 800.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: DesignSystem.titleLarge,
        ),
        Text(
          'See all',
          style: DesignSystem.labelBold.copyWith(fontSize: 13),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildMeditationScroller(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(meditationSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(child: Text('No sessions available.', style: DesignSystem.bodyMedium));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: sessions.map((session) {
              final mood = session.id.contains('calm') ? 'calm' : (session.id.contains('joy') ? 'joy' : 'open');
              final Color moodColor = AppTheme.getMoodColor(mood);

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
                  decoration: AppTheme.cardDecoration(color: DesignSystem.background).copyWith(
                    border: Border.all(color: moodColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: moodColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: Icon(Icons.spa_rounded, color: DesignSystem.textSlateDeep, size: 20),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignSystem.titleLarge.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.durationMinutes} min',
                        style: DesignSystem.labelMuted.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1, end: 0);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error', style: TextStyle(color: DesignSystem.vibeRed))),
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
      Color color = DesignSystem.surface;
      
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
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Overview',
                  style: DesignSystem.labelMuted.copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: DesignSystem.surface, borderRadius: BorderRadius.circular(8)),
                  child: Text('Last 7 Days', style: DesignSystem.labelBold.copyWith(fontSize: 10)),
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
              color: DesignSystem.surface,
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
              ),
            ),
          ).animate().scaleY(begin: 0, end: 1, duration: 1.seconds, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: DesignSystem.labelMuted.copyWith(fontSize: 10),
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


