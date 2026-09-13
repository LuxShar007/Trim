import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography tokens for TRIM (Visual Design System V3).
/// PRIMARY FONT: Manrope (human, premium, editorial, modern)
/// SECONDARY FONT: JetBrains Mono (strictly for section labels, badges, counts, step numbers)
class AppTypography {
  AppTypography._();

  // --- Primary Font: Manrope ---

  // Project title / Dominant page titles (Weight: 600–700)
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 27.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle titleLarge = GoogleFonts.manrope(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Body & Core Value (Weight: 400–500)
  static TextStyle bodyLarge = GoogleFonts.manrope(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  // Interactive UI buttons (Weight: 500–600)
  static TextStyle buttonLabel = GoogleFonts.manrope(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  // Backwards compatibility alias for button typography
  static TextStyle monoButton = buttonLabel;

  // Feature name in cards (Weight: 500–600)
  static TextStyle featureTitle = GoogleFonts.manrope(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Explanation inside expanded card (Weight: 400–500)
  static TextStyle featureExplanation = GoogleFonts.manrope(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.45,
    color: const Color(0xFFD4D4D8),
  );

  // Product Truth statement in normal premium Manrope (Weight: 400–500)
  static TextStyle productTruth = GoogleFonts.manrope(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.1,
    color: const Color(0xFFF1F5F9),
  );

  // Backwards compatibility alias
  static TextStyle harshTruth = productTruth;

  // --- Monospace (JetBrains Mono) — Strictly for metadata, labels, and badges ---

  // Section labels: THE CORE, THE NOISE, BUILD FIRST, PRODUCT TRUTH
  static TextStyle monoHeader = GoogleFonts.jetBrainsMono(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  // Status badges: PASS, CUT, step numbers
  static TextStyle monoChip = GoogleFonts.jetBrainsMono(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  static TextStyle monoLabel = GoogleFonts.jetBrainsMono(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  static TextStyle monoCounter = GoogleFonts.jetBrainsMono(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textDisabled,
  );
}
