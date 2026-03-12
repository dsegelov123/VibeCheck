import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../models/companion_persona.dart';
import '../../core/design_system.dart';
import 'voice_call_view.dart';
import 'package:record/record.dart';

class DialingView extends ConsumerStatefulWidget {
  final CompanionPersona persona;

  const DialingView({super.key, required this.persona});

  @override
  ConsumerState<DialingView> createState() => _DialingViewState();
}

class _DialingViewState extends ConsumerState<DialingView> {
  Timer? _hapticTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _startDialing();
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startDialing() async {
    // Simulate a Skype-like soft pulsing ring rhythm using haptics
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
       HapticFeedback.lightImpact();
       Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.lightImpact());
    });

    // Request Mic Permissions in the background
    bool hasPermission = await _audioRecorder.hasPermission();

    // Enforce minimum 3.5s wait for UI visual
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;
    
    _hapticTimer?.cancel();

    if (hasPermission) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => VoiceCallView(persona: widget.persona),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      // Permission denied fallback
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required for voice calls.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing rings
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DesignSystem.accent.withValues(alpha: 0.05),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.8, 1.8), duration: 1500.ms, curve: Curves.easeOut)
                   .fadeOut(duration: 1500.ms),
                   
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DesignSystem.accent.withValues(alpha: 0.1),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4), duration: 1500.ms, delay: 400.ms, curve: Curves.easeOut)
                   .fadeOut(duration: 1500.ms, delay: 400.ms),

                  // Avatar
                  Hero(
                    tag: 'avatar_${widget.persona.id}',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignSystem.accent.withValues(alpha: 0.1),
                        border: Border.all(color: DesignSystem.accent.withValues(alpha: 0.2), width: 3),
                        boxShadow: [
                           BoxShadow(
                             color: DesignSystem.accent.withValues(alpha: 0.15),
                             blurRadius: 20,
                             spreadRadius: 5,
                           )
                        ],
                      ),
                      child: Icon(Icons.person, size: 60, color: DesignSystem.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'Calling...',
                style: DesignSystem.label.copyWith(
                  letterSpacing: 2,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms).fadeOut(duration: 800.ms),
              const SizedBox(height: 8),
              Text(
                widget.persona.name,
                style: DesignSystem.h1,
              ),
              const SizedBox(height: 120),
              // End Call Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DesignSystem.accent,
                    shape: BoxShape.circle,
                    boxShadow: DesignSystem.softShadow,
                  ),
                  child: Icon(Icons.call_end_rounded, color: DesignSystem.surface, size: 32),
                ),
              ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
