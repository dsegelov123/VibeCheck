import 'package:flutter/material.dart';
import 'design_system.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignSystem.accent,
        brightness: Brightness.light,
        surface: DesignSystem.surface,
        onSurface: DesignSystem.textDeep,
      ),
      scaffoldBackgroundColor: DesignSystem.background,
      textTheme: TextTheme(
        displayLarge: DesignSystem.h1,
        displayMedium: DesignSystem.h2,
        titleMedium: DesignSystem.h2,
        bodyLarge: DesignSystem.body,
        bodyMedium: DesignSystem.body,
        labelSmall: DesignSystem.label,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DesignSystem.background.withValues(alpha: 0.0),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: DesignSystem.h2,
        iconTheme: const IconThemeData(color: DesignSystem.textDeep),
      ),
      dividerTheme: const DividerThemeData(
        color: DesignSystem.borderColor,
        thickness: DesignSystem.borderWidth,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.textDeep,
          foregroundColor: DesignSystem.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.buttonRadius),
          ),
          textStyle: DesignSystem.label.copyWith(color: DesignSystem.surface),
        ),
      ),
    );
  }

  // Unified Decoration Utility
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    BoxShape shape = BoxShape.rectangle,
    bool showBorder = true,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color ?? (gradient == null ? DesignSystem.surface : null),
      gradient: gradient,
      borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(DesignSystem.radius)),
      shape: shape,
      border: showBorder ? Border.all(color: DesignSystem.borderColor, width: DesignSystem.borderWidth) : null,
      boxShadow: boxShadow ?? DesignSystem.softShadow,
    );
  }

  // Mood-based Color Mapping (Strictly pass-through to DesignSystem)
  static Color getMoodColor(String? mood) {
    return DesignSystem.getMoodColor(mood);
  }
}
