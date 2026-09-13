import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A fluid, high-refresh rate loader with cycling brutal AI PM thoughts
/// and a razor shimmer animation.
class AnimatedShimmerLoader extends StatefulWidget {
  const AnimatedShimmerLoader({super.key});

  @override
  State<AnimatedShimmerLoader> createState() => _AnimatedShimmerLoaderState();
}

class _AnimatedShimmerLoaderState extends State<AnimatedShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _quoteTimer;
  int _quoteIndex = 0;

  static const List<String> _quotes = [
    'Sharpening the guillotine...',
    'Decimating feature creep...',
    'Stripping out vanity metrics...',
    'Exposing the illusion of complexity...',
    'Rejecting unneeded microservices...',
    'Slicing straight to the MVP core...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _quoteTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF5E00);
    const emerald = Color(0xFF10B981);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        decoration: BoxDecoration(
          color: const Color(0xFF09090C).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: const Color(0xFF27272A),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: orange.withValues(alpha: 0.16),
              blurRadius: 32.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shimmer blade bar
            SizedBox(
              height: 4.0,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFF18181B)),
                        FractionallySizedBox(
                          widthFactor: 0.45,
                          alignment: Alignment(-1.0 + (_controller.value * 2.5), 0.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  orange,
                                  emerald,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),

            // Icon with pulse
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + (0.08 * (0.5 - (_controller.value - 0.5).abs()));
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141419),
                      border: Border.all(
                        color: orange.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      color: orange,
                      size: 28.0,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20.0),

            // Main status
            Text(
              'TRIM · ANALYZING',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 8.0),

            // Animated quote switcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    )),
                    child: child,
                  ),
                );
              },
              child: Text(
                _quotes[_quoteIndex],
                key: ValueKey<int>(_quoteIndex),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFD4D4D8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
