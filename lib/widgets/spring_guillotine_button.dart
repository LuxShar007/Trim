import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A large, tactile guillotine-style button with physics spring simulation
/// and an animated sweep gradient border.
class SpringGuillotineButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;
  final double width;
  final double height;

  const SpringGuillotineButton({
    super.key,
    required this.onTap,
    this.label = 'Trim the Fat',
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 62.0,
  });

  @override
  State<SpringGuillotineButton> createState() => _SpringGuillotineButtonState();
}

class _SpringGuillotineButtonState extends State<SpringGuillotineButton>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _borderRotateController;

  // Spring physics description for tactile bounce
  final SpringDescription _springDesc = const SpringDescription(
    mass: 1.0,
    stiffness: 450.0,
    damping: 18.0,
  );

  @override
  void initState() {
    super.initState();
    // 0.0 = unpressed (scale 1.0), 1.0 = pressed (scale 0.92)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.5,
    );

    // Continuous smooth rotation for the sweep gradient border
    _borderRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _borderRotateController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isLoading || widget.onTap == null) return;
    HapticFeedback.selectionClick();
    _scaleController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOutQuad,
    );
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isLoading || widget.onTap == null) return;
    _releaseSpring();
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.isLoading) return;
    _releaseSpring();
  }

  void _releaseSpring() {
    final simulation = SpringSimulation(
      _springDesc,
      _scaleController.value,
      0.0, // target is rest (0.0)
      _scaleController.velocity,
    );
    _scaleController.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _borderRotateController]),
        builder: (context, child) {
          // Map controller value 0.0 -> 1.0 to scale 1.0 -> 0.92
          final double scale = 1.0 - (_scaleController.value * 0.08);

          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                    blurRadius: 24.0,
                    spreadRadius: -2.0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 36.0,
                    spreadRadius: -4.0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _SweepGradientBorderPainter(
                  rotationAngle: _borderRotateController.value * 2 * math.pi,
                  borderRadius: 16.0,
                  borderWidth: 2.2,
                ),
                child: Container(
                  margin: const EdgeInsets.all(2.2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D11),
                    borderRadius: BorderRadius.circular(14.0),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF17171F),
                        Color(0xFF09090D),
                      ],
                    ),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF5E00),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Sharpening Guillotine...',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE2E8F0),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.content_cut_rounded,
                                color: Color(0xFFFF5E00),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.label.toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFFF5E00)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
}

/// Custom painter for sweep gradient border with high-frequency color rotation
class _SweepGradientBorderPainter extends CustomPainter {
  final double rotationAngle;
  final double borderRadius;
  final double borderWidth;

  _SweepGradientBorderPainter({
    required this.rotationAngle,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(rotationAngle),
      colors: const [
        Color(0xFFFF5E00), // iQOO Monster Orange
        Color(0xFF10B981), // Glowing Emerald Green
        Color(0x33FF5E00), // Low-alpha transition
        Color(0xFF09090D), // Dark blade notch
        Color(0xFF10B981), // Emerald accent
        Color(0xFFFF5E00), // Back to Orange
      ],
      stops: const [0.0, 0.25, 0.5, 0.7, 0.85, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepGradientBorderPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}
