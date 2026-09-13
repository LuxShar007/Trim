import 'package:flutter/material.dart';
import 'feature_card.dart';
import 'trim_morph_card.dart';

export 'feature_card.dart' show FeatureCardType;

/// Translucent liquid glass feature card utilizing the TrimMorphCard system.
/// Maintains backwards compatibility while providing continuous states:
/// COLLAPSED, EXPANDING, EXPANDED, COLLAPSING with spring physics.
class GlassFeatureCard extends StatelessWidget {
  final String text;
  final String? reason;
  final FeatureCardType type;
  final int index;
  final VoidCallback? onPurged;
  final bool initiallyExpanded;

  const GlassFeatureCard({
    super.key,
    required this.text,
    this.reason,
    required this.type,
    this.index = 0,
    this.onPurged,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return TrimMorphCard(
      text: text,
      reason: reason,
      isPass: type == FeatureCardType.mustHave,
      index: index,
      onPurged: onPurged,
      initiallyExpanded: initiallyExpanded,
    );
  }
}
