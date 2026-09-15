import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations/spring_physics.dart';

/// Lightweight liquid boundary between SURVIVE and CUT during the trimming sequence.
/// Creates the illusion of a morphing liquid meniscus separating core capabilities
/// from discarded bloat with micro-ripples and cards carried by the motion.
class LiquidSeparationBoundary extends StatefulWidget {
  final double width;
  final double height;

  const LiquidSeparationBoundary({
    super.key,
    this.width = 320.0,
    this.height = 190.0,
  });

  @override
  State<LiquidSeparationBoundary> createState() => _LiquidSeparationBoundaryState();
}

class _LiquidSeparationBoundaryState extends State<LiquidSeparationBoundary>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _collapseController;

  static const List<String> _triageBloatExamples = [
    'VR Metaverse Avatar Store',
    'Crypto Staking Rewards',
    'Global Influencer Feed',
    'Tiered Paywall Subscriptions',
    'Gamified Achievement Badges',
  ];

  int _bloatIndex = 0;

  @override
  void initState() {
    super.initState();

    // Gentle rippling liquid meniscus wave (1800ms period)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Noise liquid collapse cycle: feature card is squeezed out of the MVP
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _bloatIndex = (_bloatIndex + 1) % _triageBloatExamples.length;
            });
            _collapseController.forward(from: 0.0);
          }
        }
      });

    _collapseController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF10B981);
    const mutedRed = Color(0xFFEF4444);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _collapseController]),
        builder: (context, child) {
          final waveVal = _waveController.value;
          final cVal = _collapseController.value;

          // Compute Noise Liquid Collapse states according to spec:
          // 1. card slightly compresses (0.0 -> 0.25)
          // 2. border glow reduces (0.15 -> 0.45)
          // 3. card width/height visually contracts (0.3 -> 0.7)
          // 4. content fades (0.35 -> 0.75)
          // 5. card translates away (0.45 -> 0.9)
          // 6. final opacity reaches zero (0.8 -> 1.0)
          final double cardScale;
          final double cardScaleY;
          final double glowOpacity;
          final double contentOpacity;
          final double translateY;
          final double translateX;
          final double finalOpacity;

          if (cVal < 0.25) {
            // State 1: Card slightly compresses using spring physics
            final t = cVal / 0.25;
            final comp = Curves.easeOutQuad.transform(t);
            cardScale = 1.0 - (comp * 0.06);
            cardScaleY = 1.0 - (comp * 0.08);
            glowOpacity = 1.0 - (comp * 0.4);
            contentOpacity = 1.0;
            translateX = 0.0;
            translateY = 0.0;
            finalOpacity = 1.0;
          } else if (cVal < 0.70) {
            // State 2 & 3: Border glow drops, width/height contracts (squeezed out)
            final t = (cVal - 0.25) / 0.45;
            final squeeze = SpringPhysics.liquidCurve.transform(t);
            cardScale = 0.94 - (squeeze * 0.22); // contracts to ~0.72
            cardScaleY = 0.92 - (squeeze * 0.35); // contracts vertically
            glowOpacity = (1.0 - squeeze).clamp(0.0, 1.0) * 0.5;
            contentOpacity = (1.0 - (t * 1.5)).clamp(0.0, 1.0);
            translateX = squeeze * 18.0;
            translateY = squeeze * 14.0;
            finalOpacity = (1.0 - (t * 0.8)).clamp(0.0, 1.0);
          } else {
            // State 4, 5, 6: Content fades, translates away, opacity reaches 0
            final t = (cVal - 0.70) / 0.30;
            final fadeOut = Curves.easeInCubic.transform(t);
            cardScale = 0.72 - (fadeOut * 0.3);
            cardScaleY = 0.57 - (fadeOut * 0.3);
            glowOpacity = 0.0;
            contentOpacity = 0.0;
            translateX = 18.0 + (fadeOut * 30.0);
            translateY = 14.0 + (fadeOut * 24.0);
            finalOpacity = (0.2 * (1.0 - fadeOut)).clamp(0.0, 1.0);
          }

          // Subtle floating motion for surviving core chip (carried by wave)
          final surviveFloat = math.sin(waveVal * 2 * math.pi) * 3.5;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Liquid Separation Meniscus Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidSeparatorPainter(
                    waveProgress: waveVal,
                    emeraldColor: emerald,
                    mutedRedColor: mutedRed,
                  ),
                ),
              ),

              // SURVIVE Zone Header & Floating Chip (Top zone)
              Positioned(
                top: 8.0 + surviveFloat,
                left: 12.0,
                right: 12.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: emerald,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SURVIVE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: emerald,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1914),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: emerald.withValues(alpha: 0.45),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: emerald.withValues(alpha: 0.12),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 11, color: emerald),
                          const SizedBox(width: 4),
                          Text(
                            'CORE LOOP PRESERVED',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD1FAE5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // CUT Zone Header & Squeezed Out Noise Card (Bottom zone)
              Positioned(
                bottom: 8.0,
                left: 12.0,
                right: 12.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: mutedRed,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CUT',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                color: mutedRed.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'SQUEEZING FAT',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.0,
                            letterSpacing: 1.0,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Noise Card undergoing Liquid Collapse
                    Transform.translate(
                      offset: Offset(translateX, translateY),
                      child: Transform.scale(
                        scaleX: cardScale,
                        scaleY: cardScaleY,
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: finalOpacity,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 7.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF140D0D),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: mutedRed.withValues(alpha: 0.45 * glowOpacity),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: mutedRed.withValues(alpha: 0.15 * glowOpacity),
                                  blurRadius: 12.0 * glowOpacity,
                                  spreadRadius: -1.0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: mutedRed.withValues(alpha: 0.7 * contentOpacity),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Opacity(
                                    opacity: contentOpacity,
                                    child: Text(
                                      _triageBloatExamples[_bloatIndex],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFFA1A1AA),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: mutedRed.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PURGED',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: mutedRed.withValues(alpha: 0.75 * contentOpacity),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter that draws a restrained liquid wave boundary
/// dividing the SURVIVE (upper emerald) and CUT (lower red) zones.
class _LiquidSeparatorPainter extends CustomPainter {
  final double waveProgress;
  final Color emeraldColor;
  final Color mutedRedColor;

  _LiquidSeparatorPainter({
    required this.waveProgress,
    required this.emeraldColor,
    required this.mutedRedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.48;
    final path = Path();
    path.moveTo(0, midY);

    // Sine wave parameters (restrained amplitude: 4.5px, smooth continuous frequency)
    const amplitude = 4.2;
    const frequency = 2 * math.pi / 220.0;
    final phase = waveProgress * 2 * math.pi;

    for (double x = 0; x <= size.width; x += 4.0) {
      final y = midY + (math.sin((x * frequency) + phase) * amplitude) +
          (math.sin((x * frequency * 0.5) - phase) * (amplitude * 0.35));
      path.lineTo(x, y);
    }

    // Top soft emerald aura along the wave line
    final topAuraPaint = Paint()
      ..color = emeraldColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawPath(path, topAuraPaint);

    // Bottom soft red aura along the wave line
    final bottomAuraPaint = Paint()
      ..color = mutedRedColor.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, bottomAuraPaint);

    // Crisp liquid separation hairline
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          emeraldColor.withValues(alpha: 0.1),
          emeraldColor.withValues(alpha: 0.7),
          const Color(0xFFFF5E00).withValues(alpha: 0.6), // Orange friction apex
          mutedRedColor.withValues(alpha: 0.7),
          mutedRedColor.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, midY - 6, size.width, 12))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidSeparatorPainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress;
  }
}
