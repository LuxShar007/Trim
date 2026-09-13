import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shadow and glow tokens for TRIM.
/// Restrained, purposeful illumination against OLED pitch black.
class AppShadows {
  AppShadows._();

  static final List<BoxShadow> primaryButton = [
    BoxShadow(
      color: AppColors.orange.withValues(alpha: 0.25),
      blurRadius: 20.0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.6),
      blurRadius: 10.0,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> emeraldPass = [
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.14),
      blurRadius: 16.0,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 12.0,
      offset: const Offset(0, 3),
    ),
  ];
}
