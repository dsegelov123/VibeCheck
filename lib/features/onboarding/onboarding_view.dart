import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/dashboard_view.dart';
import '../monetization/pro_paywall_view.dart';
import '../../core/app_theme.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  )
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
                    color: const Color(0xFF6366F1), // Indigo
                  ),
                  _buildPage(
                    title: 'Meet Your Companions',
                    subtitle: 'Chat with specialized AI personas—from a gentle listener to a fierce motivation coach.',
                    icon: Icons.forum_rounded,
                    color: const Color(0xFF10B981), // Emerald
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
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _onNext,
                  child: Text(
                    _currentPage == 2 ? 'ENTER APP' : 'CONTINUE',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              height: 1.1,
              letterSpacing: -1,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.5,
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
          const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
          const SizedBox(height: 32),
          const Text(
            'Unlock VibeCheck PRO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Go deeper with 10 additional expert AI companions, infinite memory, and advanced emotional insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade100,
                foregroundColor: Colors.amber.shade900,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             ),
             onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProPaywallView()));
             }, 
             icon: const Icon(Icons.workspace_premium_rounded),
             label: const Text('VIEW PRO TRIAL PLANS', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}
