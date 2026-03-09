import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vibe_check_mobile/core/safety_service.dart';
import 'package:vibe_check_mobile/core/app_theme.dart';

class SafetyNudge extends StatelessWidget {
  const SafetyNudge({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(opacity: 0.7).copyWith(
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Thinking of you. We\'re here if things feel heavy.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: BorderSide(color: const Color(0xFF1E293B).withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => SafetyService().openSamaritansWeb(),
                      child: const Text('RESOURCES'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      onPressed: () => SafetyService().callSamaritans(),
                      child: const Text('CALL NOW', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
