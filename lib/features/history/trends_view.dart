import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../../core/components/vibe_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/history_provider.dart';
// Removed unused imports

import '../../providers/emotional_weather_provider.dart';
import '../../models/emotional_snapshot.dart';

class TrendsView extends ConsumerStatefulWidget {
  const TrendsView({super.key});

  @override
  ConsumerState<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends ConsumerState<TrendsView> {
  int _selectedTab = 2; // 0 = Today, 1 = Specific, 2 = 7 days, 3 = 30 days
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now();
  late ScrollController _scrollerController;

  @override
  void initState() {
    super.initState();
    _scrollerController = ScrollController();
  }

  @override
  void dispose() {
    _scrollerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    
    return VibeScaffold(
      title: 'Weather Report',
      body: Container(
        color: DesignSystem.background,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildSectionLabel('Summary Period'),
                    const SizedBox(height: 12),
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildCalendar(history),
                    const SizedBox(height: 24),
                    _buildDailyWeatherScroller(history),
                    const SizedBox(height: 32),
                    _buildMainChart(history),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
     return Text(
      text,
      style: DesignSystem.label,
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: AppTheme.cardDecoration(
        borderRadius: BorderRadius.circular(16),
      ).copyWith(
        border: Border.all(color: DesignSystem.textDeep.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('TODAY', 0)),
          Expanded(child: _buildTabButton('SPECIFIC', 1)),
          Expanded(child: _buildTabButton('7 DAYS', 2)),
          Expanded(child: _buildTabButton('1 MONTH', 3)),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<EmotionalSnapshot> history) {
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday;
    final monthName = DateFormat('MMMM yyyy').format(_viewMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)),
              ),
              Text(monthName.toUpperCase(), style: DesignSystem.label),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1)),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7 + daysInMonth + (firstDayOfMonth - 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 6,
              childAspectRatio: 1.4, // Squashes the calendar cells vertically
            ),
            itemBuilder: (context, index) {
              if (index < 7) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Center(child: Text(days[index], style: DesignSystem.label));
              }
              
              final dayNum = index - 7 - (firstDayOfMonth - 2);
              if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();

              final date = DateTime(_viewMonth.year, _viewMonth.month, dayNum);
              final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
              final snapshots = history.where((s) => s.timestamp.year == date.year && s.timestamp.month == date.month && s.timestamp.day == date.day).toList();
              final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
              
              final style = snapshots.isEmpty ? null : DailyWeather.fromSnapshots(snapshots);
              final color = style?.primaryColor ?? DesignSystem.borderColor.withValues(alpha: 0.1);

              return GestureDetector(
                onTap: snapshots.isEmpty ? null : () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedDate = date;
                    _selectedTab = 1;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? DesignSystem.accent : (snapshots.isEmpty ? DesignSystem.textDeep.withValues(alpha: 0.05) : color),
                      width: isSelected ? 1.5 : 1.2,
                    ),
                    color: isSelected ? DesignSystem.accent.withValues(alpha: 0.1) : (isToday ? DesignSystem.accent.withValues(alpha: 0.05) : null),
                  ),
                  child: Center(
                    child: Text(
                      dayNum.toString(),
                        style: DesignSystem.label.copyWith(
                          color: snapshots.isEmpty ? DesignSystem.textMuted.withValues(alpha: 0.3) : DesignSystem.textDeep,
                          fontWeight: FontWeight.w400,
                        ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.02, end: 0);
  }

  Widget _buildMainChart(List<EmotionalSnapshot> history) {
    if (_selectedTab == 0 || _selectedTab == 1) {
      final date = _selectedTab == 0 ? DateTime.now() : _selectedDate;
      final dayHistory = history.where((s) => s.timestamp.year == date.year && s.timestamp.month == date.month && s.timestamp.day == date.day).toList();
      return _buildDonutChart(dayHistory, date);
    }
    
    final daysToShow = _selectedTab == 2 ? 7 : 30;
    final now = DateTime.now();

    final List<Map<String, dynamic>> chartData = List.generate(daysToShow, (index) {
      final date = now.subtract(Duration(days: (daysToShow - 1) - index));
      final dayHistory = history.where((s) => 
        s.timestamp.year == date.year && 
        s.timestamp.month == date.month && 
        s.timestamp.day == date.day
      ).toList();
      
      double heightFactor = 0.05;
      Color color = DesignSystem.textDeep.withValues(alpha: 0.05);
      IconData? weatherIcon;
      
      if (dayHistory.isNotEmpty) {
        final weather = DailyWeather.fromSnapshots(dayHistory);
        heightFactor = (0.2 + (dayHistory.length * 0.15)).clamp(0.2, 1.0);
        color = weather.primaryColor;
        weatherIcon = weather.icon;
      }
      return {
        'label': daysToShow == 7 
            ? DateFormat('E').format(date).toUpperCase().substring(0, 3)
            : (index % 5 == 0 ? DateFormat('d').format(date) : ''),
        'heightFactor': heightFactor,
        'color': color,
        'icon': weatherIcon,
      };
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(_selectedTab == 2 ? 'WEEKLY' : 'MONTHLY'),
          const SizedBox(height: 40),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((data) {
                return _buildBarItem(data);
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildDonutChart(List<EmotionalSnapshot> snapshots, DateTime date) {
    final weather = DailyWeather.fromSnapshots(snapshots);
    final dist = weather.aggregateDistribution;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          _buildChartHeader(DateFormat('EEEE, d MMMM').format(date).toUpperCase()),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (snapshots.isNotEmpty)
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: DonutPainter(distribution: dist),
                  )
                else
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignSystem.textDeep.withValues(alpha: 0.1), width: 2, style: BorderStyle.none),
                      color: DesignSystem.surface,
                    ),
                    child: Center(child: Text('NO DATA', style: DesignSystem.label)),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(weather.icon, size: 28, color: weather.primaryColor),
                    const SizedBox(height: 4),
                    Text(weather.name, style: DesignSystem.body),
                    if (weather.primaryTrigger != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: weather.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          weather.primaryTrigger!.toUpperCase(),
                          style: DesignSystem.label.copyWith(
                            color: weather.primaryColor,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(dist),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildBarItem(Map<String, dynamic> data) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: DesignSystem.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  heightFactor: data['heightFactor'],
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: data['color'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (data['icon'] != null)
             Icon(data['icon'], size: 10, color: data['color'])
          else
             const SizedBox(height: 10),
          const SizedBox(height: 4),
          Text(data['label'], style: DesignSystem.label),
        ],
      ).animate().scaleY(begin: 0, end: 1, duration: 800.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildChartHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: DesignSystem.label),
        Icon(Icons.auto_awesome_rounded, color: DesignSystem.accent.withValues(alpha: 0.3), size: 12),
      ],
    );
  }

  Widget _buildLegend(Map<String, double> dist) {
    if (dist.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: dist.entries.where((e) => e.value > 0.05).map((e) {
        final color = AppTheme.getMoodColor(e.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${e.key} ${(e.value * 100).toInt()}%', style: DesignSystem.label),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDailyWeatherScroller(List<EmotionalSnapshot> history) {
    final now = DateTime.now();
    const daysToShow = 365;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Weather Report by Day'),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _scrollerController.animateTo(
                  0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignSystem.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'TODAY',
                  style: DesignSystem.label.copyWith(
                    color: DesignSystem.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100, // Slightly shorter
          child: ListView.builder(
            controller: _scrollerController,
            scrollDirection: Axis.horizontal,
            reverse: true, // Today on the right
            padding: const EdgeInsets.symmetric(horizontal: 24), // Match page padding
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: daysToShow,
            itemBuilder: (context, index) {
              final date = now.subtract(Duration(days: index));
              final snapshots = history.where((s) => s.timestamp.year == date.year && s.timestamp.month == date.month && s.timestamp.day == date.day).toList();
              final weather = DailyWeather.fromSnapshots(snapshots);
              final hasData = snapshots.isNotEmpty;
              final isToday = index == 0;
              final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day && _selectedTab == 1;

              return GestureDetector(
                onTap: snapshots.isEmpty ? null : () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedDate = date;
                    _selectedTab = 1;
                  });
                },
                child: Container(
                  width: 68, // Smaller width to fit ~5-6 tiles
                  margin: const EdgeInsets.only(left: 10), // Consistent spacing
                  padding: const EdgeInsets.all(10),
                  decoration: AppTheme.cardDecoration(
                    color: isToday 
                        ? DesignSystem.accent.withValues(alpha: 0.1) 
                        : (hasData ? weather.primaryColor.withValues(alpha: 0.15) : DesignSystem.surface),
                    showBorder: true,
                  ).copyWith(
                    border: Border.all(
                      color: isSelected 
                          ? DesignSystem.accent 
                          : (isToday ? DesignSystem.accent.withValues(alpha: 0.3) : DesignSystem.borderColor.withValues(alpha: 0.1)),
                      width: isSelected || isToday ? 1.5 : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(weather.icon, size: 18, color: isToday ? DesignSystem.accent : weather.primaryColor),
                      const SizedBox(height: 6),
                      Text(
                        isToday ? 'TODAY' : DateFormat('EEE').format(date).toUpperCase(), 
                        style: DesignSystem.label.copyWith(
                          color: isToday ? DesignSystem.accent : DesignSystem.textDeep,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(date), 
                        style: DesignSystem.label,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTab = index;
          if (index == 0) {
            _selectedDate = DateTime.now();
            _viewMonth = DateTime(_selectedDate.year, _selectedDate.month);
          }
        });
      },
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.background : DesignSystem.background.withValues(alpha: 0.0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? DesignSystem.softShadow : [],
          border: isSelected ? Border.all(color: DesignSystem.textDeep.withValues(alpha: 0.05)) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: DesignSystem.label,
        ),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final Map<String, double> distribution;

  DonutPainter({required this.distribution});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (distribution.isEmpty) {
      paint.color = DesignSystem.borderColor.withValues(alpha: 0.2);
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -3.14 / 2;
    for (var entry in distribution.entries) {
      final sweepAngle = entry.value * 2 * 3.14;
      paint.color = AppTheme.getMoodColor(entry.key);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.02, // Tightened gap
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
