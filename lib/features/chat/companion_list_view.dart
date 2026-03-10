import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../models/companion_persona.dart';
import '../../core/design_system.dart';
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

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        title: Text('Companions', style: DesignSystem.titleLarge),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: DesignSystem.textSlateDeep),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. "Continue Talking" Hero Card
              _buildSectionLabel('Recently Active'),
              const SizedBox(height: 12),
              _buildRecentCompanionCard(context, recentPersona),
              
              const SizedBox(height: 32),
              
              // 2. Free Companions
              _buildSectionLabel('Free Companions'),
              const SizedBox(height: 12),
              ...CompanionPersona.freeCompanions.where((p) => p.id != recentPersona.id).map((persona) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildContactRow(context, persona, isPro),
                );
              }),

              const SizedBox(height: 16),

              // 3. Premium Companions (Pro)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   _buildSectionLabel('Premium'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                       color: Colors.amber.shade100,
                       borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('PRO', style: DesignSystem.labelBold.copyWith(fontSize: 10, color: Colors.amber.shade900)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              ...CompanionPersona.premiumCompanions.where((p) => p.id != recentPersona.id).map((persona) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildContactRow(context, persona, isPro),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
     return Text(
      text,
      style: DesignSystem.labelMuted.copyWith(fontWeight: FontWeight.w700),
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
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration(color: DesignSystem.background).copyWith(
          border: Border.all(color: DesignSystem.vibeRed.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${persona.id}',
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.vibeRedLight,
                  border: Border.all(color: DesignSystem.vibeRed.withValues(alpha: 0.1), width: 2),
                ),
                child: const Icon(Icons.person, size: 40, color: DesignSystem.vibeRed), 
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignSystem.vibeRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'CONTINUE TALKING',
                      style: DesignSystem.labelBold.copyWith(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    persona.name,
                    style: DesignSystem.titleLarge.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to jump back in...',
                    style: DesignSystem.labelMuted,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DesignSystem.vibeRed, size: 32),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildContactRow(BuildContext context, CompanionPersona persona, bool isPro) {
    final isLocked = persona.isPremium && !isPro;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${persona.id}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.background,
                  border: Border.all(color: DesignSystem.textSlateDeep.withValues(alpha: 0.05), width: 1),
                ),
                child: Icon(Icons.person, size: 30, color: DesignSystem.vibeRed.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.name,
                    style: DesignSystem.titleLarge.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        persona.role,
                        style: DesignSystem.labelBold.copyWith(fontSize: 11),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persona.description,
                    style: DesignSystem.bodyMedium.copyWith(fontSize: 13, color: DesignSystem.textSlateMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isLocked)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.black12, size: 24),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }
}
