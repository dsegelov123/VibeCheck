import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/history_provider.dart';
import '../../core/app_theme.dart';
import '../../core/design_system.dart';

class ReflectionView extends ConsumerWidget {
  const ReflectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          if (history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No memories captured yet.',
                  style: DesignSystem.bodyMedium,
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildHighlightCard(context, history.first),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildHistoryCard(context, history[index + 1]),
                  childCount: history.length > 1 ? history.length - 1 : 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, dynamic snapshot) {
    // We still use mood colors for subtle accents, but the card itself is white
    final baseColor = AppTheme.getMoodColor(snapshot.mood);
    final colors = [baseColor, baseColor.withValues(alpha: 0.5)];
    final moodColor = colors[0];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.cardDecoration(color: DesignSystem.background).copyWith(
        border: Border.all(color: moodColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'LATEST REFLECTION',
                    style: DesignSystem.labelBold.copyWith(fontSize: 10, color: moodColor),
                  ),
                ),
                Icon(Icons.auto_awesome_rounded, color: moodColor.withValues(alpha: 0.3), size: 20),
             ],
          ),
          const SizedBox(height: 24),
          Text(
            snapshot.transcript,
            style: DesignSystem.titleLarge.copyWith(fontSize: 22, height: 1.4),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignSystem.vibeRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: DesignSystem.vibeRed, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Captured via Companion',
                style: DesignSystem.labelBold.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      backgroundColor: DesignSystem.background,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Reflections',
          style: DesignSystem.titleLarge.copyWith(fontSize: 24),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.auto_awesome,
                size: 200,
                color: DesignSystem.textSlateDeep.withValues(alpha: 0.02),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: DesignSystem.textSlateDeep),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic snapshot) {
    final baseColor = AppTheme.getMoodColor(snapshot.mood);
    final colors = [baseColor, baseColor.withValues(alpha: 0.5)];
    final moodColor = colors[0];    final dateStr = DateFormat('MMM dd, h:mm a').format(snapshot.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AppTheme.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    snapshot.mood.toUpperCase(),
                    style: DesignSystem.labelBold.copyWith(fontSize: 10, color: moodColor),
                  ),
                ),
                Text(
                  dateStr,
                  style: DesignSystem.labelMuted.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '"${snapshot.transcript}"',
              style: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateDeep, fontWeight: FontWeight.w700),
            ),
            if (snapshot.companionResponse != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignSystem.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: moodColor.withValues(alpha: 0.05)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_rounded, color: moodColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        snapshot.companionResponse!,
                        style: DesignSystem.bodyMedium.copyWith(fontSize: 14, color: DesignSystem.textSlateDeep, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
