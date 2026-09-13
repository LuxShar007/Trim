import 'package:flutter/material.dart';

/// Design tokens for TRIM: OLED brutalism meets Watermelon UI / shadcn dark mode.
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color canvas = Color(0xFF000000); // Deep OLED Black
  static const Color surface = Color(0xFF070709); // Near-black surface
  static const Color surfaceSubtle = Color(0xFF0E0E12); // Card surface
  static const Color surfaceElevated = Color(0xFF14141A); // Modal / Popover

  // Core Must-Haves (Pass)
  static const Color emerald = Color(0xFF10B981); // Glowing Emerald Green
  static const Color emeraldSubtle = Color(0xFF062319);
  static const Color emeraldBorder = Color(0x7310B981); // ~45% alpha

  // Action Accents (Energy)
  static const Color orange = Color(0xFFFF5E00); // iQOO Monster Orange
  static const Color orangeSubtle = Color(0xFF261005);
  static const Color orangeGlow = Color(0x38FF5E00); // ~22% alpha

  // Bloat & Noise (Discarded)
  static const Color noiseGray = Color(0xFF333333); // Strict specification
  static const Color mutedText = Color(0xFF71717A);
  static const Color border = Color(0xFF1F1F24);
  static const Color borderHighlight = Color(0xFF2E2E36);

  // Failure & Warnings
  static const Color cutRed = Color(0xFFEF4444); // Bloat cut red
  static const Color cutRedSubtle = Color(0xFF260D0D);

  // Typography
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textDisabled = Color(0xFF3F3F46);
}
