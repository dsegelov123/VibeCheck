import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/subscription_service.dart';
import '../home/dashboard_view.dart';

class ProPaywallView extends ConsumerStatefulWidget {
  const ProPaywallView({super.key});

  @override
  ConsumerState<ProPaywallView> createState() => _ProPaywallViewState();
}

class _ProPaywallViewState extends ConsumerState<ProPaywallView> {
  bool _isLoading = false;

  void _handlePurchase() async {
    setState(() => _isLoading = true);
    final service = ref.read(subscriptionServiceProvider);
    final success = await service.purchasePro();
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardView()),
        (route) => false,
      );
    }
  }

  void _handleRestore() async {
    setState(() => _isLoading = true);
    final service = ref.read(subscriptionServiceProvider);
    final success = await service.restorePurchases();
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardView()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscription found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: DesignSystem.premiumBackground),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration(
                    shape: BoxShape.circle,
                    color: DesignSystem.premium.withValues(alpha: 0.1),
                    showBorder: true,
                  ).copyWith(
                    border: Border.all(color: DesignSystem.premium.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(Icons.stars_rounded, color: DesignSystem.premiumAccent.withValues(alpha: 0.8), size: 72),
                ).animate(onPlay: (c) => c.repeat())
                 .shimmer(duration: 2.seconds, color: DesignSystem.onAccent.withValues(alpha: 0.5)),

                const SizedBox(height: 48),
                
                Text(
                  'VibeCheck Pro',
                  style: DesignSystem.h1,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Deepen your emotional connection.',
                  style: DesignSystem.body.copyWith(color: DesignSystem.textMuted),
                ),

                const SizedBox(height: 64),

                // Features
                _buildFeatureRow(Icons.face_retouching_natural, 'Unlock 4+ Premium Avatars'),
                _buildFeatureRow(Icons.psychology_alt, 'Infinite Emotional Memory'),
                _buildFeatureRow(Icons.auto_graph_rounded, 'Advanced Sentiment Insights'),
                _buildFeatureRow(Icons.support_agent, 'Priority UK Support Access'),

                const Spacer(),

                // Price & CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      Text(
                        '£4.99 / MONTH',
                        style: DesignSystem.h2.copyWith(
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.textDeep,
                            foregroundColor: DesignSystem.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonRadius)),
                            elevation: 8,
                            shadowColor: DesignSystem.textDeep.withValues(alpha: 0.3),
                          ),
                          onPressed: _isLoading ? null : _handlePurchase,
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: DesignSystem.onAccent))
                            : Text(
                                'START 7-DAY FREE TRIAL',
                                style: DesignSystem.body,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _handleRestore,
                        child: Text(
                          'Restore Purchase',
                          style: DesignSystem.label,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: 60,
            right: 24,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close_rounded, color: DesignSystem.textDeep, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: DesignSystem.premiumAccent, size: 28),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              text,
              style: DesignSystem.body,
            ),
          ),
        ],
      ),
    );
  }
}
