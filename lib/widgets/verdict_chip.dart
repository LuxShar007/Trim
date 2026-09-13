import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';

enum VerdictType {
  pass,
  cut,
  bloat,
}

/// Minimalist verdict chip badge using technical monospace typography.
class VerdictChip extends StatelessWidget {
  final VerdictType type;
  final String? customLabel;

  const VerdictChip({
    super.key,
    required this.type,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color textColor;
    final Color bgColor;
    final Color borderColor;

    switch (type) {
      case VerdictType.pass:
        label = customLabel ?? 'PASS';
        textColor = AppColors.emerald;
        bgColor = AppColors.emerald.withValues(alpha: 0.12);
        borderColor = AppColors.emerald.withValues(alpha: 0.4);
        break;
      case VerdictType.cut:
        label = customLabel ?? 'CUT';
        textColor = AppColors.mutedText;
        bgColor = AppColors.surfaceElevated;
        borderColor = AppColors.border;
        break;
      case VerdictType.bloat:
        label = customLabel ?? 'BLOAT';
        textColor = AppColors.cutRed;
        bgColor = AppColors.cutRed.withValues(alpha: 0.12);
        borderColor = AppColors.cutRed.withValues(alpha: 0.35);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.sm,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: AppTypography.monoChip.copyWith(color: textColor),
      ),
    );
  }
}
