import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../models/emotional_snapshot.dart';
import '../../core/app_theme.dart';
import '../../core/components/vibe_scaffold.dart';

class JournalDetailView extends StatelessWidget {
  final EmotionalSnapshot snapshot;

  const JournalDetailView({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final moodColor = AppTheme.getMoodColor(snapshot.mood);
    final dateStr = DateFormat('MMMM dd, yyyy').format(snapshot.timestamp);
    final timeStr = DateFormat('h:mm a').format(snapshot.timestamp);

    return VibeScaffold(
      title: 'Entry Detail',
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, moodColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeatherStrip(snapshot.moodDistribution),
                  const SizedBox(height: 16),
                  // Meta Info Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: moodColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignSystem.radius),
                          border: Border.all(color: moodColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: moodColor),
                            const SizedBox(width: 6),
                            Text(
                              dateStr.toUpperCase(),
                              style: DesignSystem.label.copyWith(color: moodColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        timeStr,
                        style: DesignSystem.label,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // AI Summary Card (Authoritative & Straightforward)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: DesignSystem.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.auto_awesome_rounded, color: DesignSystem.accent, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'AI SUMMARY',
                              style: DesignSystem.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          snapshot.journalLongSummary ?? "Analyzing transcript...",
                          style: DesignSystem.h2.copyWith(
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // The "Transcript" Section
                  Text(
                    'FULL TRANSCRIPT',
                    style: DesignSystem.label,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration(),
                    child: Text(
                      snapshot.transcript ?? "No transcript available.",
                      style: DesignSystem.body.copyWith(
                        height: 1.8,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStrip(Map<String, double>? distribution) {
    if (distribution == null || distribution.isEmpty) {
      return const SizedBox(height: 4); // Fallback
    }

    final validMoods = distribution.entries
        .where((e) => e.value > 0.05)
        .toList();
    
    validMoods.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            width: double.infinity,
            child: Row(
              children: validMoods.map((entry) {
                return Expanded(
                  flex: (entry.value * 100).toInt(),
                  child: Container(
                    color: AppTheme.getMoodColor(entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'EMOTIONAL SPECTRUM',
          style: DesignSystem.label,
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, Color moodColor) {
    return SliverAppBar(
      expandedHeight: 220,
      backgroundColor: DesignSystem.background,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: DesignSystem.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 24, right: 24),
        centerTitle: false,
        title: Text(
          snapshot.journalTitleSummary ?? 'Journal Entry',
          style: DesignSystem.h2,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    moodColor.withValues(alpha: 0.15),
                    DesignSystem.background,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -100,
              top: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      moodColor.withValues(alpha: 0.1),
                      DesignSystem.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
