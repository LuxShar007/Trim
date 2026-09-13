import 'package:flutter/services.dart';

/// Haptic feedback utility providing tactile physical sensations on modern Android hardware.
class HapticsUtil {
  HapticsUtil._();

  /// Subtle click on button press-down.
  static void lightClick() {
    HapticFeedback.selectionClick();
  }

  /// Solid release impact when trimming or triggering key actions.
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for harsh truth reveals and guillotine cuts.
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
}
