import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../../providers/content_provider.dart';
import '../../models/meditation_session.dart';
import 'meditation_detail_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        title: Text('Mindfulness Library', style: DesignSystem.titleLarge),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: DesignSystem.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: DesignSystem.textSlateDeep),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignSystem.textSlateDeep.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: DesignSystem.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search sessions...',
                        hintStyle: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: DesignSystem.textSlateMuted),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),

              if (_searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 24, bottom: 16),
                    child: Text('For You', style: DesignSystem.titleMedium),
                  ),
                ),
                // Horizontal For You list
                SliverToBoxAdapter(
                  child: SizedBox(
                     height: 180,
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       padding: const EdgeInsets.symmetric(horizontal: 24),
                       itemCount: sessions.take(5).length, 
                       itemBuilder: (context, index) {
                         final session = sessions[index];
                         return Padding(
                           padding: const EdgeInsets.only(right: 16),
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
                  padding: const EdgeInsets.only(top: 32, bottom: 24),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                         final category = allCategories[index];
                         final isSelected = _selectedCategory == category;
                         return Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: GestureDetector(
                             onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = category);
                             },
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                               decoration: BoxDecoration(
                                  color: isSelected ? DesignSystem.vibeRed : DesignSystem.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? Colors.transparent : DesignSystem.textSlateDeep.withValues(alpha: 0.1)),
                               ),
                               alignment: Alignment.center,
                               child: Text(
                                 category,
                                 style: DesignSystem.labelBold.copyWith(
                                    color: isSelected ? Colors.white : DesignSystem.textSlateDeep
                                 ),
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
              SliverPadding(
                 padding: const EdgeInsets.symmetric(horizontal: 24),
                 sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final session = filteredSessions[index];
                        return _buildStandardCard(context, session, index);
                      },
                      childCount: filteredSessions.length,
                    ),
                 ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: DesignSystem.vibeRed)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: DesignSystem.errorRed))),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, MeditationSession session, int index) {
     final String hexString = session.colors.isNotEmpty ? session.colors.first : '#F02D3A';
     final Color baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));

     return GestureDetector(
        onTap: () {
           HapticFeedback.lightImpact();
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MeditationDetailView(session: session),
            ),
          );
        },
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
             gradient: LinearGradient(
               colors: [baseColor, baseColor.withValues(alpha: 0.7)],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             borderRadius: BorderRadius.circular(24),
             boxShadow: [
               BoxShadow(
                 color: baseColor.withValues(alpha: 0.3),
                 blurRadius: 16,
                 offset: const Offset(0, 8),
               )
             ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.2),
                         borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('RECOMMENDED', style: DesignSystem.labelBold.copyWith(color: Colors.white, fontSize: 10)),
                    ),
                    const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                 ],
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                      session.title,
                      style: DesignSystem.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.durationMinutes} min • ${session.category}',
                      style: DesignSystem.labelMuted.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                 ],
               ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0),
     );
  }

  Widget _buildStandardCard(BuildContext context, MeditationSession session, int index) {
      final String hexString = session.colors.isNotEmpty ? session.colors.first : '#F02D3A';
      final Color baseColor = Color(int.parse(hexString.replaceAll('#', '0xFF')));

      return GestureDetector(
        onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MeditationDetailView(session: session),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(color: DesignSystem.background).copyWith(
            border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.1), 
                    shape: BoxShape.circle
                ),
                child: Icon(Icons.spa_rounded, color: baseColor, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: DesignSystem.bodyMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: DesignSystem.textSlateDeep),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.category,
                    style: DesignSystem.labelMuted.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: DesignSystem.textSlateMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                        Icon(Icons.access_time_rounded, size: 12, color: DesignSystem.textSlateMuted),
                        const SizedBox(width: 4),
                        Text(
                        '${session.durationMinutes} min',
                        style: DesignSystem.labelMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: ((index % 4) * 50).ms).scale(begin: const Offset(0.95, 0.95)),
      );
  }
}
