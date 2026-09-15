import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';
import 'trim_chevron.dart';
import 'trim_expandable_reason.dart';
import 'trim_glass_surface.dart';
import 'trim_status_badge.dart';

/// Explicit lifecycle states of the TrimMorphCard.
enum TrimCardState {
  collapsed,
  expanding,
  expanded,
  collapsing,
}

/// The TrimMorphCard:
/// A custom liquid morphing card where the SAME physical surface expands and collapses
/// in-place using spring physics.
/// Coordinates:
/// - card height
/// - corner radius
/// - surface opacity
/// - border
/// - subtle blur
/// - internal spacing
/// - chevron rotation
/// - reason text opacity
/// - reason text vertical offset
///
/// Ensures 120Hz/144Hz smoothness with internal RepaintBoundary and restrained blur.
class TrimMorphCard extends StatefulWidget {
  final String text;
  final String? reason;
  final bool isPass;
  final int index;
  final VoidCallback? onPurged;
  final bool initiallyExpanded;
  final String? reasonLabel;

  const TrimMorphCard({
    super.key,
    required this.text,
    this.reason,
    required this.isPass,
    this.index = 0,
    this.onPurged,
    this.initiallyExpanded = false,
    this.reasonLabel,
  });

  @override
  State<TrimMorphCard> createState() => _TrimMorphCardState();
}

class _TrimMorphCardState extends State<TrimMorphCard>
    with TickerProviderStateMixin {
  // Press response controller (scale 1.0 -> 0.98 -> 1.0 via spring)
  late final AnimationController _pressController;

  // Anchored expansion controller (0.0 = collapsed, 1.0 = expanded)
  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;

  // Noise squeeze/collapse controller (for purged bloat)
  late final AnimationController _purgeController;
  bool _isPurged = false;

  bool get hasReason => widget.reason != null && widget.reason!.trim().isNotEmpty;
  bool get isExpanded => _morphController.value > 0.5;

  TrimCardState get currentState {
    if (_morphController.isAnimating) {
      return _morphController.status == AnimationStatus.forward
          ? TrimCardState.expanding
          : TrimCardState.collapsing;
    }
    return isExpanded ? TrimCardState.expanded : TrimCardState.collapsed;
  }

  @override
  void initState() {
    super.initState();

    // 1. Press controller with spring
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.5,
    );

    // 2. Coordinated expansion animation with physical snap and soft settle
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: SpringPhysics.snapCurve, // slight overshoot followed by soft settle
      reverseCurve: Curves.easeInOutCubic,
    );

    // 3. Purge/squeeze collapse controller
    _purgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _morphController.dispose();
    _purgeController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!hasReason || _isPurged) return;
    HapticsUtil.lightClick();
    _pressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOutQuad,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _releasePressSpring();
    _toggleExpand();
  }

  void _onTapCancel() {
    _releasePressSpring();
  }

  void _releasePressSpring() {
    final simulation = SpringSimulation(
      SpringPhysics.cardPress,
      _pressController.value,
      0.0,
      _pressController.velocity,
    );
    _pressController.animateWith(simulation);
  }

  void _toggleExpand() {
    if (!hasReason || _isPurged) return;
    HapticsUtil.lightClick();

    if (_morphController.isCompleted || _morphController.value > 0.5) {
      _morphController.reverse();
    } else {
      _morphController.forward();
    }
  }

  Future<void> triggerPurge() async {
    if (_isPurged) return;
    HapticsUtil.mediumImpact();
    setState(() => _isPurged = true);
    await _purgeController.forward();
    widget.onPurged?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Material influence setup:
    // Core: subtle emerald material influence
    // Noise: subtle muted red/gray material influence
    final Color accentColor = widget.isPass
        ? AppColors.emerald
        : const Color(0xFF9E4B56);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _morphAnimation, _purgeController]),
        builder: (context, child) {
          final pVal = _pressController.value;
          final mVal = _morphAnimation.value;
          final purgeVal = _purgeController.value;

          // If purge is complete, remove from layout
          if (purgeVal >= 1.0) {
            return const SizedBox.shrink();
          }

          // Noise squeeze dynamics (if triggered)
          final double purgeScaleX;
          final double purgeScaleY;
          final double purgeTranslateX;
          final double purgeOpacity;
          final double purgeHeightFactor;

          if (purgeVal > 0.0) {
            final t = purgeVal;
            final squeeze = Curves.easeInCubic.transform(t);
            purgeScaleX = 1.0 - (squeeze * 0.25);
            purgeScaleY = 1.0 - (squeeze * 0.35);
            purgeTranslateX = squeeze * 28.0;
            purgeOpacity = (1.0 - (t * 1.3)).clamp(0.0, 1.0);
            purgeHeightFactor = (1.0 - (t * 0.8)).clamp(0.0, 1.0);
          } else {
            purgeScaleX = 1.0;
            purgeScaleY = 1.0;
            purgeTranslateX = 0.0;
            purgeOpacity = 1.0;
            purgeHeightFactor = 1.0;
          }

          // Press scale factor (1.0 -> 0.98)
          final pressScale = 1.0 - (pVal * 0.02);

          // Internal spacing animation:
          // Unfolds with subtle additional vertical padding as the card expands
          final currentPadding = EdgeInsets.lerp(
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.5),
            mVal.clamp(0.0, 1.0),
          )!;

          // Subtle material tint influence
          final surfaceTint = widget.isPass
              ? const Color(0xFF06281B).withValues(alpha: 0.16 + (0.10 * mVal.clamp(0.0, 1.0)))
              : const Color(0xFF221417).withValues(alpha: 0.14 + (0.08 * mVal.clamp(0.0, 1.0)));

          return SizeTransition(
            sizeFactor: AlwaysStoppedAnimation(purgeHeightFactor),
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(purgeTranslateX, 0),
              child: Transform.scale(
                scaleX: purgeScaleX * pressScale,
                scaleY: purgeScaleY * pressScale,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: purgeOpacity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    width: double.infinity,
                    child: TrimGlassSurface(
                      morphProgress: mVal,
                      accentColor: accentColor,
                      surfaceTint: surfaceTint,
                      padding: currentPadding,
                      child: GestureDetector(
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top header row: Icon + Feature Title + Badge + Chevron
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Feature Status Icon
                                _buildStatusIcon(),
                                const SizedBox(width: 10.0),

                                // Feature Title in Manrope (humanist sans-serif)
                                Expanded(
                                  child: Text(
                                    widget.text,
                                    style: AppTypography.featureTitle.copyWith(
                                      fontWeight: widget.isPass ? FontWeight.w600 : FontWeight.w400,
                                      color: widget.isPass
                                          ? const Color(0xFFF4F4F5)
                                          : const Color(0xFF8E8E93),
                                      decoration: widget.isPass
                                          ? TextDecoration.none
                                          : TextDecoration.lineThrough,
                                      decorationColor: AppColors.cutRed.withValues(alpha: 0.6),
                                      decorationThickness: 1.6,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8.0),

                                // CUT / PASS Badge
                                TrimStatusBadge(
                                  status: widget.isPass
                                      ? TrimStatusType.pass
                                      : TrimStatusType.cut,
                                  onTap: !widget.isPass ? triggerPurge : null,
                                ),

                                // Chevron arrow that rotates physically with spring motion
                                if (hasReason) ...[
                                  const SizedBox(width: 6.0),
                                  TrimChevron(
                                    progress: mVal,
                                    color: widget.isPass
                                        ? Color.lerp(
                                            const Color(0xFF71717A),
                                            AppColors.emerald,
                                            mVal.clamp(0.0, 1.0),
                                          )
                                        : Color.lerp(
                                            const Color(0xFF71717A),
                                            const Color(0xFFD48B95),
                                            mVal.clamp(0.0, 1.0),
                                          ),
                                  ),
                                ],
                              ],
                            ),

                            // Emergent Reason Drawer (unfolds naturally from the SAME card)
                            if (hasReason)
                              TrimExpandableReason(
                                reason: widget.reason!,
                                isPass: widget.isPass,
                                progress: mVal,
                                label: widget.reasonLabel,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (widget.isPass) {
      return Container(
        width: 22.0,
        height: 22.0,
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 13.0,
            color: AppColors.emerald,
          ),
        ),
      );
    } else {
      return Container(
        width: 22.0,
        height: 22.0,
        decoration: BoxDecoration(
          color: const Color(0xFF181212),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.cutRed.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.close_rounded,
            size: 12.0,
            color: AppColors.cutRed.withValues(alpha: 0.7),
          ),
        ),
      );
    }
  }
}
