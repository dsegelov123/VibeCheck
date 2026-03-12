import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import '../auth/auth_screen.dart';
import '../monetization/pro_paywall_view.dart';
import '../../core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});
  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    debugPrint('OnboardingView: Finishing onboarding...');
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    // The root VibeCheckApp watches onboardingProvider and will switch to AuthScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? DesignSystem.brandIndigo
                              : DesignSystem.textDeep.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _onNext,
                    child: Text('Skip', style: DesignSystem.label),
                  ),
                ],
              ),
            ),
            
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Welcome to VibeCheck',
                    subtitle: 'Track your emotional weather and find clarity in the chaos of daily life.',
                    icon: Icons.auto_awesome_rounded,
                    color: DesignSystem.brandIndigo,
                  ),
                  _buildPage(
                    title: 'Meet Your Companions',
                    subtitle: 'Chat with specialized AI personas—from a gentle listener to a fierce motivation coach.',
                    icon: Icons.forum_rounded,
                    color: DesignSystem.success,
                  ),
                  _buildSoftPaywallPage(),
                ],
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.textDeep,
                    foregroundColor: DesignSystem.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonRadius)),
                  ),
                  onPressed: _onNext,
                  child: Text(
                    _currentPage == 2 ? 'ENTER APP' : 'CONTINUE',
                    style: DesignSystem.body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DesignSystem.h1,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DesignSystem.body.copyWith(
              color: DesignSystem.textMuted,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSoftPaywallPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars_rounded, size: 80, color: DesignSystem.premium),
          const SizedBox(height: 32),
          Text(
            'Unlock VibeCheck PRO',
            textAlign: TextAlign.center,
            style: DesignSystem.h1,
          ),
          const SizedBox(height: 16),
          Text(
            'Go deeper with 10 additional expert AI companions, infinite memory, and advanced emotional insights.',
            textAlign: TextAlign.center,
            style: DesignSystem.body.copyWith(color: DesignSystem.textMuted),
          ),
          const SizedBox(height: 40),
          
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.premium.withValues(alpha: 0.1),
                foregroundColor: DesignSystem.premium,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             ),
             onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProPaywallView()));
             }, 
             icon: const Icon(Icons.workspace_premium_rounded),
             label: Text('VIEW PRO TRIAL PLANS', style: DesignSystem.label),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}
