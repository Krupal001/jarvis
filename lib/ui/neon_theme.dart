import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised neon colour palette, gradients, glow helpers and text styles.
/// Used across the bootstrap screen and chat screen for a consistent
/// cyberpunk / neon aesthetic.

class NeonColors {
  NeonColors._();

  // Muted accent colours (toned down from pure neon)
  static const cyan = Color(0xFF5ADAEF);
  static const purple = Color(0xFF9C6ADE);
  static const pink = Color(0xFFD670C8);
  static const blue = Color(0xFF5A9BEF);
  static const green = Color(0xFF5ADBA0);
  static const orange = Color(0xFFE89B5A);

  // Backgrounds (slightly lighter for less harsh contrast)
  static const bgDark = Color(0xFF0A0B10);
  static const bgCard = Color(0xFF121319);
  static const bgCardLight = Color(0xFF1A1B24);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, purple, pink],
  );

  static const cyanPurpleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, purple],
  );

  static const pinkPurpleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pink, purple],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14141F), Color(0xFF0A0A12)],
  );
}

/// Extension helpers for neon glow [BoxShadow] lists.
class NeonGlow {
  NeonGlow._();

  static List<BoxShadow> cyan({double blur = 12, double spread = 0}) => [
        BoxShadow(
          color: NeonColors.cyan.withValues(alpha: 0.2),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> purple({double blur = 12, double spread = 0}) => [
        BoxShadow(
          color: NeonColors.purple.withValues(alpha: 0.2),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> pink({double blur = 12, double spread = 0}) => [
        BoxShadow(
          color: NeonColors.pink.withValues(alpha: 0.2),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> multi({double blur = 16, double spread = 0}) => [
        BoxShadow(
          color: NeonColors.cyan.withValues(alpha: 0.12),
          blurRadius: blur,
          spreadRadius: spread,
        ),
        BoxShadow(
          color: NeonColors.purple.withValues(alpha: 0.12),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> soft(Color color, {double blur = 8, double opacity = 0.15}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
        ),
      ];
}

/// Neon-flavoured [TextTheme] built on top of Google Fonts (Orbitron for
/// headings, Rajdhani for body).
class NeonText {
  NeonText._();

  static TextStyle get heading => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get headingBold => GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodySemiBold => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyBold => GoogleFonts.inter(
        fontWeight: FontWeight.w700,
      );

  static TextStyle get mono => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );
}

/// Builds the app-level [ThemeData] with neon dark theme.
ThemeData neonTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeonColors.bgDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NeonColors.purple,
      brightness: Brightness.dark,
      primary: NeonColors.cyan,
      secondary: NeonColors.pink,
      surface: NeonColors.bgCard,
    ),
    textTheme: TextTheme(
      displayLarge: NeonText.headingBold.copyWith(fontSize: 32, color: Colors.white),
      displayMedium: NeonText.headingBold.copyWith(fontSize: 26, color: Colors.white),
      headlineMedium: NeonText.heading.copyWith(fontSize: 22, color: Colors.white),
      titleLarge: NeonText.heading.copyWith(fontSize: 18, color: Colors.white),
      titleMedium: NeonText.bodySemiBold.copyWith(fontSize: 16, color: Colors.white),
      bodyLarge: NeonText.body.copyWith(fontSize: 16, color: Colors.white70),
      bodyMedium: NeonText.bodyMedium.copyWith(fontSize: 14, color: Colors.white70),
      bodySmall: NeonText.body.copyWith(fontSize: 12, color: Colors.white54),
      labelSmall: NeonText.mono.copyWith(fontSize: 11, color: Colors.white54),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: NeonText.heading.copyWith(
        fontSize: 20,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: NeonColors.cyan),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: NeonColors.cyan.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NeonColors.cyan, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: NeonColors.purple.withValues(alpha: 0.25)),
      ),
      hintStyle: NeonText.body.copyWith(color: Colors.white30),
    ),
  );
}
