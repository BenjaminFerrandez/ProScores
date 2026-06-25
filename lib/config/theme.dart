import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _Palette {
  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  const _Palette(
      {required this.bg,
      required this.card,
      required this.text,
      required this.muted});
}

const _darkPalette = _Palette(
  bg: Color(0xFF202322),
  card: Color(0xFF262B2A),
  text: Color(0xFFF3F9F8),
  muted: Color(0xFF9BB3AD),
);

const _lightPalette = _Palette(
  bg: Color(0xFFF3F9F8),
  card: Color(0xFFFFFFFF),
  text: Color(0xFF202322),
  muted: Color(0xFF5A6B66),
);

/// App colors. The accent (teal) is constant; the rest follow the current
/// theme (dark/light) — they are getters, so they are no longer `const`.
class AppColors {
  static _Palette _p = _darkPalette;

  /// Switches the palette. Called by [buildAppTheme] for the active mode.
  static void apply(Brightness brightness) =>
      _p = brightness == Brightness.dark ? _darkPalette : _lightPalette;

  static const teal = Color(0xFF049F7C);

  // Names kept for backwards compatibility: `dark` = background, `light` = text.
  static Color get dark => _p.bg;
  static Color get card => _p.card;
  static Color get light => _p.text;
  static Color get muted => _p.muted;
}

ThemeData buildAppTheme(Brightness brightness) {
  AppColors.apply(brightness);
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final bodyFont = GoogleFonts.dmSansTextTheme(base.textTheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.dark,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.teal,
      surface: AppColors.card,
    ),
    textTheme: bodyFont.copyWith(
      headlineSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w800, color: AppColors.light),
      titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: AppColors.light),
      titleSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: AppColors.light),
    ),
  );
}

/// Text style for numbers (odds, percentages) with aligned figures.
TextStyle tabularNumberStyle(TextStyle base) =>
    base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
