import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Smooth spring-rotated chevron arrow indicating expansion state.
class TrimChevron extends StatelessWidget {
  final double progress; // 0.0 = collapsed, 1.0 = expanded (180 deg)
  final Color? color;
  final double size;

  const TrimChevron({
    super.key,
    required this.progress,
    this.color,
    this.size = 17.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: progress * math.pi,
      alignment: Alignment.center,
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: size,
        color: color ?? const Color(0xFF71717A),
      ),
    );
  }
}
