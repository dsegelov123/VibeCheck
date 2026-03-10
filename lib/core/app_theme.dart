import 'package:flutter/material.dart';
import 'design_system.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignSystem.vibeRed,
        brightness: Brightness.light,
        surface: DesignSystem.background,
      ),
      scaffoldBackgroundColor: DesignSystem.background,
      textTheme: TextTheme(
        displayLarge: DesignSystem.displayLarge,
        displayMedium: DesignSystem.titleLarge,
        titleMedium: DesignSystem.titleLarge.copyWith(fontSize: 18),
        bodyLarge: DesignSystem.bodyMedium,
        bodyMedium: DesignSystem.bodyMedium.copyWith(fontSize: 14),
        labelSmall: DesignSystem.labelBold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // Unified Decoration Utility
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return BoxDecoration(
      color: color ?? DesignSystem.surface,
      borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(24)),
      shape: shape,
      boxShadow: DesignSystem.softShadow,
    );
  }

  // Mood-based Tokens (Centralized)
  static Color getMoodColor(String mood) {
    switch (mood) {
      case 'joy': return DesignSystem.safeMint;
      case 'calm': return DesignSystem.safeMint;
      case 'anxious': return DesignSystem.vibeRedLight;
      case 'open': return DesignSystem.openLavender;
      default: return DesignSystem.surface;
    }
  }
}
