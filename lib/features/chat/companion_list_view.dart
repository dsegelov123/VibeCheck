import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../../core/components/vibe_scaffold.dart';
import '../../models/companion_persona.dart';
import 'companion_chat_view.dart';
import '../monetization/pro_paywall_view.dart';
import '../../core/subscription_service.dart';

class CompanionListView extends ConsumerWidget {
  const CompanionListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, this would come from a provider tracking the last active chat
    final recentPersona = CompanionPersona.maya; 
    
    // Check if the user has an active Pro subscription
    final isPro = ref.watch(isProProvider);

    return VibeScaffold(
      title: 'Companions',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 1. "Continue Talking" Hero Card
            _buildSectionLabel('RECENTLY ACTIVE'),
            const SizedBox(height: 12),
            _buildRecentCompanionCard(context, recentPersona),
            
            const SizedBox(height: 24),
            
            // 2. Free Companions
            _buildSectionLabel('FREE COMPANIONS'),
            const SizedBox(height: 12),
            ...CompanionPersona.freeCompanions.where((p) => p.id != recentPersona.id).map((persona) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildContactRow(context, persona, isPro),
              );
            }),

            const SizedBox(height: 12),

            // 3. Premium Companions (Pro)
            Row(
              children: [
                _buildSectionLabel('PREMIUM'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DesignSystem.premiumSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('PRO', style: DesignSystem.label.copyWith(color: DesignSystem.premiumAccent)),
                )
              ],
            ),
            const SizedBox(height: 12),
            ...CompanionPersona.premiumCompanions.where((p) => p.id != recentPersona.id).map((persona) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildContactRow(context, persona, isPro),
              );
            }),
            const SizedBox(height: 80), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: DesignSystem.label.copyWith(letterSpacing: 1.2),
    );
  }

  Widget _buildRecentCompanionCard(BuildContext context, CompanionPersona persona) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CompanionChatView(persona: persona)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${persona.id}',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.moodColors['joy']?.withValues(alpha: 0.1) ?? DesignSystem.accent.withValues(alpha: 0.1),
                  border: Border.all(color: DesignSystem.borderColor, width: 1),
                ),
                child: const Icon(Icons.person, size: 30, color: DesignSystem.accent), 
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE TALKING',
                    style: DesignSystem.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persona.name,
                    style: DesignSystem.h2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to jump back in...',
                    style: DesignSystem.label,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: DesignSystem.textMuted, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, CompanionPersona persona, bool isPro) {
    final isLocked = persona.isPremium && !isPro;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
           Navigator.of(context).push(
             MaterialPageRoute(builder: (_) => const ProPaywallView()),
           );
        } else {
           Navigator.of(context).push(
             MaterialPageRoute(builder: (_) => CompanionChatView(persona: persona)),
           );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${persona.id}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.background,
                  border: Border.all(color: DesignSystem.borderColor, width: 1),
                ),
                child: Icon(Icons.person, size: 24, color: DesignSystem.textMuted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.name,
                    style: DesignSystem.body,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        persona.role,
                        style: DesignSystem.label,
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock_rounded, size: 10, color: DesignSystem.premium),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persona.description,
                    style: DesignSystem.label.copyWith(color: DesignSystem.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Icon(Icons.star_rounded, color: DesignSystem.premiumGold, size: 18)
            else
              const Icon(Icons.chevron_right_rounded, color: DesignSystem.borderColor, size: 20),
          ],
        ),
      ),
    );
  }
}
