import 'package:flutter/services.dart';

/// Haptic feedback utility providing tactile physical sensations on modern Android hardware.
class HapticsUtil {
  HapticsUtil._();

  /// Subtle click on button press-down.
  static void lightClick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Solid release impact when trimming or triggering key actions.
  static void mediumImpact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for harsh truth reveals and guillotine cuts.
  static void heavyImpact() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
