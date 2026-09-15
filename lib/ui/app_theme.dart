import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light glassmorphism colour palette with high-contrast accents.
class AppColors {
  AppColors._();

  // Primary accents (deep, high contrast on light)
  static const primary = Color(0xFF2563EB);   // deep blue
  static const secondary = Color(0xFF7C3AED); // deep purple
  static const accent = Color(0xFF0D9488);   // teal
  static const pink = Color(0xFFDB2777);     // rose
  static const orange = Color(0xFFEA580C);   // orange
  static const green = Color(0xFF16A34A);    // green
  static const red = Color(0xFFDC2626);      // red

  // Surface tones (light theme)
  static const bgBase = Color(0xFFF1F5F9);      // slate-100
  static const bgSoft = Color(0xFFE2E8F0);      // slate-200
  static const glass = Color(0xFFFFFFFF);       // pure white for glass
  static const glassAlt = Color(0xFFF8FAFC);    // near-white

  // Text
  static const textPrimary = Color(0xFF0F172A); // slate-900
  static const textSecondary = Color(0xFF475569); // slate-600
  static const textHint = Color(0xFF94A3B8);    // slate-400

  // Borders
  static const border = Color(0xFFCBD5E1);       // slate-300
  static const borderLight = Color(0xFFE2E8F0); // slate-200

  // Gradients (used sparingly)
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

/// Subtle shadow helpers — minimal, professional elevation.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft({Color color = AppColors.primary, double blur = 8, double opacity = 0.06}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> card({double blur = 8}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: blur,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> elevated({Color color = AppColors.primary, double blur = 12, double opacity = 0.08}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Text styles built on Google Fonts (Poppins for headings, Inter for body).
class AppText {
  AppText._();

  static TextStyle get heading => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  static TextStyle get headingBold => GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
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
        letterSpacing: 0.2,
      );
}

/// App-level [ThemeData] with light glassmorphism theme.
ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgBase,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.glass,
    ),
    textTheme: TextTheme(
      displayLarge: AppText.headingBold.copyWith(fontSize: 32, color: AppColors.textPrimary),
      displayMedium: AppText.headingBold.copyWith(fontSize: 26, color: AppColors.textPrimary),
      headlineMedium: AppText.heading.copyWith(fontSize: 22, color: AppColors.textPrimary),
      titleLarge: AppText.heading.copyWith(fontSize: 18, color: AppColors.textPrimary),
      titleMedium: AppText.bodySemiBold.copyWith(fontSize: 16, color: AppColors.textPrimary),
      bodyLarge: AppText.body.copyWith(fontSize: 16, color: AppColors.textSecondary),
      bodyMedium: AppText.bodyMedium.copyWith(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: AppText.body.copyWith(fontSize: 12, color: AppColors.textHint),
      labelSmall: AppText.mono.copyWith(fontSize: 11, color: AppColors.textHint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.heading.copyWith(
        fontSize: 20,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      hintStyle: AppText.body.copyWith(color: AppColors.textHint),
    ),
  );
}
