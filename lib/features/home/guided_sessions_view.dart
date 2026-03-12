import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../../core/components/vibe_scaffold.dart';
import '../../providers/content_provider.dart';
import '../../models/meditation_session.dart';
import 'meditation_detail_view.dart';

class GuidedSessionsView extends ConsumerStatefulWidget {
  const GuidedSessionsView({super.key});

  @override
  ConsumerState<GuidedSessionsView> createState() => _GuidedSessionsViewState();
}

class _GuidedSessionsViewState extends ConsumerState<GuidedSessionsView> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(meditationSessionsProvider);

    return VibeScaffold(
      title: 'Mindfulness',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ],
      body: sessionsAsync.when(
        data: (sessions) {
          final allCategories = ['All', ...sessions.map((e) => e.category).toSet().toList()..sort()];
          
          final filteredSessions = sessions.where((s) {
            final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty || 
                s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.description.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignSystem.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DesignSystem.borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: DesignSystem.body,
                      decoration: InputDecoration(
                        hintText: 'Search sessions...',
                        hintStyle: DesignSystem.body.copyWith(color: DesignSystem.textMuted),
                        prefixIcon: Icon(Icons.search_rounded, color: DesignSystem.textMuted, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),

              if (_searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 12),
                    child: Text('FOR YOU', style: DesignSystem.label),
                  ),
                ),
                // Horizontal For You list
                SliverToBoxAdapter(
                  child: SizedBox(
                     height: 140,
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       itemCount: sessions.take(5).length, 
                       itemBuilder: (context, index) {
                         final session = sessions[index];
                         return Padding(
                           padding: const EdgeInsets.only(right: 12),
                           child: _buildFeaturedCard(context, session, index),
                         );
                       },
                     ),
                  ),
                ),
              ],
              // Category Filter list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                         final category = allCategories[index];
                         final isSelected = _selectedCategory == category;
                         return Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: GestureDetector(
                             onTap: () {
                                setState(() => _selectedCategory = category);
                             },
                             child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: AppTheme.cardDecoration(
                                  color: isSelected ? DesignSystem.accent.withValues(alpha: 0.1) : DesignSystem.surface,
                                ).copyWith(
                                  border: Border.all(
                                    color: isSelected ? DesignSystem.accent.withValues(alpha: 0.3) : DesignSystem.borderColor,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  category.toUpperCase(),
                                  style: DesignSystem.label,
                                ),
                             ),
                           ),
                         );
                      },
                    ),
                  ),
                ),
              ),
              // Grid View for all library items
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = filteredSessions[index];
                    return _buildStandardCard(context, session, index);
                  },
                  childCount: filteredSessions.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: DesignSystem.error))),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, MeditationSession session, int index) {
    final String hexString = session.colors.isNotEmpty ? session.colors.first : '#FF686B';
    final Color baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MeditationDetailView(session: session),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(color: baseColor.withValues(alpha: 0.1)).copyWith(
          border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECOMMENDED',
                  style: DesignSystem.label,
                ),
                Icon(Icons.play_circle_fill_rounded, color: baseColor, size: 24),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: DesignSystem.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.durationMinutes} min • ${session.category}',
                  style: DesignSystem.label,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardCard(BuildContext context, MeditationSession session, int index) {
    final String hexString = session.colors.isNotEmpty ? session.colors.first : '#A0C4FF';
    final Color baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MeditationDetailView(session: session),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.1), 
                shape: BoxShape.circle
              ),
              child: Icon(Icons.spa_rounded, color: baseColor, size: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: DesignSystem.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  session.category,
                  style: DesignSystem.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 10, color: DesignSystem.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${session.durationMinutes} min',
                      style: DesignSystem.label,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
