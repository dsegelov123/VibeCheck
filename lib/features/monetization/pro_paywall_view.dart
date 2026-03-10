import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Premium Light Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Color(0xFFFFFBEB), // Light Amber
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Icon/Badge
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.stars_rounded, color: Color(0xFF92400E), size: 72),
                ).animate(onPlay: (c) => c.repeat())
                 .shimmer(duration: 2.seconds, color: Colors.white70),

                const SizedBox(height: 48),
                
                const Text(
                  'VibeCheck Pro',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Deepen your emotional connection.',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 16,
                  ),
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
                      const Text(
                        '£4.99 / MONTH',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.3),
                          ),
                          onPressed: _isLoading ? null : _handlePurchase,
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                            : const Text(
                                'START 7-DAY FREE TRIAL',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _handleRestore,
                        child: const Text(
                          'Restore Purchase',
                          style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
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
              icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B), size: 32),
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
          Icon(icon, color: const Color(0xFF92400E), size: 28),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1E293B), 
                fontSize: 16, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
