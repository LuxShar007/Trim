import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';

/// Clean section header for TRIM triage sections ("THE CORE", "THE NOISE").
class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color accentColor;
  final String countLabel;

  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Status indicator pip
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.5),
                  blurRadius: 6.0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),

          // Section Title
          Text(
            title.toUpperCase(),
            style: AppTypography.monoHeader.copyWith(
              fontSize: 13.0,
              letterSpacing: 1.6,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 8.0),

          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.sm,
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Text(
              '$count $countLabel',
              style: AppTypography.monoCounter.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
