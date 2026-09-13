import 'package:flutter/material.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'trim_glass_surface.dart';

/// Clean scope reduction telemetry component:
/// Dynamically formats:
/// When there is noise:
///   "{TOTAL} → {SURVIVORS} SURVIVE" (e.g. "9 → 2 SURVIVE")
/// When there is no noise:
///   "{TOTAL} FEATURES · FULLY FOCUSED"
class TrimScopeMetric extends StatefulWidget {
  final int totalFeatures;
  final int survivorsCount;
  final bool animate;

  const TrimScopeMetric({
    super.key,
    required this.totalFeatures,
    required this.survivorsCount,
    this.animate = true,
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
      duration: const Duration(milliseconds: 500),
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
    final bool hasNoise = widget.totalFeatures > widget.survivorsCount;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;

        if (!hasNoise) {
          // Zero noise: "{TOTAL} FEATURES · FULLY FOCUSED"
          final opacity = val.clamp(0.0, 1.0);
          return TrimGlassSurface(
            intensity: TrimGlassIntensity.low,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Opacity(
                opacity: opacity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.totalFeatures} FEATURES',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        letterSpacing: 0.8,
                        color: const Color(0xFFF1F5F9),
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
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Has noise: "{TOTAL} → {SURVIVORS} SURVIVE"
        final totalOpacity = (val / 0.4).clamp(0.0, 1.0);
        final arrowT = ((val - 0.35) / 0.35).clamp(0.0, 1.0);
        final arrowScale = 0.85 + (0.15 * SpringPhysics.liquidCurve.transform(arrowT));

        final survT = ((val - 0.55) / 0.45).clamp(0.0, 1.0);
        final survSpring = Curves.easeOutBack.transform(survT);
        final survScale = 1.10 - (survSpring * 0.10);
        final survOpacity = survT.clamp(0.0, 1.0);

        return TrimGlassSurface(
          intensity: TrimGlassIntensity.low,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Total Features
                Opacity(
                  opacity: totalOpacity,
                  child: Text(
                    '${widget.totalFeatures}',
                    style: AppTypography.monoHeader.copyWith(
                      fontSize: 13.0,
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
                      size: 13,
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
                          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.14 * survOpacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${widget.survivorsCount}',
                            style: AppTypography.monoHeader.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'SURVIVE',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Percentage removed metric
                Opacity(
                  opacity: survOpacity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '·',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Color(0xFF52525B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${((widget.totalFeatures - widget.survivorsCount) / widget.totalFeatures * 100).round()}% SCOPE REMOVED',
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: const Color(0xFFA1A1AA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
