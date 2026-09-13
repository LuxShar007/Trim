import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';

enum SpringButtonVariant {
  primary,
  secondary,
  ghost,
}

/// A tactile button that behaves like a physical switch or stamped control.
/// Compresses to 0.95 on tap down and releases with a genuine [SpringSimulation].
/// Uses Inter (humanist sans-serif) typography and participates in the energy handoff transition.
class SpringButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;
  final IconData? icon;
  final SpringButtonVariant variant;
  final double height;
  final double? width;
  final bool enableLiquidTransition;

  const SpringButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
    this.variant = SpringButtonVariant.primary,
    this.height = 56.0,
    this.width,
    this.enableLiquidTransition = false,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton> with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _liquidController;
  bool _isLiquidTransitioning = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.5,
    );

    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _liquidController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.isLoading || widget.onTap == null || _isLiquidTransitioning) return;
    HapticsUtil.lightClick();
    _pressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOutQuad,
    );
  }

  Future<void> _onTapUp(TapUpDetails details) async {
    if (!widget.isEnabled || widget.isLoading || widget.onTap == null || _isLiquidTransitioning) return;

    if (widget.enableLiquidTransition) {
      _isLiquidTransitioning = true;
      HapticsUtil.mediumImpact();
      // Liquid energy handoff
      await _liquidController.forward(from: 0.0);
      widget.onTap?.call();
      if (mounted) {
        _liquidController.reset();
        _releaseSpring();
        setState(() => _isLiquidTransitioning = false);
      }
    } else {
      _releaseSpring();
      HapticsUtil.mediumImpact();
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    if (_isLiquidTransitioning) return;
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
    final isInteractive = widget.isEnabled && !widget.isLoading && widget.onTap != null;

    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final List<BoxShadow> shadows;

    switch (widget.variant) {
      case SpringButtonVariant.primary:
        if (isInteractive) {
          bgColor = AppColors.orange;
          textColor = Colors.white;
          borderColor = const Color(0xFFFF7A29);
          shadows = AppShadows.primaryButton;
        } else {
          bgColor = const Color(0xFF1E1714);
          textColor = AppColors.textDisabled;
          borderColor = const Color(0xFF2E221C);
          shadows = [];
        }
        break;
      case SpringButtonVariant.secondary:
        bgColor = isInteractive ? AppColors.surfaceElevated : AppColors.surfaceSubtle;
        textColor = isInteractive ? AppColors.textPrimary : AppColors.textDisabled;
        borderColor = isInteractive ? AppColors.borderHighlight : AppColors.border;
        shadows = [];
        break;
      case SpringButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = isInteractive ? AppColors.textSecondary : AppColors.textDisabled;
        borderColor = Colors.transparent;
        shadows = [];
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _liquidController]),
        builder: (context, child) {
          // Compress 1.0 -> 0.95
          final tactileScale = 1.0 - (_pressController.value * 0.05);
          final lVal = _liquidController.value;

          final double scaleX;
          final double scaleY;
          final double borderRadiusVal;
          final double opacityVal;
          final List<BoxShadow> currentShadows;
          final Gradient? dynamicGradient;

          if (lVal > 0.0 && widget.variant == SpringButtonVariant.primary) {
            if (lVal <= 0.4) {
              final t = lVal / 0.4;
              final comp = Curves.easeOutQuad.transform(t);
              scaleX = tactileScale * (1.0 - (comp * 0.03));
              scaleY = tactileScale * (1.0 - (comp * 0.04));
              borderRadiusVal = 14.0 + (comp * 4.0);
              opacityVal = 1.0;
              currentShadows = shadows;
              dynamicGradient = null;
            } else {
              final t = (lVal - 0.4) / 0.6;
              final morph = Curves.easeOutCubic.transform(t);
              scaleX = tactileScale * (0.97 + (morph * 0.06));
              scaleY = tactileScale * (0.96 + (morph * 0.04));
              borderRadiusVal = 18.0 + (morph * 6.0);
              opacityVal = 1.0;
              currentShadows = [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.35 + (morph * 0.15)),
                  blurRadius: 18.0 + (morph * 12.0),
                  spreadRadius: morph * 1.5,
                  offset: const Offset(0, 3),
                ),
              ];
              dynamicGradient = LinearGradient(
                colors: const [
                  Color(0xFFFF5E00),
                  Color(0xFFFF7A29),
                  Color(0xFFFF5E00),
                ],
                stops: [0.0, 0.5 + (morph * 0.2), 1.0],
              );
            }
          } else {
            scaleX = tactileScale;
            scaleY = tactileScale;
            borderRadiusVal = 14.0;
            opacityVal = 1.0;
            currentShadows = shadows;
            dynamicGradient = null;
          }

          return Opacity(
            opacity: opacityVal.clamp(0.0, 1.0),
            child: Transform(
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
              alignment: Alignment.center,
              child: Container(
                width: widget.width ?? double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: dynamicGradient == null ? bgColor : null,
                  gradient: dynamicGradient,
                  borderRadius: BorderRadius.circular(borderRadiusVal),
                  border: Border.all(
                    color: borderColor,
                    width: 1.1,
                  ),
                  boxShadow: currentShadows,
                ),
                child: Stack(
                  children: [
                    // Subtle top highlight bevel for tactile weight
                    if (widget.variant == SpringButtonVariant.primary && isInteractive && dynamicGradient == null)
                      Positioned(
                        top: 0,
                        left: 14,
                        right: 14,
                        height: 1.2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),

                    Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              ),
                            )
                          : Row(
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
                                  widget.label.toUpperCase(),
                                  style: AppTypography.buttonLabel.copyWith(
                                    color: textColor,
                                    fontSize: 13.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
