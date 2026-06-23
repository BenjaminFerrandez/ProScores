import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const dark = Color(0xFF202322);
  static const light = Color(0xFFF3F9F8);
  static const teal = Color(0xFF049F7C);
  static const card = Color(0xFF262B2A);
  static const muted = Color(0xFF9BB3AD);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
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
