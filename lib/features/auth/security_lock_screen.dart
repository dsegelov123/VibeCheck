import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../core/security_service.dart';
import '../home/dashboard_view.dart';

class SecurityLockScreen extends ConsumerStatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  ConsumerState<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends ConsumerState<SecurityLockScreen> {
  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final success = await ref.read(securityServiceProvider).authenticate();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: DesignSystem.authGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: DesignSystem.onAccent),
            const SizedBox(height: 24),
            Text(
              'Locked',
              style: DesignSystem.h1.copyWith(color: DesignSystem.onAccent),
            ),
            const SizedBox(height: 12),
            Text(
              'Please authenticate to unlock VibeCheck',
              style: DesignSystem.body.copyWith(color: DesignSystem.onAccent.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.onAccent,
                foregroundColor: DesignSystem.brandIndigo,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonRadius)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
