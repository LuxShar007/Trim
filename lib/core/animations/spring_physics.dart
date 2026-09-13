import 'package:flutter/animation.dart';

/// Standardized spring physics configurations for 60Hz/90Hz/120Hz/144Hz tactile interactions.
/// NEVER uses linear animations.
class SpringPhysics {
  SpringPhysics._();

  /// Snappy, tactile bounce for button presses and card taps.
  static const SpringDescription tactile = SpringDescription(
    mass: 1.0,
    stiffness: 420.0,
    damping: 24.0,
  );

  /// Card press response for TrimMorphCard (scale 0.98).
  static const SpringDescription cardPress = SpringDescription(
    mass: 1.0,
    stiffness: 460.0,
    damping: 26.0,
  );

  /// Button press response for TrimGlassButton (scale 0.95).
  static const SpringDescription buttonPress = SpringDescription(
    mass: 1.0,
    stiffness: 400.0,
    damping: 22.0,
  );

  /// Expansion spring with slight overshoot followed by soft settle.
  static const SpringDescription cardExpansion = SpringDescription(
    mass: 1.0,
    stiffness: 280.0,
    damping: 23.0,
  );

  /// Softer spring for layout transitions and screen handoffs.
  static const SpringDescription gentle = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 26.0,
  );

  /// Fluid spring with subtle bounce for liquid morphing.
  static const SpringDescription liquid = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 22.0,
  );

  /// Squeezing spring for noise collapse transitions.
  static const SpringDescription liquidSqueeze = SpringDescription(
    mass: 1.0,
    stiffness: 280.0,
    damping: 20.0,
  );

  /// Curve for route and state transitions with slight overshoot.
  static const Curve snapCurve = Curves.easeOutBack;

  /// Shorter snappy curve for micro-animations.
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Smooth fluid curve for morphing and reveals.
  static const Curve liquidCurve = Curves.easeOutCubic;

  /// Soft entrance curve.
  static const Curve softEntrance = Curves.easeOutQuad;

  /// Soft exit curve.
  static const Curve softExit = Curves.easeInQuad;
}
