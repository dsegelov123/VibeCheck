import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/history_provider.dart';
import '../../core/app_theme.dart';
import 'reflection_view.dart';
import '../home/dashboard_view.dart';

class TrendsView extends ConsumerStatefulWidget {
  const TrendsView({super.key});

  @override
  ConsumerState<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends ConsumerState<TrendsView> {
  int _selectedTab = 0; // 0 = 7 days, 1 = 30 days

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 32),
                  _buildMainChart(history),
                  const SizedBox(height: 32),
                  _buildMoodDistribution(history),
                  const SizedBox(height: 32),
                  _buildInsightsList(history),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReflectionView()),
        ),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.history_rounded, color: Colors.white),
        label: const Text('View Journal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: const Text(
          'Emotional Weather',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('7 D', 0)),
          Expanded(child: _buildTabButton('1 M', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(dynamic history) {
    final daysToShow = _selectedTab == 0 ? 7 : 30;
    final now = DateTime.now();

    final List<Map<String, dynamic>> chartData = List.generate(daysToShow, (index) {
      final date = now.subtract(Duration(days: (daysToShow - 1) - index));
      final dayHistory = history.where((s) => 
        s.timestamp.year == date.year && 
        s.timestamp.month == date.month && 
        s.timestamp.day == date.day
      ).toList();
      
      double heightFactor = 0.05;
      Color color = Colors.grey.shade200;
      
      if (dayHistory.isNotEmpty) {
        final latest = dayHistory.first; 
        heightFactor = (0.2 + (dayHistory.length * 0.15)).clamp(0.2, 1.0);
        color = AppTheme.getMoodColor(latest.mood);
      }
      return {
        'label': daysToShow == 7 
            ? DateFormat('E').format(date).substring(0, 3)
            : (index % 5 == 0 ? DateFormat('d').format(date) : ''),
        'heightFactor': heightFactor,
        'color': color,
      };
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
              Text(
                _selectedTab == 0 ? 'This Week' : 'This Month',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
              ),
              const Icon(Icons.show_chart_rounded, color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((data) {
                return _buildHatchedBar(data['label'], data['heightFactor'], data['color'], daysToShow);
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildHatchedBar(String label, double heightFactor, Color color, int totalDays) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: totalDays == 7 ? 24 : 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: HatchedPainter(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ).animate().scaleY(begin: 0, end: 1, duration: 1.seconds, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 14,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodDistribution(dynamic history) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Calculate percentage breakdown
    final Map<String, int> counts = {'joy': 0, 'calm': 0, 'sad': 0, 'anxious': 0};
    final now = DateTime.now();
    final daysToFilter = _selectedTab == 0 ? 7 : 30;
    final filteredHistory = history.where((s) => now.difference(s.timestamp).inDays < daysToFilter).toList();

    if (filteredHistory.isEmpty) return const SizedBox.shrink();

    for (var s in filteredHistory) {
      if (counts.containsKey(s.mood)) {
        counts[s.mood] = counts[s.mood]! + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood Distribution',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: counts.entries.map((e) {
            final percentage = (e.value / filteredHistory.length * 100).toInt();
            return _buildDistributionBubble(e.key, percentage);
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDistributionBubble(String mood, int percentage) {
    final color = AppTheme.getMoodColor(mood);
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$percentage%',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            mood.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9, color: Color(0xFF64748B), letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(dynamic history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Insights',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: Icons.wb_sunny_rounded,
          color: Colors.amber,
          title: 'Morning Momentum',
          description: 'You tend to log "joy" primarily before 10 AM. Capturing these moments is setting a positive tone for your days.',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.nightlight_round,
          color: Colors.indigo,
          title: 'Evening Unwind',
          description: 'Your recent evenings show an increase in "calm", suggesting your new meditation routines are effectively lowering stress.',
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildInsightCard({required IconData icon, required Color color, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
