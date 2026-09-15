import 'dart:ui';
import 'package:flutter/material.dart';

/// Preset intensity levels for TrimGlassSurface.
enum TrimGlassIntensity {
  low, // Collapsed cards / base controls: dark OLED surface, restrained blur, gentle depth
  medium, // Expanded cards / elevated surfaces: tactile depth, subtle edge highlight
  high, // Modal dialogs, sheets, popovers: deeper diffusion
}

/// Liquid Glass Surface:
/// A disciplined, reusable glass material system inspired by optical liquid glass
/// while strictly honoring TRIM's dark, minimalist OLED identity.
/// Avoids expensive blur passes or redundant saveLayers to guarantee 120/144Hz fluidity.
class TrimGlassSurface extends StatelessWidget {
  final Widget child;
  final TrimGlassIntensity intensity;
  final double? morphProgress; // 0.0 (low) -> 1.0 (medium) for continuous physical morphing
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;
  final Color? surfaceTint;
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
    this.surfaceTint,
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

    // Dynamic corner radius: 12px (collapsed) -> 16px (expanded) -> 20px (high)
    final double effectiveRadiusVal = t <= 1.0
        ? (12.0 + (t * 4.0))
        : (16.0 + ((t - 1.0) * 8.0));
    final effectiveRadius = borderRadius ?? BorderRadius.circular(effectiveRadiusVal);

    // Restrained blur sigma (optimized for 120Hz/144Hz high-refresh displays):
    // 4.0 (low) -> 7.5 (medium) -> 11.0 (high)
    final double blurSigma = t <= 1.0
        ? (4.0 + (t * 3.5))
        : (7.5 + ((t - 1.0) * 7.0));

    // Base OLED translucent surface color
    final Color baseBgColor;
    if (t <= 1.0) {
      baseBgColor = Color.lerp(
        const Color(0xFF09090D).withValues(alpha: 0.70),
        const Color(0xFF121217).withValues(alpha: 0.84),
        t,
      )!;
    } else {
      baseBgColor = Color.lerp(
        const Color(0xFF121217).withValues(alpha: 0.84),
        const Color(0xFF181820).withValues(alpha: 0.92),
        (t - 1.0).clamp(0.0, 1.0),
      )!;
    }

    // Subtle material tint influence (Core = emerald, Noise = muted red/gray)
    final Color effectiveBgColor;
    if (surfaceTint != null) {
      effectiveBgColor = Color.alphaBlend(surfaceTint!, baseBgColor);
    } else if (accentColor != null) {
      final tintAlpha = 0.03 + (0.04 * t.clamp(0.0, 1.0));
      final dynamicTint = accentColor!.withValues(alpha: tintAlpha);
      effectiveBgColor = Color.alphaBlend(dynamicTint, baseBgColor);
    } else {
      effectiveBgColor = baseBgColor;
    }

    // Dynamic border color
    final Color baseBorder;
    if (accentColor != null) {
      final borderAlpha = 0.14 + (t.clamp(0.0, 1.0) * 0.16);
      baseBorder = accentColor!.withValues(alpha: borderAlpha);
    } else {
      baseBorder = Color.lerp(
        const Color(0xFF1E1E24),
        const Color(0xFF2E2E36),
        t.clamp(0.0, 1.0),
      )!;
    }

    // Dynamic physical shadow
    final List<BoxShadow> shadows;
    if (accentColor != null && t > 0.05) {
      shadows = [
        BoxShadow(
          color: accentColor!.withValues(alpha: 0.06 * t.clamp(0.0, 1.0)),
          blurRadius: 10.0 * t.clamp(0.0, 1.0),
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25 + (0.15 * t.clamp(0.0, 1.0))),
          blurRadius: 6.0 + (6.0 * t.clamp(0.0, 1.0)),
          offset: Offset(0, 1.5 + (2.0 * t.clamp(0.0, 1.0))),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20 + (0.20 * t.clamp(0.0, 1.0))),
          blurRadius: 3.0 + (8.0 * t.clamp(0.0, 1.0)),
          offset: Offset(0, 1.0 + (2.0 * t.clamp(0.0, 1.0))),
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
              color: effectiveBgColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: baseBorder,
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Subtle top hairline highlight for optical liquid surface depth
                if (showTopHighlight)
                  Positioned(
                    top: 0,
                    left: 14,
                    right: 14,
                    height: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            (accentColor ?? Colors.white).withValues(
                              alpha: 0.08 + (0.08 * t.clamp(0.0, 1.0)),
                            ),
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
