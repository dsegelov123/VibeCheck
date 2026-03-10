import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth_service.dart';
import '../home/dashboard_view.dart';
import '../../core/app_theme.dart';
import '../../core/security_service.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEEF2FF),
              const Color(0xFFF5F3FF),
              const Color(0xFFFDF2F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo & Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 64,
                    color: Color(0xFF6366F1),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'Welcome to VibeCheck',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        color: const Color(0xFF1E293B),
                      ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Your companion for emotional clarity.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ).animate().fadeIn(delay: 400.ms),
                const Spacer(),
                
                // Login Buttons
                _buildSocialButton(
                  context: context,
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  onPressed: () => _handleLogin(context, ref, 'google'),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 12),
                _buildSocialButton(
                  context: context,
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  onPressed: () => _handleLogin(context, ref, 'apple'),
                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 12),
                _buildSocialButton(
                  context: context,
                  label: 'Continue with Email',
                  icon: Icons.email_outlined,
                  onPressed: () => _handleLogin(context, ref, 'email'),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 32),
                
                // Skip Link
                TextButton(
                  onPressed: () => _handleSkip(context, ref),
                  child: Text(
                    'Ignore for now',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('AuthScreen: Social button tapped: $label');
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, WidgetRef ref, String method) async {
    debugPrint('AuthScreen: Login initiated with method: $method');
    await ref.read(authServiceProvider.notifier).login();
    if (!context.mounted) return;

    // Check if security setup is possible
    final securityService = ref.read(securityServiceProvider);
    debugPrint('AuthScreen: Checking if security setup is possible...');
    bool canSecure = false;
    try {
      canSecure = await securityService.canCheckBiometrics();
    } catch (e) {
      debugPrint('AuthScreen: Security check failed (expected on some platforms): $e');
    }
    debugPrint('AuthScreen: canSecure = $canSecure');

    if (canSecure && context.mounted) {
      debugPrint('AuthScreen: Showing security setup.');
      _showSecuritySetup(context, ref);
    }
    // No need to navigate here, the root VibeCheckApp watches authServiceProvider
  }

  void _showSecuritySetup(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 24),
            Text(
              'Secure Your Conversations?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use your device biometrics or passcode to keep your chats private. This will be required every time you open the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final securityService = ref.read(securityServiceProvider);
                  final success = await securityService.authenticate();
                  if (success) {
                    await securityService.setSecurityEnabled(true);
                    if (context.mounted) _navigateToDashboard(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Enable Secure Access', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _navigateToDashboard(context),
              child: const Text('Maybe Later', style: TextStyle(color: Color(0xFF64748B))),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardView()),
    );
  }

  void _handleSkip(BuildContext context, WidgetRef ref) async {
    debugPrint('AuthScreen: User chose to skip auth for this session.');
    await ref.read(authServiceProvider.notifier).skipAuth();
    // No need to navigate here, the root VibeCheckApp watches authServiceProvider
  }
}
