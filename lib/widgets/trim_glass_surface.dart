import 'dart:ui';
import 'package:flutter/material.dart';

/// Preset intensity levels for TrimGlassSurface.
enum TrimGlassIntensity {
  low, // Collapsed cards / controls: dark OLED surface, very low blur, low shadow
  medium, // Expanded cards: slightly brighter, stronger depth, subtle edge highlight
  high, // Temporary overlays, sheets, and popovers
}

/// Liquid Glass Surface:
/// Reusable glass material system with continuous morphing capabilities.
/// Preserves OLED black as the dominant canvas.
class TrimGlassSurface extends StatelessWidget {
  final Widget child;
  final TrimGlassIntensity intensity;
  final double? morphProgress; // 0.0 (low) -> 1.0 (medium) for continuous morphing
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;
  final bool showTopHighlight;
  final VoidCallback? onTap;

  const TrimGlassSurface({
    super.key,
    required this.child,
    this.intensity = TrimGlassIntensity.low,
    this.morphProgress,
    this.borderRadius,
    this.padding,
    this.margin,
    this.accentColor,
    this.showTopHighlight = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine interpolation progress t (0.0 = low, 1.0 = medium, >1.0 = high)
    final double t;
    if (morphProgress != null) {
      t = morphProgress!.clamp(0.0, 1.0);
    } else {
      switch (intensity) {
        case TrimGlassIntensity.low:
          t = 0.0;
          break;
        case TrimGlassIntensity.medium:
          t = 1.0;
          break;
        case TrimGlassIntensity.high:
          t = 1.5;
          break;
      }
    }

    final double effectiveRadiusVal = 13.0 + (t.clamp(0.0, 1.0) * 3.0);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(effectiveRadiusVal);

    // Continuous blur sigma: 6.0 (low) -> 12.0 (medium) -> 16.0 (high)
    final double blurSigma = t <= 1.0
        ? (6.0 + (t * 6.0))
        : (12.0 + ((t - 1.0) * 8.0));

    // Continuous surface color: subtle dark translucent OLED surface
    final Color bgColor;
    if (t <= 1.0) {
      bgColor = Color.lerp(
        const Color(0xFF09090C).withValues(alpha: 0.68),
        const Color(0xFF131318).withValues(alpha: 0.82),
        t,
      )!;
    } else {
      bgColor = Color.lerp(
        const Color(0xFF131318).withValues(alpha: 0.82),
        const Color(0xFF181820).withValues(alpha: 0.90),
        (t - 1.0).clamp(0.0, 1.0),
      )!;
    }

    // Border color and highlight
    final Color baseBorder;
    if (accentColor != null) {
      final baseAlpha = 0.18 + (t.clamp(0.0, 1.0) * 0.22);
      baseBorder = accentColor!.withValues(alpha: baseAlpha);
    } else {
      baseBorder = Color.lerp(
        const Color(0xFF1F1F24),
        const Color(0xFF2E2E36),
        t.clamp(0.0, 1.0),
      )!;
    }

    // Shadow calculation
    final List<BoxShadow> shadows;
    if (accentColor != null && t > 0.05) {
      shadows = [
        BoxShadow(
          color: accentColor!.withValues(alpha: 0.08 * t.clamp(0.0, 1.0)),
          blurRadius: 12.0 * t.clamp(0.0, 1.0),
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3 + (0.2 * t.clamp(0.0, 1.0))),
          blurRadius: 8.0 + (8.0 * t.clamp(0.0, 1.0)),
          offset: Offset(0, 2.0 + (2.0 * t.clamp(0.0, 1.0))),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25 + (0.25 * t.clamp(0.0, 1.0))),
          blurRadius: 4.0 + (10.0 * t.clamp(0.0, 1.0)),
          offset: Offset(0, 1.5 + (2.5 * t.clamp(0.0, 1.0))),
        ),
      ];
    }

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: baseBorder,
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Subtle top hairline highlight for physical material depth
                if (showTopHighlight)
                  Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    height: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.12 + (0.10 * t.clamp(0.0, 1.0))),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
