import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // 1. Core Colors (Collaborative Palette)
  static const Color background = Color(0xFFFCFCFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFFF686B);
  static const Color textDeep = Color(0xFF242423);
  static Color textMuted = const Color(0xFF242423).withValues(alpha: 0.6);

  // 2. Semantic Palette (Hard Rule)
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color premium = Color(0xFFD97706);
  static const Color premiumSurface = Color(0xFFFEF3C7);
  static const Color premiumAccent = Color(0xFF92400E);
  static const Color premiumGold = Color(0xFFFBBF24);
  static const Color onAccent = Colors.white;
  static const Color brandIndigo = Color(0xFF6366F1);

  // 3. Borders & Spacing
  static const double grid = 8.0;
  static const double padding = 16.0;
  static const double radius = 14.0;
  static const double buttonRadius = 28.0;
  static const Color borderColor = Color(0xFFDEE2E6);
  static const double borderWidth = 1.0;

  // 4. Gradients (Centralized Policy)
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEF2FF),
      Color(0xFFF5F3FF),
      Color(0xFFFDF2F8),
    ],
  );

  static const RadialGradient orbitBackground = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      Color(0xFFF8FAFC),
      Colors.white,
    ],
  );

  static const RadialGradient premiumBackground = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.5,
    colors: [
      Color(0xFFFFFBEB),
      Colors.white,
    ],
  );

  // 3. Mood Color System (Desaturated Pastels)
  static const Map<String, Color> moodColors = {
    'joy': Color(0xFFFDFFB6),
    'excitement': Color(0xFFFFD6A5),
    'excited': Color(0xFFFFD6A5),
    'pride': Color(0xFFFFC6FF),
    'proud': Color(0xFFFFC6FF),
    'calmness': Color(0xFFCAFFBF),
    'calm': Color(0xFFCAFFBF),
    'reflection': Color(0xFF9BF6FF),
    'reflective': Color(0xFF9BF6FF),
    'sadness': Color(0xFFA0C4FF),
    'sad': Color(0xFFA0C4FF),
    'grief': Color(0xFF8EB7E6),
    'grieving': Color(0xFF8EB7E6),
    'loneliness': Color(0xFFB8BACF),
    'lonely': Color(0xFFB8BACF),
    'anxiety': Color(0xFFBDB2FF),
    'anxious': Color(0xFFBDB2FF),
    'stress': Color(0xFFFFADAD),
    'stressed': Color(0xFFFFADAD),
    'fear': Color(0xFFD0B8F0),
    'fearful': Color(0xFFD0B8F0),
    'tiredness': Color(0xFFE2D1F9),
    'tired': Color(0xFFE2D1F9),
    'boredom': Color(0xFFE5E9BC),
    'bored': Color(0xFFE5E9BC),
    'anger': Color(0xFFFF8B8B),
    'angry': Color(0xFFFF8B8B),
    'frustration': Color(0xFFFF9B71),
    'frustrated': Color(0xFFFF9B71),
    'annoyance': Color(0xFFFFB4A2),
    'annoyed': Color(0xFFFFB4A2),
  };

  // 4. Weather State System (Centralized)
  static final Map<String, ({Color color, IconData icon})> weatherStyles = {
    'sunny': (color: moodColors['excitement']!, icon: Icons.wb_sunny_rounded),
    'rainy': (color: moodColors['sadness']!, icon: Icons.umbrella_rounded),
    'foggy': (color: moodColors['tiredness']!, icon: Icons.cloud_rounded),
    'stormy': (color: moodColors['anger']!, icon: Icons.thunderstorm_rounded),
    'clear skies': (color: moodColors['reflection']!, icon: Icons.nightlight_round),
    'partly cloudy': (color: moodColors['boredom']!, icon: Icons.wb_cloudy_rounded),
    // Micro-Climates (Mixed States)
    'unsettled': (color: Color(0xFFD1B2FF), icon: Icons.cloud_sync_rounded), // Blend of Sunny/Rainy
    'misty': (color: Color(0xFFB5EAD7), icon: Icons.filter_drama_rounded),    // Blend of Foggy/Clear
    'heavy': (color: Color(0xFF94A3B8), icon: Icons.water_drop_rounded),      // Blend of Stormy/Rainy
  };

  /// Returns the color for a specific mood, or a brand fallback if not found.
  static Color getMoodColor(String? mood) {
    if (mood == null) return borderColor.withValues(alpha: 0.1);
    final m = mood.toLowerCase().trim();
    return moodColors[m] ?? accent; // Brand fallback instead of grey
  }

  /// Returns the style (color + icon) for a weather state.
  static ({Color color, IconData icon}) getWeatherStyle(String name) {
    final n = name.toLowerCase().trim();
    return weatherStyles[n] ?? (color: moodColors['boredom']!, icon: Icons.wb_cloudy_rounded);
  }

  // 5. Typography (Strict Weights - No Bold)
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: textDeep,
    letterSpacing: -1.0,
  );

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: textDeep,
    letterSpacing: -0.5,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textDeep,
    height: 1.5,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    letterSpacing: 0.5,
  );

  // 6. Common Effects
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 30,
      spreadRadius: 5,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      spreadRadius: 5,
    ),
  ];

  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor, width: borderWidth),
    boxShadow: softShadow,
  );
}
