import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'brain_dump_screen.dart';

/// TRIM — Intro / Startup Screen
///
/// Sequence (total ≈ 2 800 ms before push):
///   0 ms  – screen mounts, orb breath starts
/// 300 ms  – wordmark slides up + fades in (spring)
/// 750 ms  – tagline fades in
/// 1400 ms – bottom rule draws in
/// 2300 ms – fade-to-black curtain descends
/// 2800 ms – replace with BrainDumpScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Orb breath ──────────────────────────────────────────────────────────────
  late final AnimationController _orbCtrl;
  late final Animation<double> _orbScale;
  late final Animation<double> _orbOpacity;

  // ── Wordmark ─────────────────────────────────────────────────────────────────
  late final AnimationController _wordCtrl;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _wordFade;

  // ── Tagline ──────────────────────────────────────────────────────────────────
  late final AnimationController _tagCtrl;
  late final Animation<double> _tagFade;

  // ── Rule ─────────────────────────────────────────────────────────────────────
  late final AnimationController _ruleCtrl;
  late final Animation<double> _ruleScale;

  // ── Curtain (exit) ───────────────────────────────────────────────────────────
  late final AnimationController _curtainCtrl;
  late final Animation<double> _curtainFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ── Orb: slow sinusoidal breath ────────────────────────────────────────────
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _orbScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut),
    );
    _orbOpacity = Tween<double>(begin: 0.30, end: 0.60).animate(
      CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut),
    );

    // ── Wordmark: spring slide-up ──────────────────────────────────────────────
    _wordCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _wordSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOutCubic),
    );
    _wordFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wordCtrl, curve: const Interval(0, 0.7)),
    );

    // ── Tagline: simple fade ───────────────────────────────────────────────────
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tagFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut),
    );

    // ── Rule: draw-in ─────────────────────────────────────────────────────────
    _ruleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ruleScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ruleCtrl, curve: Curves.easeOutCubic),
    );

    // ── Curtain: fade to black ─────────────────────────────────────────────────
    _curtainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _curtainFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _curtainCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Wordmark entrance after 300 ms
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _wordCtrl.forward();

    // Tagline after 750 ms total
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _tagCtrl.forward();

    // Rule after 1 400 ms total
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _ruleCtrl.forward();

    // Begin curtain at 2 300 ms
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _curtainCtrl.forward();

    // Navigate at 2 800 ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      _FadeRoute(child: const BrainDumpScreen()),
    );
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _wordCtrl.dispose();
    _tagCtrl.dispose();
    _ruleCtrl.dispose();
    _curtainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background orb glow ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _OrbPainter(
                  scale: _orbScale.value,
                  opacity: _orbOpacity.value,
                ),
              );
            },
          ),

          // ── Noise overlay (subtle grain) ────────────────────────────────────
          const Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: _NoisePainter()),
          ),

          // ── Centre content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Wordmark
                FadeTransition(
                  opacity: _wordFade,
                  child: SlideTransition(
                    position: _wordSlide,
                    child: const _Wordmark(),
                  ),
                ),

                const SizedBox(height: 20),

                // Tagline
                FadeTransition(
                  opacity: _tagFade,
                  child: const _Tagline(),
                ),

                const SizedBox(height: 36),

                // Draw-in rule
                AnimatedBuilder(
                  animation: _ruleScale,
                  builder: (context, _) => Transform.scale(
                    scaleX: _ruleScale.value,
                    child: Container(
                      width: 40,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(180),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withAlpha(80),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 4),

                // Bottom caption
                FadeTransition(
                  opacity: _tagFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Text(
                      'TRIM THE FAT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 3.5,
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Exit curtain ────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _curtainFade,
            builder: (context, _) => IgnorePointer(
              child: Opacity(
                opacity: _curtainFade.value,
                child: const ColoredBox(
                  color: AppColors.canvas,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wordmark ──────────────────────────────────────────────────────────────────

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _ScissorsGlyph(),
        const SizedBox(width: 14),
        Text(
          'TRIM',
          style: GoogleFonts.manrope(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _ScissorsGlyph extends StatefulWidget {
  const _ScissorsGlyph();

  @override
  State<_ScissorsGlyph> createState() => _ScissorsGlyphState();
}

class _ScissorsGlyphState extends State<_ScissorsGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _angle = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      builder: (_, _) => Transform.rotate(
        angle: _angle.value,
        child: const CustomPaint(
          size: Size(36, 36),
          painter: _ScissorsPainter(),
        ),
      ),
    );
  }
}

class _ScissorsPainter extends CustomPainter {
  const _ScissorsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    final bladeA = Paint()
      ..color = AppColors.emerald
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bladeB = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pivotPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    // Blade A — emerald diagonal
    final a1 = Offset(
      cx - r * math.cos(math.pi / 4),
      cy - r * math.sin(math.pi / 4),
    );
    final a2 = Offset(
      cx + r * math.cos(math.pi / 4),
      cy + r * math.sin(math.pi / 4),
    );
    canvas.drawLine(a1, a2, bladeA);

    // Blade B — orange diagonal
    final b1 = Offset(
      cx - r * math.cos(math.pi / 4),
      cy + r * math.sin(math.pi / 4),
    );
    final b2 = Offset(
      cx + r * math.cos(math.pi / 4),
      cy - r * math.sin(math.pi / 4),
    );
    canvas.drawLine(b1, b2, bladeB);

    // Pivot dot
    canvas.drawCircle(Offset(cx, cy), 3.0, pivotPaint);
  }

  @override
  bool shouldRepaint(_ScissorsPainter old) => false;
}

// ── Tagline ───────────────────────────────────────────────────────────────────

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
          height: 1.5,
        ),
        children: const [
          TextSpan(text: 'Turn ideas into '),
          TextSpan(
            text: 'ruthless',
            style: TextStyle(
              color: AppColors.emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' MVPs.\nNo fluff. No '),
          TextSpan(
            text: 'bloat.',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background orb painter ────────────────────────────────────────────────────

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.scale, required this.opacity});

  final double scale;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    // Emerald orb
    final emeraldRadius = size.width * 0.55 * scale;
    final emeraldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.emerald.withAlpha((opacity * 0.38 * 255).round()),
          AppColors.emerald.withAlpha(0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: emeraldRadius),
      );
    canvas.drawCircle(Offset(cx, cy), emeraldRadius, emeraldPaint);

    // Orange accent orb (offset lower-right)
    final orangeRadius = size.width * 0.28 * scale;
    final ox = cx + size.width * 0.18;
    final oy = cy + size.height * 0.08;
    final orangePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.orange.withAlpha((opacity * 0.25 * 255).round()),
          AppColors.orange.withAlpha(0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(ox, oy), radius: orangeRadius),
      );
    canvas.drawCircle(Offset(ox, oy), orangeRadius, orangePaint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.scale != scale || old.opacity != opacity;
}

// ── Noise painter (static grain) ─────────────────────────────────────────────

class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 4000; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter _) => false;
}

// ── Page route: instant fade-replace (no slide) ───────────────────────────────

class _FadeRoute extends PageRouteBuilder {
  _FadeRoute({required Widget child})
      : super(
          pageBuilder: (_, _, _) => child,
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        );
}
