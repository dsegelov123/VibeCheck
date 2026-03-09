import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/history_provider.dart';
import '../../core/app_theme.dart';

class ReflectionView extends ConsumerWidget {
  const ReflectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          if (history.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No memories captured yet.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
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
    final colors = AppTheme.getMoodGradient(snapshot.mood);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0],
            colors[1].withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LATEST REFLECTION',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            snapshot.transcript,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Captured via Finn',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: const Text(
          'Reflections',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.auto_awesome,
                size: 200,
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic snapshot) {
    final colors = AppTheme.getMoodGradient(snapshot.mood);
    final dateStr = DateFormat('MMM dd, h:mm a').format(snapshot.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(opacity: 0.6).copyWith(
              border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors[0], colors[1]],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        snapshot.mood.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Text(
                  '"${snapshot.transcript}"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (snapshot.companionResponse != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors[0].withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors[0].withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.psychology_rounded, color: colors[0], size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            snapshot.companionResponse!,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
