import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';
import '../services/trim_voice_service.dart';
import '../widgets/api_key_modal.dart';
import '../widgets/spring_button.dart';
import '../widgets/voice_waveform.dart';
import 'trim_workspace_screen.dart';
import 'trimming_screen.dart';

/// The two primary capture modes in Trim.
enum BrainDumpInputMode { type, speak }

/// The Brain Dump Screen:
/// An almost absurdly simple, distraction-free, OLED edge-to-edge canvas
/// supporting both tactile typing and native, premium voice input.
class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final TextEditingController _ideaController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  BrainDumpInputMode _inputMode = BrainDumpInputMode.type;
  late final TrimVoiceService _voiceService;

  bool _hasContent = false;
  int _charCount = 0;
  bool _isSubmitting = false;
  bool _isHoldingMic = false;
  String _preVoiceText = '';
  String? _voiceErrorMessage;
  Timer? _errorDismissTimer;
  DateTime? _lastSubmitTime;

  int _sampleIndex = 0;
  static const String _sampleBloatedIdea =
      'I want to build a social fitness app for crypto traders with AI avatars, '
      'a multi-tiered decentralized staking economy, an in-app 3D metaverse gym, '
      'direct TikTok cross-posting, daily horoscope workouts, and a 50-step '
      'meal logging flow with barcode scanning and NFT achievements.';

  static const List<String> _sampleBloatedIdeas = [
    _sampleBloatedIdea,
    'A hyper-local coffee ordering platform with drone delivery tracking, AR bean inspection, '
        'decentralized bean trading futures, barista tipping tokens, live streaming roasting cams, '
        'and a multi-tiered subscription club with physical merch boxes.',
    'An AI copilot for medical students that generates automatic flashcards, records 4-hour clinic audio, '
        'syncs across smart watches, hosts 3D anatomical VR dissections, runs competitive medical trivia '
        'leaderboards, and integrates with hospital ERPs.',
  ];

  @override
  void initState() {
    super.initState();
    _voiceService = TrimVoiceService.instance;
    _ideaController.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _voiceService.liveWordsListenable.addListener(_onLiveWordsChanged);
    _voiceService.errorListenable.addListener(_onVoiceErrorChanged);
    _voiceService.stateListenable.addListener(_onVoiceStateChanged);
  }

  void _onTextChanged() {
    final text = _ideaController.text;
    final hasContent = text.trim().isNotEmpty;
    if (_hasContent != hasContent || _charCount != text.length) {
      setState(() {
        _hasContent = hasContent;
        _charCount = text.length;
      });
    }
  }

  void _onLiveWordsChanged() {
    final liveWords = _voiceService.liveWords;
    if (_voiceService.state == TrimVoiceState.listening && liveWords.isNotEmpty) {
      final combined = _preVoiceText.isEmpty
          ? liveWords
          : '$_preVoiceText $liveWords';
      _ideaController.text = combined;
      _ideaController.selection = TextSelection.fromPosition(
        TextPosition(offset: combined.length),
      );
    }
  }

  void _onVoiceStateChanged() {
    if (mounted) setState(() {});
  }

  void _onVoiceErrorChanged() {
    final err = _voiceService.currentError;
    if (err != null && mounted) {
      setState(() {
        _voiceErrorMessage = err.displayMessage;
      });

      _errorDismissTimer?.cancel();
      _errorDismissTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) {
          setState(() {
            _voiceErrorMessage = null;
          });
        }
      });

      // Immediate or gentle fallback to typing
      if (err == TrimVoiceError.permissionDenied ||
          err == TrimVoiceError.notAvailable ||
          err == TrimVoiceError.transcriptionFailed) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted && _inputMode == BrainDumpInputMode.speak) {
            setState(() {
              _inputMode = BrainDumpInputMode.type;
            });
            _focusNode.requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    _voiceService.liveWordsListenable.removeListener(_onLiveWordsChanged);
    _voiceService.errorListenable.removeListener(_onVoiceErrorChanged);
    _voiceService.stateListenable.removeListener(_onVoiceStateChanged);
    _ideaController.removeListener(_onTextChanged);
    _ideaController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleInputMode(BrainDumpInputMode mode) async {
    if (_inputMode == mode) return;

    // If currently listening, stop first
    if (_voiceService.state == TrimVoiceState.listening) {
      await _voiceService.stopListening();
    }

    setState(() {
      _inputMode = mode;
      _voiceErrorMessage = null;
    });

    if (mode == BrainDumpInputMode.type) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _focusNode.unfocus();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _voiceErrorMessage = null;
      _preVoiceText = _ideaController.text.trim();
    });

    final success = await _voiceService.startListening();
    if (success) {
      HapticsUtil.mediumImpact();
    } else if (mounted) {
      final err = _voiceService.currentError ?? TrimVoiceError.notAvailable;
      setState(() {
        _voiceErrorMessage = err.displayMessage;
      });
    }
  }

  Future<void> _stopRecording() async {
    HapticsUtil.lightClick();
    await _voiceService.stopListening();
    if (mounted) {
      setState(() {
        _isHoldingMic = false;
        _preVoiceText = '';
      });
    }
  }

  Future<void> _cancelRecording() async {
    await _voiceService.cancelListening();
    if (mounted) {
      setState(() {
        _isHoldingMic = false;
        _ideaController.text = _preVoiceText;
        _preVoiceText = '';
        _voiceErrorMessage = null;
      });
    }
  }

  Future<void> _handleMicTap() async {
    if (_voiceService.state == TrimVoiceState.listening) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  /// Safely resets the composer, text controller, counters, and transient states
  /// so the screen represents a brand new idea when returning from a Trim flow.
  void resetForNewIdea() => _resetForNewIdea();

  void _resetForNewIdea() {
    if (_voiceService.state == TrimVoiceState.listening) {
      _voiceService.cancelListening();
    }
    _errorDismissTimer?.cancel();

    _ideaController.clear();

    if (mounted) {
      setState(() {
        _hasContent = false;
        _charCount = 0;
        _isSubmitting = false;
        _isHoldingMic = false;
        _preVoiceText = '';
        _voiceErrorMessage = null;
        _inputMode = BrainDumpInputMode.type;
      });
      _focusNode.unfocus();
    }
  }

  Future<void> _submitIdea() async {
    final finalSubmittedIdea = _ideaController.text.trim();
    if (finalSubmittedIdea.isEmpty || _isSubmitting) return;

    final now = DateTime.now();
    if (_lastSubmitTime != null &&
        now.difference(_lastSubmitTime!) < const Duration(milliseconds: 750)) {
      return;
    }
    _lastSubmitTime = now;

    // Immediate synchronous lock against rapid double-taps
    _isSubmitting = true;
    setState(() {});

    // If still listening, stop before submitting
    if (_voiceService.state == TrimVoiceState.listening) {
      await _voiceService.stopListening();
    }
    if (!mounted) {
      _isSubmitting = false;
      return;
    }

    _focusNode.unfocus();
    HapticsUtil.mediumImpact();

    try {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TrimmingScreen(rawIdea: finalSubmittedIdea),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: SpringPhysics.snapCurve,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    } finally {
      if (mounted) {
        _resetForNewIdea();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isFocused = _focusNode.hasFocus;
    final voiceState = _voiceService.state;
    final isListening = voiceState == TrimVoiceState.listening;

    return Scaffold(
      backgroundColor: AppColors.canvas, // Pure OLED black
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // TOP BAR: Trim wordmark with signature orange dot & Workspace action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onLongPress: () => ApiKeyModal.show(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.5,
                              height: 8.5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.orange,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'Trim',
                              style: GoogleFonts.manrope(
                                fontSize: 22.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Your Workspace',
                        icon: const Icon(
                          Icons.folder_outlined,
                          color: Color(0xFFD4D4D8),
                          size: 21,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const TrimWorkspaceScreen(),
                              transitionDuration: const Duration(milliseconds: 320),
                              reverseTransitionDuration: const Duration(milliseconds: 250),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // LARGE HEADLINE: "What are you building?"
                  Text(
                    'What are you building?',
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 25.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // MODE SELECTOR (TYPE or SPEAK) & SUB-BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tactile Segmented Toggle: [ TYPE ] [ SPEAK ]
                      Container(
                        padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSegmentButton(
                              label: 'TYPE',
                              icon: Icons.keyboard_alt_outlined,
                              isActive: _inputMode == BrainDumpInputMode.type,
                              onTap: () => _toggleInputMode(BrainDumpInputMode.type),
                            ),
                            _buildSegmentButton(
                              label: 'SPEAK',
                              icon: Icons.mic_rounded,
                              isActive: _inputMode == BrainDumpInputMode.speak,
                              onTap: () => _toggleInputMode(BrainDumpInputMode.speak),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_inputMode == BrainDumpInputMode.type)
                              Flexible(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticsUtil.lightClick();
                                    final sample = _sampleBloatedIdeas[
                                        _sampleIndex % _sampleBloatedIdeas.length];
                                    _sampleIndex++;
                                    _ideaController.text = sample;
                                    _ideaController.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(offset: sample.length),
                                    );
                                  },
                                  child: Text(
                                    'Insert Bloated Idea Sample',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoCounter.copyWith(
                                      fontSize: 11.0,
                                      color: AppColors.orange,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          AppColors.orange.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              '$_charCount chars',
                              style: AppTypography.monoCounter.copyWith(
                                fontSize: 11.0,
                                color: isFocused || isListening
                                    ? AppColors.textSecondary
                                    : AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ERROR BANNER (Permission denied, silence, failure fallback)
                  if (_voiceErrorMessage != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: AppColors.cutRed.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: AppColors.cutRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _voiceErrorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _voiceErrorMessage = null);
                              _toggleInputMode(BrainDumpInputMode.type);
                            },
                            child: Text(
                              'TYPE',
                              style: AppTypography.monoChip.copyWith(
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // MAIN WORKSPACE CONTENT: TYPING OR SPEAKING
                  Expanded(
                    child: _inputMode == BrainDumpInputMode.type
                        ? _buildTypeInput(isFocused)
                        : _buildSpeakInput(voiceState, isListening),
                  ),

                  // FLOATING TACTILE CTA ("TRIM THE FAT")
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: bottomInset > 0
                          ? bottomInset + AppSpacing.md
                          : AppSpacing.xl,
                      top: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: SpringButton(
                        label: 'Trim the Fat',
                        icon: Icons.content_cut_rounded,
                        isEnabled: _hasContent && !_isSubmitting,
                        isLoading: _isSubmitting,
                        enableLiquidTransition: true,
                        onTap: (_hasContent && !_isSubmitting)
                            ? _submitIdea
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tactile Segment Toggle item
  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: SpringPhysics.snapCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isActive
                ? AppColors.borderHighlight
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? AppColors.orange : AppColors.textDisabled,
            ),
            const SizedBox(width: 5.0),
            Text(
              label,
              style: AppTypography.monoLabel.copyWith(
                fontSize: 11.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.textPrimary : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Classic Multiline Text Input
  Widget _buildTypeInput(bool isFocused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isFocused
                ? AppColors.orange.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: isFocused ? AppSpacing.md : 0.0),
        child: TextField(
          controller: _ideaController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          cursorColor: AppColors.orange,
          cursorWidth: 2.2,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 17.0,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Dump your massive, bloated app idea here...',
            hintStyle: AppTypography.bodyLarge.copyWith(
              fontSize: 17.0,
              height: 1.5,
              color: AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }

  /// Native, Premium Voice Input Canvas
  Widget _buildSpeakInput(TrimVoiceState voiceState, bool isListening) {
    final text = _ideaController.text.trim();

    return Column(
      children: [
        // Top section: Live/Transcribed Text Review Card
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () => _toggleInputMode(BrainDumpInputMode.type),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isListening
                      ? AppColors.orange.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 1.0,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isListening ? 'LIVE TRANSCRIPTION' : 'REVIEW YOUR IDEA',
                          style: AppTypography.monoHeader.copyWith(
                            fontSize: 10.0,
                            color: isListening
                                ? AppColors.orange
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (text.isNotEmpty)
                          Text(
                            'TAP TO EDIT IN TYPE',
                            style: AppTypography.monoCounter.copyWith(
                              fontSize: 9.5,
                              color: AppColors.textDisabled,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (text.isEmpty)
                      Text(
                        isListening
                            ? 'Listening… speak features, ideas, workflows…'
                            : 'Tap the microphone or press and hold to speak your raw product idea.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 15.0,
                          height: 1.45,
                        ),
                      )
                    else
                      Text(
                        text,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16.0,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Bottom section: Waveform, Tactile Microphone Button, and Product State
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: ValueListenableBuilder<double>(
            valueListenable: _voiceService.soundLevelListenable,
            builder: (context, soundLevel, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 7-bar subtle spring waveform visualizer
                  VoiceWaveform(
                    state: voiceState,
                    soundLevel: soundLevel,
                    height: 32.0,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Tactile circular microphone button (tap or press-and-hold)
                  VoiceMicrophoneButton(
                    state: voiceState,
                    soundLevel: soundLevel,
                    onTap: _handleMicTap,
                    onLongPressStart: () {
                      setState(() => _isHoldingMic = true);
                      _startRecording();
                    },
                    onLongPressEnd: () {
                      _stopRecording();
                    },
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Product Status: SPEAK / LISTENING… / RELEASE TO FINISH
                  VoiceStatusIndicator(
                    state: voiceState,
                    isHolding: _isHoldingMic,
                  ),

                  const SizedBox(height: 2.0),

                  // Cancellation / Review Actions
                  if (isListening)
                    GestureDetector(
                      onTap: _cancelRecording,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'CANCEL',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 10.5,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    )
                  else if (text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _toggleInputMode(BrainDumpInputMode.type),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'SWITCH TO TYPE TO EDIT',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.borderHighlight,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
