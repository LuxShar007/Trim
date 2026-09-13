import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';
import 'glass_card.dart';
import 'verdict_chip.dart';

enum FeatureCardType {
  mustHave,
  discardedBloat,
}

/// Feature card representing an extracted Core Feature or a Cut Bloat item.
class FeatureCard extends StatelessWidget {
  final String text;
  final FeatureCardType type;
  final int index;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.text,
    required this.type,
    this.index = 0,
    this.onTap,
  });

  bool get isMustHave => type == FeatureCardType.mustHave;

  @override
  Widget build(BuildContext context) {
    final borderColor = isMustHave
        ? AppColors.emeraldBorder
        : AppColors.border;

    final backgroundColor = isMustHave
        ? AppColors.emeraldSubtle.withValues(alpha: 0.55)
        : AppColors.surfaceSubtle.withValues(alpha: 0.60);

    final textColor = isMustHave
        ? AppColors.textPrimary
        : AppColors.mutedText;

    final decoration = isMustHave
        ? TextDecoration.none
        : TextDecoration.lineThrough;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
        borderColor: borderColor,
        backgroundColor: backgroundColor,
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon Indicator
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: isMustHave
                    ? AppColors.emerald.withValues(alpha: 0.15)
                    : AppColors.cutRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMustHave
                      ? AppColors.emerald.withValues(alpha: 0.6)
                      : AppColors.cutRed.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Icon(
                  isMustHave ? Icons.check_rounded : Icons.close_rounded,
                  size: 14.0,
                  color: isMustHave ? AppColors.emerald : AppColors.cutRed.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Feature Title
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isMustHave ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                  decoration: decoration,
                  decorationColor: AppColors.cutRed.withValues(alpha: 0.6),
                  decorationThickness: 1.8,
                ),
              ),
            ),

            const SizedBox(width: 8.0),

            // Verdict Chip
            VerdictChip(
              type: isMustHave ? VerdictType.pass : VerdictType.cut,
            ),
          ],
        ),
      ),
    );
  }
}
