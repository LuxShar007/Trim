import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../services/trim_voice_service.dart';

/// A subtle, spring-based sound waveform visualizer for Trim.
/// Displays 7 balanced vertical bars that dynamically scale based on
/// microphone sound level and ambient spring physics.
class VoiceWaveform extends StatefulWidget {
  final TrimVoiceState state;
  final double soundLevel; // 0.0 to 1.0
  final double height;
  final Color? barColor;

  const VoiceWaveform({
    super.key,
    required this.state,
    required this.soundLevel,
    this.height = 48.0,
    this.barColor,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;

  static const List<double> _barWeights = [
    0.35,
    0.6,
    0.85,
    1.0,
    0.85,
    0.6,
    0.35,
  ];

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.state == TrimVoiceState.listening) {
      _ambientController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == TrimVoiceState.listening &&
        !_ambientController.isAnimating) {
      _ambientController.repeat(reverse: true);
    } else if (widget.state != TrimVoiceState.listening &&
        _ambientController.isAnimating) {
      _ambientController.stop();
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == TrimVoiceState.listening;
    final activeColor = widget.barColor ?? AppColors.orange;

    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final phase = _ambientController.value * 2 * math.pi;

        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barWeights.length, (index) {
              final weight = _barWeights[index];
              final ambientVariation =
                  math.sin(phase + (index * 0.8)).abs() * 0.25;

              double targetBarHeight;
              if (isListening) {
                // When listening, scale heavily with sound level + ambient spring pulse
                final levelFactor = (widget.soundLevel * 0.75) + ambientVariation;
                targetBarHeight =
                    (6.0 + (widget.height - 10.0) * weight * levelFactor.clamp(0.1, 1.0));
              } else {
                // Resting idle state: subtle resting pills
                targetBarHeight = 5.0;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 3.5,
                  height: targetBarHeight,
                  decoration: BoxDecoration(
                    color: isListening
                        ? activeColor.withValues(
                            alpha: 0.6 + (0.4 * (targetBarHeight / widget.height)))
                        : AppColors.borderHighlight.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Tactile Microphone Spring Button supporting both Tap-to-Talk and Press-and-Hold
class VoiceMicrophoneButton extends StatefulWidget {
  final TrimVoiceState state;
  final double soundLevel;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const VoiceMicrophoneButton({
    super.key,
    required this.state,
    required this.soundLevel,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  State<VoiceMicrophoneButton> createState() => _VoiceMicrophoneButtonState();
}

class _VoiceMicrophoneButtonState extends State<VoiceMicrophoneButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == TrimVoiceState.listening;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        widget.onLongPressStart();
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);
        widget.onLongPressEnd();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : (isListening ? 1.05 : 1.0),
        duration: const Duration(milliseconds: 160),
        curve: SpringPhysics.snapCurve,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening
                ? AppColors.orange.withValues(alpha: 0.12)
                : AppColors.surfaceElevated,
            border: Border.all(
              color: isListening
                  ? AppColors.orange.withValues(alpha: 0.8)
                  : AppColors.borderHighlight,
              width: isListening ? 2.0 : 1.5,
            ),
            boxShadow: isListening
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: 28,
              color: isListening ? AppColors.orange : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Concise status display under the microphone with product language
class VoiceStatusIndicator extends StatelessWidget {
  final TrimVoiceState state;
  final bool isHolding;

  const VoiceStatusIndicator({
    super.key,
    required this.state,
    this.isHolding = false,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (state) {
      case TrimVoiceState.listening:
        label = isHolding ? 'RELEASE TO FINISH' : 'LISTENING…';
        color = AppColors.orange;
        break;
      case TrimVoiceState.processing:
        label = 'PROCESSING…';
        color = AppColors.emerald;
        break;
      case TrimVoiceState.idle:
        label = 'SPEAK';
        color = AppColors.textSecondary;
        break;
    }

    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }
}
