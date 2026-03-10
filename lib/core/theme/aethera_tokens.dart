import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design token system for Aethera.
/// All colors, typography, spacing and glass styles defined here.
abstract class AetheraTokens {
  // ─── Backgrounds ────────────────────────────────────────────────
  static const Color deepSpace = Color(0xFF070B14);
  static const Color cosmicNight = Color(0xFF0D1B2A);
  static const Color voidBlue = Color(0xFF0A0F1E);

  // ─── Accent Colors ───────────────────────────────────────────────
  static const Color auroraTeal = Color(0xFF64FFDA);
  static const Color nebulaPurple = Color(0xFF9B72CF);
  static const Color goldenDawn = Color(0xFFFFD700);
  static const Color roseQuartz = Color(0xFFFF6B8A);
  static const Color starlightBlue = Color(0xFF4FC3F7);

  // ─── Text Colors ─────────────────────────────────────────────────
  static const Color starlight = Color(0xFFE8F4FD);
  static const Color moonGlow = Color(0xFF94A3B8);
  static const Color dusk = Color(0xFF64748B);

  // ─── Emotion Colors ───────────────────────────────────────────────
  static const Color emotionJoy = Color(0xFFFFD700);
  static const Color emotionLove = Color(0xFFFF6B8A);
  static const Color emotionPeace = Color(0xFF64FFDA);
  static const Color emotionLonging = Color(0xFF9B72CF);
  static const Color emotionMelancholy = Color(0xFF4A5568);
  static const Color emotionAnxious = Color(0xFFFF8C42);

  // ─── Sky Gradients per emotion ────────────────────────────────────
  static const Map<String, List<Color>> emotionSkyGradients = {
    'joy': [Color(0xFF1A1200), Color(0xFF3D2B00), Color(0xFF7B5800)],
    'love': [Color(0xFF1A0010), Color(0xFF3D0025), Color(0xFF7B0048)],
    'peace': [Color(0xFF001A14), Color(0xFF003D2E), Color(0xFF006B52)],
    'longing': [Color(0xFF0E0018), Color(0xFF220040), Color(0xFF4A0080)],
    'melancholy': [Color(0xFF0A0E1A), Color(0xFF0D1B2A), Color(0xFF1A2A3A)],
    'anxious': [Color(0xFF1A0800), Color(0xFF3D1A00), Color(0xFF6B3000)],
    'neutral': [Color(0xFF070B14), Color(0xFF0D1B2A), Color(0xFF0A0F1E)],
  };

  // ─── Glassmorphism ────────────────────────────────────────────────
  static Color glassBackground = Colors.white.withValues(alpha: 0.08);
  static Color glassBorder = Colors.white.withValues(alpha: 0.15);
  static Color glassBackgroundStrong = Colors.white.withValues(alpha: 0.12);
  static const double glassBlur = 20.0;
  static const double glassBorderWidth = 1.0;

  // ─── Border Radii ─────────────────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusFull = 999.0;

  // ─── Spacing ─────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Typography ───────────────────────────────────────────────────
  static TextStyle displayLarge({Color? color}) => GoogleFonts.cormorantGaramond(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 8.0,
        color: color ?? starlight,
        height: 1.1,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 4.0,
        color: color ?? starlight,
        height: 1.2,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
        color: color ?? starlight,
        height: 1.3,
      );

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? starlight,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? moonGlow,
        height: 1.5,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? dusk,
        height: 1.4,
      );

  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: color ?? starlight,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color ?? moonGlow,
      );

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [auroraTeal, nebulaPurple, roseQuartz],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient deepSpaceGradient = LinearGradient(
    colors: [deepSpace, cosmicNight, voidBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Shadows / Glow ───────────────────────────────────────────────
  static List<BoxShadow> auroraGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: auroraTeal.withValues(alpha: 0.3 * intensity),
          blurRadius: 20 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> roseGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: roseQuartz.withValues(alpha: 0.3 * intensity),
          blurRadius: 20 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> nebulaPurpleGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: nebulaPurple.withValues(alpha: 0.3 * intensity),
          blurRadius: 20 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> goldenGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: goldenDawn.withValues(alpha: 0.35 * intensity),
          blurRadius: 20 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  // ─── Helper: color por emoción ────────────────────────────────────
  static Color colorForEmotion(String mood) {
    switch (mood) {
      case 'joy':
        return emotionJoy;
      case 'love':
        return emotionLove;
      case 'peace':
        return emotionPeace;
      case 'longing':
        return emotionLonging;
      case 'melancholy':
        return emotionMelancholy;
      case 'anxious':
        return emotionAnxious;
      default:
        return moonGlow;
    }
  }

  // ─── Material Theme ───────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: deepSpace,
        colorScheme: const ColorScheme.dark(
          surface: cosmicNight,
          primary: auroraTeal,
          secondary: nebulaPurple,
          tertiary: roseQuartz,
          onSurface: starlight,
          onPrimary: deepSpace,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
}
