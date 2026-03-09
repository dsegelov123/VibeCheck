import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';

class CompanionAvatar extends StatelessWidget {
  final String mood;
  final bool isRecording;
  final Stream<Amplitude>? amplitudeStream;

  const CompanionAvatar({
    super.key,
    required this.mood,
    this.isRecording = false,
    this.amplitudeStream,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Dynamic Aura
        _buildAura(mood),

        // 2. Listening Rings
        if (isRecording)
          _buildListeningRings()
              .animate()
              .fadeIn(duration: 400.ms),

        // 3. Main character card
        Center(
          child: Container(
            width: 320,
            height: 480,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(160),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(160),
              child: Stack(
                children: [
                  // Base Image with Crossfade Transition
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: Image.asset(
                        _getAvatarAsset(mood),
                        key: ValueKey<String>(_getAvatarAsset(mood)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Noise Texture (Premium Feel)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: NoisePainter(opacity: 0.08),
                    ),
                  ),

                  // Bottom Gradient Fade
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -15, end: 15, duration: 4.seconds, curve: Curves.easeInOutSine)
          .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 5.seconds, curve: Curves.easeInOutSine),
        ),
      ],
    );
  }

  Widget _buildAura(String mood) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getMoodColor(mood).withValues(alpha: 0.15),
            blurRadius: 100,
            spreadRadius: 30,
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(begin: const Offset(0.8, 0.8), end: Offset(1.2, 1.2), duration: 3.seconds, curve: Curves.easeInOutSine);
  }

  Widget _buildListeningRings() {
    return StreamBuilder<Amplitude>(
      stream: amplitudeStream,
      builder: (context, snapshot) {
        double expansion = 0.0;
        if (snapshot.hasData) {
          final amp = snapshot.data!.current;
          // Clamp amplitude from -50 (silence) to 0 (loud) -> 0.0 to 1.0
          expansion = ((amp + 50) / 50).clamp(0.0, 1.0);
        }

        return Stack(
          alignment: Alignment.center,
          children: List.generate(2, (index) {
            return Container(
              width: 340 + (index * 20).toDouble() + (expansion * 60),
              height: 500 + (index * 20).toDouble() + (expansion * 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(180),
                border: Border.all(
                  color: Colors.white.withValues(alpha: (0.2 - (index * 0.1)) + (expansion * 0.2)),
                  width: 2 + (expansion * 2),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat())
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeOut)
             .fadeOut(duration: 2.seconds);
          }),
        );
      }
    );
  }


  String _getAvatarAsset(String mood) {
    // Joyful spectrum
    if (['joy', 'excited', 'proud'].contains(mood)) {
      return 'images/expression_joyful.png';
    }
    // Deeply sad / struggling spectrum
    if (['sad', 'grieving', 'lonely'].contains(mood)) {
      return 'images/expression_concerned.png';
    }
    // High anxiety spectrum
    if (['anxious', 'overwhelmed', 'fearful'].contains(mood)) {
      return 'images/expression_reassuring.png';
    }
    // Calm / resting spectrum
    if (['calm', 'reflective', 'tired', 'bored'].contains(mood)) {
      return 'images/expression_serene.png';
    }
    // Agitated spectrum
    if (['angry', 'frustrated', 'annoyed'].contains(mood)) {
      return 'images/expression_attentive.png';
    }
    
    return 'images/expression_serene.png'; // Fallback
  }

  Color _getMoodColor(String mood) {
    if (['joy', 'excited', 'proud'].contains(mood)) return Colors.amber;
    if (['sad', 'grieving', 'lonely'].contains(mood)) return Colors.blue;
    if (['calm', 'reflective', 'tired', 'bored'].contains(mood)) return Colors.greenAccent;
    if (['anxious', 'overwhelmed', 'fearful', 'angry', 'frustrated', 'annoyed'].contains(mood)) return Colors.red;
    return Colors.white;
  }
}

class NoisePainter extends CustomPainter {
  final double opacity;
  NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final random = Random();
    for (int i = 0; i < 2000; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
