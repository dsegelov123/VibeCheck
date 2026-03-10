import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../models/companion_persona.dart';
import '../../core/app_theme.dart';
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
      backgroundColor: const Color(0xFFF8FAFC), // Very light gray background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Companions',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
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
              const Text(
                'Recently Active',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentCompanionCard(context, recentPersona),
              
              const SizedBox(height: 32),
              
              // 2. Free Companions
              const Text(
                'Free Companions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
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
                  const Text(
                    'Premium Companions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                       color: Colors.amber.shade100,
                       borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Deep Indigo
              Color(0xFF818CF8), // Medium Indigo
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
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
                  color: Colors.white24,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white), // Placeholder until images
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'CONTINUE TALKING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    persona.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to jump back in...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 32),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${persona.id}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9), // Slate 100
                  border: Border.all(color: Colors.black12, width: 1),
                ),
                child: const Icon(Icons.person, size: 30, color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.name,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        persona.role,
                        style: const TextStyle(
                          color: Color(0xFF6366F1), // Indigo
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
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
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.3,
                    ),
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
