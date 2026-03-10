import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../../providers/content_provider.dart';
import '../../core/design_system.dart';
import 'meditation_detail_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuidedSessionsView extends ConsumerWidget {
  const GuidedSessionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(meditationSessionsProvider);

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        title: Text('Guided Sessions', style: DesignSystem.titleLarge),
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
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
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
                          const SizedBox(height: 6),
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
                ).animate().fadeIn(delay: (index * 100).ms).scale(begin: const Offset(0.95, 0.95)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: DesignSystem.vibeRed)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: DesignSystem.errorRed))),
      ),
    );
  }
}
