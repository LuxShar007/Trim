import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';

enum TrimButtonVariant {
  primary, // Monster Orange action surface
  glass, // Subtle dark glass surface (e.g. Export Spec)
  ghost, // Subtle text/icon button
}

enum TrimButtonMorphState {
  idle,
  loading,
  success,
}

/// Tactile glass button featuring physical spring compression (scale 1.0 -> 0.95),
/// subtle top edge highlight, and fluid state morphing (e.g., Export -> Exporting... -> Exported ✓).
class TrimGlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final TrimButtonVariant variant;
  final TrimButtonMorphState morphState;
  final String? loadingLabel;
  final String? successLabel;
  final bool isEnabled;
  final double height;
  final double? width;
  final bool enableHaptic;

  const TrimGlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = TrimButtonVariant.primary,
    this.morphState = TrimButtonMorphState.idle,
    this.loadingLabel,
    this.successLabel,
    this.isEnabled = true,
    this.height = 54.0,
    this.width,
    this.enableHaptic = true,
  });

  @override
  State<TrimGlassButton> createState() => _TrimGlassButtonState();
}

class _TrimGlassButtonState extends State<TrimGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.5,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.onTap == null || widget.morphState != TrimButtonMorphState.idle) return;
    if (widget.enableHaptic) {
      HapticsUtil.lightClick();
    }
    _pressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOutQuad,
    );
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isEnabled || widget.onTap == null || widget.morphState != TrimButtonMorphState.idle) return;
    _releaseSpring();
    if (widget.enableHaptic) {
      HapticsUtil.mediumImpact();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _releaseSpring();
  }

  void _releaseSpring() {
    final simulation = SpringSimulation(
      SpringPhysics.buttonPress,
      _pressController.value,
      0.0,
      _pressController.velocity,
    );
    _pressController.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.isEnabled && widget.onTap != null;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final List<BoxShadow> shadows;

    if (widget.morphState == TrimButtonMorphState.success) {
      bgColor = AppColors.emeraldSubtle;
      borderColor = AppColors.emerald.withValues(alpha: 0.6);
      textColor = AppColors.emerald;
      shadows = [
        BoxShadow(
          color: AppColors.emerald.withValues(alpha: 0.16),
          blurRadius: 16.0,
        ),
      ];
    } else if (widget.variant == TrimButtonVariant.primary) {
      if (isInteractive) {
        bgColor = AppColors.orange;
        borderColor = const Color(0xFFFF7A29);
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.28),
            blurRadius: 18.0,
            offset: const Offset(0, 3),
          ),
        ];
      } else {
        bgColor = const Color(0xFF1E1714);
        borderColor = const Color(0xFF2E221C);
        textColor = AppColors.textDisabled;
        shadows = [];
      }
    } else if (widget.variant == TrimButtonVariant.glass) {
      bgColor = isInteractive ? const Color(0xFF131318) : const Color(0xFF0D0D10);
      borderColor = isInteractive ? const Color(0xFF33333D) : const Color(0xFF222228);
      textColor = isInteractive ? const Color(0xFFF4F4F5) : AppColors.textDisabled;
      shadows = isInteractive
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10.0,
                offset: const Offset(0, 2),
              ),
            ]
          : [];
    } else {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = isInteractive ? AppColors.textSecondary : AppColors.textDisabled;
      shadows = [];
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          // Compress 1.0 -> 0.95
          final scale = 1.0 - (_pressController.value * 0.05);

          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: SpringPhysics.liquidCurve,
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(13.0),
                border: Border.all(
                  color: borderColor,
                  width: 1.1,
                ),
                boxShadow: shadows,
              ),
              child: Stack(
                children: [
                  // Subtle top highlight edge for physical material depth
                  if (widget.variant == TrimButtonVariant.primary && isInteractive)
                    Positioned(
                      top: 0,
                      left: 14,
                      right: 14,
                      height: 1.2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),

                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildButtonContent(textColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (widget.morphState == TrimButtonMorphState.loading) {
      return Row(
        key: const ValueKey('loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.loadingLabel ?? 'Exporting...',
            style: AppTypography.buttonLabel.copyWith(
              color: textColor,
              fontSize: 13.5,
            ),
          ),
        ],
      );
    }

    if (widget.morphState == TrimButtonMorphState.success) {
      return Row(
        key: const ValueKey('success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 17,
            color: AppColors.emerald,
          ),
          const SizedBox(width: 8),
          Text(
            widget.successLabel ?? 'Exported ✓',
            style: AppTypography.buttonLabel.copyWith(
              color: AppColors.emerald,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      );
    }

    return Row(
      key: const ValueKey('idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 9),
        ],
        Text(
          widget.label,
          style: AppTypography.buttonLabel.copyWith(
            color: textColor,
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }
}
