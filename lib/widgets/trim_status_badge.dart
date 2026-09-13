import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum TrimStatusType { pass, cut }

/// Minimalist, editorial status badge for PASS and CUT triage decisions.
class TrimStatusBadge extends StatelessWidget {
  final TrimStatusType status;
  final VoidCallback? onTap;

  const TrimStatusBadge({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPass = status == TrimStatusType.pass;
    final text = isPass ? 'PASS' : 'CUT';
    final textColor = isPass ? AppColors.emerald : const Color(0xFFA1A1AA);
    final bgColor = isPass
        ? AppColors.emerald.withValues(alpha: 0.12)
        : const Color(0xFF18181D);
    final borderColor = isPass
        ? AppColors.emerald.withValues(alpha: 0.32)
        : const Color(0xFF27272E);

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.monoChip.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.8,
        ),
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
