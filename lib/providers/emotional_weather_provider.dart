import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import 'history_provider.dart';
import '../models/emotional_snapshot.dart';

class DailyWeather {
  final String name;
  final IconData icon;
  final Map<String, double> aggregateDistribution;
  final Color primaryColor;
  final String? primaryTrigger;

  DailyWeather({
    required this.name,
    required this.icon,
    required this.aggregateDistribution,
    required this.primaryColor,
    this.primaryTrigger,
  });

  factory DailyWeather.fromSnapshots(List<EmotionalSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return DailyWeather(
        name: 'Waiting for Insights',
        icon: Icons.cloud_outlined,
        aggregateDistribution: {},
        primaryColor: DesignSystem.borderColor.withValues(alpha: 0.5),
      );
    }

    // 1. Get primary trigger (most common or last)
    final triggerMap = <String, int>{};
    for (var s in snapshots) {
      if (s.behavioralTrigger != null) {
        triggerMap[s.behavioralTrigger!] = (triggerMap[s.behavioralTrigger!] ?? 0) + 1;
      }
    }
    String? dominantTrigger;
    if (triggerMap.isNotEmpty) {
      dominantTrigger = triggerMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // 2. Aggregate distributions
    final Map<String, double> totalDistribution = {};
    for (var snapshot in snapshots) {
      final dist = snapshot.moodDistribution;
      if (dist != null) {
        dist.forEach((mood, value) {
          totalDistribution[mood] = (totalDistribution[mood] ?? 0) + value;
        });
      } else {
        // Fallback for snapshots without distribution (use dominant mood as 100%)
        totalDistribution[snapshot.mood] = (totalDistribution[snapshot.mood] ?? 0) + 1.0;
      }
    }

    // Normalize by number of snapshots
    final count = snapshots.length;
    final Map<String, double> averageDistribution = {};
    totalDistribution.forEach((mood, value) {
      averageDistribution[mood] = value / count;
    });

    return calculateFromDistribution(averageDistribution, primaryTrigger: dominantTrigger);
  }

  static DailyWeather calculateFromDistribution(Map<String, double> dist, {String? primaryTrigger}) {
    if (dist.isEmpty) {
      return DailyWeather(
        name: 'Calm Skies',
        icon: Icons.wb_sunny_rounded,
        aggregateDistribution: {},
        primaryColor: DesignSystem.moodColors['calmness']!,
      );
    }

    // Normalized map for case-insensitive lookup
    final normalized = dist.map((k, v) => MapEntry(k.toLowerCase().trim(), v));

    // Sum up broader categories (case-insensitive)
    double sunny = (normalized['joy'] ?? 0) + (normalized['excitement'] ?? 0) + (normalized['pride'] ?? 0) + (normalized['excited'] ?? 0) + (normalized['proud'] ?? 0);
    double rainy = (normalized['sadness'] ?? 0) + (normalized['grief'] ?? 0) + (normalized['loneliness'] ?? 0) + (normalized['sad'] ?? 0) + (normalized['grieving'] ?? 0) + (normalized['lonely'] ?? 0);
    double foggy = (normalized['anxiety'] ?? 0) + (normalized['stress'] ?? 0) + (normalized['fear'] ?? 0) + (normalized['anxious'] ?? 0) + (normalized['stressed'] ?? 0) + (normalized['fearful'] ?? 0);
    double stormy = (normalized['anger'] ?? 0) + (normalized['frustration'] ?? 0) + (normalized['annoyance'] ?? 0) + (normalized['angry'] ?? 0) + (normalized['frustrated'] ?? 0) + (normalized['annoyed'] ?? 0);
    double clear = (normalized['calmness'] ?? 0) + (normalized['reflection'] ?? 0) + (normalized['calm'] ?? 0) + (normalized['reflective'] ?? 0);
    double cloudy = (normalized['tiredness'] ?? 0) + (normalized['boredom'] ?? 0) + (normalized['tired'] ?? 0) + (normalized['bored'] ?? 0);

    // Sort scores to find top two
    final scores = {
      'sunny': sunny,
      'rainy': rainy,
      'foggy': foggy,
      'stormy': stormy,
      'clear skies': clear,
      'partly cloudy': cloudy,
    };

    final sortedEntries = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sortedEntries[0];
    final second = sortedEntries[1];

    String finalWeatherName = dominant.key;

    // Micro-Climate Logic: Detect Mixed States
    // If top two are close (< 0.15 gap) and both are substantial (> 0.25)
    if (second.value > 0.25 && (dominant.value - second.value) < 0.15) {
      if ((dominant.key == 'sunny' && second.key == 'rainy') || (dominant.key == 'rainy' && second.key == 'sunny')) {
        finalWeatherName = 'unsettled';
      } else if ((dominant.key == 'foggy' && second.key == 'clear skies') || (dominant.key == 'clear skies' && second.key == 'foggy')) {
        finalWeatherName = 'misty';
      } else if ((dominant.key == 'stormy' && second.key == 'rainy') || (dominant.key == 'rainy' && second.key == 'stormy')) {
        finalWeatherName = 'heavy';
      }
    }

    final style = DesignSystem.getWeatherStyle(finalWeatherName);

    return DailyWeather(
      name: finalWeatherName[0].toUpperCase() + finalWeatherName.substring(1),
      icon: style.icon,
      aggregateDistribution: normalized,
      primaryColor: style.color,
      primaryTrigger: primaryTrigger,
    );
  }
}

final dailyWeatherProvider = Provider<DailyWeather>((ref) {
  final history = ref.watch(historyProvider);
  final now = DateTime.now();
  
  final todaySnapshots = history.where((s) {
    return s.timestamp.year == now.year &&
           s.timestamp.month == now.month &&
           s.timestamp.day == now.day;
  }).toList();

  return DailyWeather.fromSnapshots(todaySnapshots);
});
