import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
        background: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: Color(0xFF1E293B),
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
            height: 1.5,
          ),
          labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  // Glassmorphic Style Utility (Light Mode - "Frosted Glass")
  static BoxDecoration glassDecoration({
    double opacity = 0.4,
    BorderRadius? borderRadius,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(24)),
      shape: shape,
      border: Border.all(color: Colors.white.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ],
    );
  }

  // Mood-based Gradients (Pastel Tones)
  static List<Color> getMoodGradient(String mood) {
    switch (mood) {
      case 'joy':
        return [const Color(0xFFFEF9C3), const Color(0xFFFEF08A), const Color(0xFFFDE68A)]; // Soft Yellow/Gold
      case 'sad':
        return [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE), const Color(0xFF93C5FD)]; // Pale Blue
      case 'calm':
        return [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0), const Color(0xFFA7F3D0)]; // Soft Mint
      case 'anxious':
        return [const Color(0xFFFEE2E2), const Color(0xFFFECACA), const Color(0xFFFCA5A5)]; // Blush Pink
      default:
        return [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]; // Slate White
    }
  }

  static Color getMoodColor(String mood) {
    switch (mood) {
      case 'joy': return const Color(0xFFFEF08A);
      case 'sad': return const Color(0xFF93C5FD);
      case 'calm': return const Color(0xFFBBF7D0);
      case 'anxious': return const Color(0xFFFECACA);
      default: return const Color(0xFFE2E8F0);
    }
  }
}
