import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../../core/components/vibe_scaffold.dart';
import '../../providers/history_provider.dart';
import 'journal_recording_view.dart';
import 'journal_detail_view.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class ReflectionView extends ConsumerWidget {
  const ReflectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return VibeScaffold(
      title: 'Journal',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JournalRecordingView()),
          );
        },
        backgroundColor: DesignSystem.accent,
        elevation: 4,
        child: const Icon(Icons.mic_rounded, color: DesignSystem.onAccent, size: 28),
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                'No memories captured yet.',
                style: DesignSystem.body,
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHighlightCard(context, history.first),
                  const SizedBox(height: 24),
                  ..._buildGroupedHistory(context, history.skip(1).toList()),
                  const SizedBox(height: 100), // Reserve space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, dynamic snapshot) {
    final moodColor = AppTheme.getMoodColor(snapshot.mood);
    return GestureDetector(
      onTap: () {
        if (snapshot.isJournalEntry) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JournalDetailView(snapshot: snapshot),
            ),
          );
        }
      },
      child: Container(
        decoration: AppTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherStrip(snapshot.moodDistribution),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LATEST REFLECTION',
                        style: DesignSystem.label,
                      ),
                      Icon(Icons.auto_awesome_rounded, color: moodColor.withValues(alpha: 0.3), size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.isJournalEntry ? (snapshot.journalTitleSummary ?? 'Untitled Entry') : snapshot.transcript,
                    style: DesignSystem.h2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        snapshot.isJournalEntry ? Icons.mic_rounded : Icons.psychology_rounded, 
                        color: DesignSystem.accent, 
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Text(
                        snapshot.isJournalEntry ? 'Voice Journal Entry' : 'Captured via Companion',
                        style: DesignSystem.label.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<Widget> _buildGroupedHistory(BuildContext context, List<dynamic> snapshots) {
    if (snapshots.isEmpty) return [];

    // Grouping logic
    final Map<String, List<dynamic>> grouped = {};
    for (var snapshot in snapshots) {
      final date = snapshot.timestamp;
      final now = DateTime.now();
      String key;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = 'TODAY';
      } else if (date.isAfter(now.subtract(const Duration(days: 1)))) {
        key = 'YESTERDAY';
      } else {
        key = DateFormat('MMMM dd').format(date).toUpperCase();
      }
      grouped.putIfAbsent(key, () => []).add(snapshot);
    }

    List<Widget> widgets = [];
    grouped.forEach((dateLabel, items) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: DesignSystem.label.copyWith(
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: DesignSystem.borderColor.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
      widgets.addAll(items.map((item) => _buildHistoryCard(context, item)));
    });

    return widgets;
  }

  Widget _buildHistoryCard(BuildContext context, dynamic snapshot) {
    final moodColor = AppTheme.getMoodColor(snapshot.mood);
    final timeStr = DateFormat('h:mm a').format(snapshot.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (snapshot.isJournalEntry) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JournalDetailView(snapshot: snapshot)),
            );
          }
        },
        child: Container(
          decoration: AppTheme.cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildWeatherStrip(snapshot.moodDistribution),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: moodColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              snapshot.mood.toUpperCase(),
                               style: DesignSystem.label,
                            ),
                          ],
                        ),
                        Text(
                          timeStr,
                          style: DesignSystem.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.isJournalEntry ? (snapshot.journalTitleSummary ?? 'Untitled Entry') : '"${snapshot.transcript}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignSystem.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStrip(Map<String, double>? distribution) {
    if (distribution == null || distribution.isEmpty) {
      return const SizedBox(height: 3); // Fallback for old entries
    }

    // Filter only moods > 0.05 to keep it clean
    final validMoods = distribution.entries
        .where((e) => e.value > 0.05)
        .toList();
    
    // Sort buy score descending
    validMoods.sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 3,
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
    );
  }
}
