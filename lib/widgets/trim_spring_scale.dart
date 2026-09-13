import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../core/animations/spring_physics.dart';
import '../core/utilities/haptics_util.dart';

/// Tactile spring scale wrapper for physical touch responses.
/// Compresses slightly on press down (e.g., 0.98 for cards, 0.95 for buttons)
/// and releases using a genuine [SpringSimulation].
class TrimSpringScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final SpringDescription spring;
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const TrimSpringScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
    this.spring = SpringPhysics.cardPress,
    this.enableHaptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<TrimSpringScale> createState() => _TrimSpringScaleState();
}

class _TrimSpringScaleState extends State<TrimSpringScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticsUtil.lightClick();
    }
    _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOutQuad,
    );
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _releaseSpring();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _releaseSpring();
  }

  void _releaseSpring() {
    final simulation = SpringSimulation(
      widget.spring,
      _controller.value,
      0.0,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: widget.behavior,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * (1.0 - widget.pressedScale));
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
