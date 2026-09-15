import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// The expandable reason block that physically emerges from the SAME parent card.
/// Does not look like a separate rectangle inserted underneath; unfolds organically
/// with the card container.
class TrimExpandableReason extends StatelessWidget {
  final String reason;
  final bool isPass;
  final double progress; // 0.0 = collapsed, 1.0 = fully expanded
  final String? label;

  const TrimExpandableReason({
    super.key,
    required this.reason,
    required this.isPass,
    required this.progress,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0) {
      return const SizedBox.shrink();
    }

    // Delayed fade and upward vertical offset for natural emergence as the surface unfolds
    final textOpacity = ((progress - 0.20) / 0.80).clamp(0.0, 1.0);
    final textTranslateY = (1.0 - textOpacity) * 5.0;

    final accentColor = isPass
        ? AppColors.emerald
        : const Color(0xFFE06D7D); // restrained muted red/rose

    final sectionLabel = label ?? (isPass ? 'Why this survives' : 'Why this was cut');

    return ClipRect(
      child: Align(
        heightFactor: progress,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: textOpacity,
          child: Transform.translate(
            offset: Offset(0, textTranslateY),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10.0),

                // Hairline divider showing internal emergence within the optical surface
                Container(
                  height: 1.0,
                  width: double.infinity,
                  color: isPass
                      ? AppColors.emerald.withValues(alpha: 0.15)
                      : const Color(0xFF27272A).withValues(alpha: 0.6),
                ),

                const SizedBox(height: 9.0),

                // Section Label: "Why this survives" / "Why this was cut"
                Text(
                  sectionLabel,
                  style: AppTypography.monoLabel.copyWith(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: accentColor,
                  ),
                ),

                const SizedBox(height: 4.0),

                // Concise editorial explanation
                Text(
                  reason,
                  style: AppTypography.featureExplanation.copyWith(
                    fontSize: 13.0,
                    height: 1.45,
                    color: isPass
                        ? const Color(0xFFD4D4D8)
                        : const Color(0xFFA1A1AA),
                  ),
                ),

                const SizedBox(height: 2.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
