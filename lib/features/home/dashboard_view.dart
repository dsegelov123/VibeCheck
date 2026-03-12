import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../core/components/vibe_scaffold.dart';
import '../../providers/mood_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/history_provider.dart';
import '../../core/app_theme.dart';
import '../chat/companion_list_view.dart';
import '../history/trends_view.dart';
import 'meditation_detail_view.dart';
import '../profile/memory_vault_view.dart';
import '../../core/user_memory_service.dart';
import '../../models/user_profile.dart';
import '../../core/auth_service.dart';
import '../../providers/emotional_weather_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return VibeScaffold(
      title: 'VibeCheck',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(context, ref, profile),
            const SizedBox(height: 24),
            _buildEmotionalWeatherCard(context, ref),
            const SizedBox(height: 24),
            _buildSectionHeader('Chat with Companions'),
            const SizedBox(height: 12),
            _buildCompanionShortcut(context),

            const SizedBox(height: 24),
            _buildSectionHeader('Guided for you'),
            const SizedBox(height: 12),
            _buildMeditationScroller(context, ref),
            const SizedBox(height: 100), // Reserve space for global navigation
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning,',
          style: DesignSystem.label,
        ),
        const SizedBox(height: 4),
        Text(
          profile.name ?? 'Friend',
          style: DesignSystem.h1,
        ),
      ],
    );
  }

  Widget _buildEmotionalWeatherCard(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(dailyWeatherProvider);
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
        width: double.infinity,
        decoration: AppTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
          // Weather Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: weather.primaryColor.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: DesignSystem.borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppTheme.cardDecoration(
                    color: DesignSystem.surface,
                    shape: BoxShape.circle,
                    showBorder: true,
                  ).copyWith(
                    border: Border.all(color: weather.primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Icon(weather.icon, size: 24, color: weather.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY\'S WEATHER',
                        style: DesignSystem.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.name,
                        style: DesignSystem.h2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mood Distribution Chart
          if (weather.aggregateDistribution.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EMOTIONAL BREAKDOWN',
                        style: DesignSystem.label,
                      ),
                      Text(
                        '${(weather.aggregateDistribution.values.fold(0.0, (a, b) => a + b) * 100).toInt()}% DETECTED',
                        style: DesignSystem.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Horizontal Distribution Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: Row(
                        children: weather.aggregateDistribution.entries
                            .where((e) => e.value > 0.02)
                            .map((e) {
                          return Expanded(
                            flex: (e.value * 100).toInt(),
                            child: Container(color: AppTheme.getMoodColor(e.key)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Legend Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weather.aggregateDistribution.entries
                        .where((e) => e.value > 0.1)
                        .map((e) {
                      final moodColor = AppTheme.getMoodColor(e.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: moodColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: moodColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(color: moodColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${e.key} ${(e.value * 100).toInt()}%',
                              style: DesignSystem.label,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          if (weather.aggregateDistribution.isNotEmpty)
            Divider(height: 1, thickness: 1, color: DesignSystem.borderColor.withValues(alpha: 0.5)),
            
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: DesignSystem.label.copyWith(color: DesignSystem.textMuted),
                    ),
                    Text(
                      'Past Week',
                      style: DesignSystem.label,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyData.map((data) {
                      return _buildTrendBar(data['label'], data['heightFactor'], data['color']);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildCompanionShortcut(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CompanionListView()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.accent.withValues(alpha: 0.05),
                border: Border.all(color: DesignSystem.accent.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.psychology_rounded, color: DesignSystem.accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat with Companions', style: DesignSystem.body),
                  Text('Personalized emotional support.', style: DesignSystem.label),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: DesignSystem.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: DesignSystem.h2,
        ),
        Text(
          'See all',
          style: DesignSystem.label,
        ),
      ],
    );
  }

  Widget _buildMeditationScroller(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(meditationSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(child: Text('No sessions available.', style: DesignSystem.body));
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
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: moodColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.spa_rounded, color: moodColor, size: 18),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignSystem.body,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.durationMinutes} min',
                        style: DesignSystem.label,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error', style: TextStyle(color: DesignSystem.accent))),
    );
  }



  Widget _buildTrendBar(String label, double heightFactor, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 24,
            decoration: BoxDecoration(
              color: DesignSystem.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: DesignSystem.borderColor, width: 1),
            ),
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: DesignSystem.label,
        ),
      ],
    );
  }

  String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}


