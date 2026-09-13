import 'package:flutter/material.dart';
import '../core/animations/spring_physics.dart';

/// Reusable continuity transitions for TRIM:
/// Eliminates abrupt screen switches with soft spring contraction and expansion.
class TrimLiquidTransition {
  TrimLiquidTransition._();

  /// Creates a PageRouteBuilder with soft spring expansion and fade.
  static PageRouteBuilder<T> pageRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 380),
    Duration reverseDuration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final springCurved = CurvedAnimation(
          parent: animation,
          curve: SpringPhysics.snapCurve,
          reverseCurve: Curves.easeInQuad,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(springCurved),
            child: child,
          ),
        );
      },
    );
  }

  /// Softly contracts the active screen before popping back to the previous screen.
  static Future<void> softPop(BuildContext context, {AnimationController? exitController}) async {
    if (exitController != null) {
      await exitController.forward();
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
