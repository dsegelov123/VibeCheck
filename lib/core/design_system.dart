import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // 1. Primary Colors (Stark White & Vibe Red)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color vibeRed = Color(0xFFF02D3A);
  static const Color vibeRedLight = Color(0xFFFFEAEA);
  static const Color vibeRedDark = Color(0xFFC41E28);

  // 2. Functional & Pastel Colors
  static const Color textSlateDeep = Color(0xFF0F172A);
  static const Color textSlateMuted = Color(0xFF64748B);
  static const Color safeMint = Color(0xFFE0F7FA);
  static const Color openLavender = Color(0xFFF3E5F5);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  // 3. Vibe Gradients (Pastel-Based)
  static LinearGradient safeGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
  );

  static LinearGradient openGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
  );

  static LinearGradient pulseGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // 4. Glassmorphism Tokens (Optimized for White Background)
  static BoxDecoration glassFrosted = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.7),
    border: Border.all(color: textSlateDeep.withValues(alpha: 0.05), width: 1.0),
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
  );

  static BoxDecoration glassClear = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.4),
    border: Border.all(color: textSlateDeep.withValues(alpha: 0.03), width: 1.0),
    borderRadius: BorderRadius.circular(24),
  );

  // 5. Typography (Outfit & Inter)
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textSlateDeep,
    letterSpacing: -0.5,
  );

  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textSlateDeep,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSlateDeep,
    height: 1.5,
  );

  static TextStyle labelBold = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: vibeRed,
  );

  static TextStyle labelMuted = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSlateMuted,
  );

  // 6. Common Shadows (Subtle & Open)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 40,
      offset: Offset(0, 10),
    ),
  ];
}
