import 'package:flutter/material.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Dynamic Scope Metric Component (Verdict UX Polish):
/// Dynamically calculates and displays:
///   TOTAL → SURVIVORS SURVIVE
///   X% SCOPE REMOVED
///
/// Principles:
/// - Strong whitespace
/// - No unnecessary containers
/// - JetBrains Mono for numbers and technical labels
/// - OLED black canvas
class TrimScopeMetric extends StatefulWidget {
  final int totalFeatures;
  final int survivorsCount;
  final bool animate;
  final bool showHeader;

  const TrimScopeMetric({
    super.key,
    required this.totalFeatures,
    required this.survivorsCount,
    this.animate = true,
    this.showHeader = true,
  });

  @override
  State<TrimScopeMetric> createState() => _TrimScopeMetricState();
}

class _TrimScopeMetricState extends State<TrimScopeMetric>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TrimScopeMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int discardedCount = (widget.totalFeatures - widget.survivorsCount).clamp(0, widget.totalFeatures);
    final bool hasNoise = discardedCount > 0;
    final int percentRemoved = widget.totalFeatures > 0
        ? ((discardedCount / widget.totalFeatures) * 100).round()
        : 0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final opacity = val.clamp(0.0, 1.0);

        if (!hasNoise) {
          // Zero noise: "{TOTAL} FEATURES · FULLY FOCUSED"
          return Opacity(
            opacity: opacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showHeader) ...[
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'SCOPE:',
                        style: AppTypography.monoHeader.copyWith(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: const Color(0xFFA1A1AA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.totalFeatures} FEATURES',
                      style: AppTypography.monoHeader.copyWith(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF4F4F5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '·',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.emerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FULLY FOCUSED',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  '0% SCOPE REMOVED',
                  style: AppTypography.monoLabel.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          );
        }

        // Has noise:
        // TOTAL → SURVIVORS SURVIVE
        // X% SCOPE REMOVED
        final totalOpacity = (val / 0.4).clamp(0.0, 1.0);
        final arrowT = ((val - 0.3) / 0.35).clamp(0.0, 1.0);
        final arrowScale = 0.85 + (0.15 * SpringPhysics.liquidCurve.transform(arrowT));

        final survT = ((val - 0.5) / 0.5).clamp(0.0, 1.0);
        final survSpring = Curves.easeOutBack.transform(survT);
        final survScale = 1.05 - (survSpring * 0.05);
        final survOpacity = survT.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showHeader) ...[
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'SCOPE:',
                      style: AppTypography.monoHeader.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],

              // Metric Line 1: TOTAL → SURVIVORS SURVIVE
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Total Features
                    Opacity(
                      opacity: totalOpacity,
                      child: Text(
                        '${widget.totalFeatures}',
                        style: AppTypography.monoHeader.copyWith(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4D4D8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Arrow
                    Transform.scale(
                      scale: arrowScale,
                      child: Opacity(
                        opacity: arrowT,
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Survivors
                    Transform.scale(
                      scale: survScale,
                      child: Opacity(
                        opacity: survOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.14 * survOpacity),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.survivorsCount}',
                                style: AppTypography.monoHeader.copyWith(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SURVIVE',
                              style: AppTypography.monoLabel.copyWith(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4.0),

              // Metric Line 2: X% SCOPE REMOVED
              Opacity(
                opacity: survOpacity,
                child: Text(
                  '$percentRemoved% SCOPE REMOVED',
                  style: AppTypography.monoLabel.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: const Color(0xFFA1A1AA),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
