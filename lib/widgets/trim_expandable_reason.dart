import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// The "WHY CUT?" or "WHY KEEP?" reason block that emerges organically
/// from the SAME parent card rather than looking like a separate rectangle inserted underneath.
class TrimExpandableReason extends StatelessWidget {
  final String reason;
  final bool isPass;
  final double progress; // 0.0 = collapsed, 1.0 = fully expanded

  const TrimExpandableReason({
    super.key,
    required this.reason,
    required this.isPass,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0) {
      return const SizedBox.shrink();
    }

    // Delayed fade and slide for organic emergence
    final textOpacity = ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
    final textTranslateY = (1.0 - textOpacity) * 4.0;

    final accentColor = isPass ? AppColors.emerald : AppColors.mutedText;
    final sectionLabel = isPass ? 'WHY KEEP?' : 'WHY CUT?';

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
                const SizedBox(height: 9.0),

                // Hairline divider showing internal emergence
                Container(
                  height: 1.0,
                  width: double.infinity,
                  color: const Color(0xFF1E1E24),
                ),

                const SizedBox(height: 9.0),

                // Small technical label in JetBrains Mono
                Text(
                  sectionLabel,
                  style: AppTypography.monoLabel.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: accentColor,
                  ),
                ),

                const SizedBox(height: 4.0),

                // Editorial reason text in Manrope
                Text(
                  reason,
                  style: AppTypography.featureExplanation.copyWith(
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
