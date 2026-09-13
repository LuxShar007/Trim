import 'dart:async';
import 'package:flutter/material.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';
import '../models/trim_result.dart';
import '../services/groq_service.dart';
import '../services/trim_engine.dart';
import '../widgets/api_key_modal.dart';
import '../widgets/spring_button.dart';
import 'trim_results_screen.dart';

/// Processing sequence states (Visual Design System V3).
enum ProcessingStage {
  understanding, // State 1: "UNDERSTANDING" - fragments appear
  trimming, // State 2: "TRIMMING" - fragments separate into SURVIVE & CUT
  locking, // State 3: "LOCKING" - surviving features consolidate
  verdictReady, // State 4: "{TOTAL} → {SURVIVORS}" using actual returned data
}

enum TrimApiState { idle, loading, success, error }

/// Dedicated processing screen between Brain Dump and Results.
/// Replaces developer quotes & scissors with a deliberate 4-stage product sequence.
class TrimmingScreen extends StatefulWidget {
  final String rawIdea;
  final TrimEngine? engine;

  const TrimmingScreen({
    super.key,
    required this.rawIdea,
    this.engine,
  });

  @override
  State<TrimmingScreen> createState() => _TrimmingScreenState();
}

class _TrimmingScreenState extends State<TrimmingScreen>
    with TickerProviderStateMixin {
  late final TrimEngine _trimEngine;

  ProcessingStage _stage = ProcessingStage.understanding;
  TrimApiState _apiState = TrimApiState.loading;
  bool _isExecuting = false;
  String? _errorMessage;
  TrimErrorType? _errorType;
  TrimResult? _result;

  int _currentRequestId = 0;
  TrimCancellableToken? _activeCancelToken;

  Timer? _stageTimer1;
  Timer? _stageTimer2;

  late final AnimationController _motionController;

  // Sample feature fragments extracted for visual motion
  late final List<String> _coreFragments;
  late final List<String> _noiseFragments;

  @override
  void initState() {
    super.initState();
    _trimEngine = widget.engine ?? TrimEngine();

    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _prepareFragments();
    _startStageTimeline();
    _executeTriage();
  }

  void _prepareFragments() {
    // Extract keywords or use clean contextual fragments
    final words = widget.rawIdea
        .split(RegExp(r'[,.\s]+'))
        .where((w) => w.length > 3)
        .take(6)
        .toList();

    if (words.length >= 4) {
      _coreFragments = [
        '${words[0]} flow',
        '${words[1]} core',
      ];
      _noiseFragments = [
        words.length > 2 ? words[2] : 'Avatar Feed',
        words.length > 3 ? words[3] : 'Token Rewards',
        words.length > 4 ? words[4] : 'Social Layer',
      ];
    } else {
      _coreFragments = [
        'Core user loop',
        'Primary action engine',
      ];
      _noiseFragments = [
        '3D Avatar customization',
        'Gamified leaderboards',
        'Social sharing feed',
      ];
    }
  }

  void _startStageTimeline() {
    _stageTimer1?.cancel();
    _stageTimer2?.cancel();

    _stageTimer1 = Timer(const Duration(milliseconds: 1600), () {
      if (mounted && _stage == ProcessingStage.understanding) {
        setState(() {
          _stage = ProcessingStage.trimming;
        });
        _motionController.forward(from: 0.0);
      }
    });

    _stageTimer2 = Timer(const Duration(milliseconds: 3200), () {
      if (mounted && _stage == ProcessingStage.trimming) {
        setState(() {
          _stage = ProcessingStage.locking;
        });
        _motionController.forward(from: 0.0);
      }
    });
  }

  void _cancelActiveRequest() {
    _activeCancelToken?.cancel();
    _activeCancelToken = null;
    _currentRequestId++;
  }

  @override
  void dispose() {
    _cancelActiveRequest();
    _stageTimer1?.cancel();
    _stageTimer2?.cancel();
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _executeTriage({bool isRetry = false}) async {
    if (_isExecuting && !isRetry) return;

    if (isRetry) {
      _cancelActiveRequest();
      _errorMessage = null;
      _errorType = null;
      _result = null;
      _stage = ProcessingStage.understanding;
      _motionController.reset();
      _startStageTimeline();
    }

    final int requestId = ++_currentRequestId;
    final cancelToken = TrimCancellableToken();
    _activeCancelToken = cancelToken;

    _isExecuting = true;
    setState(() {
      _apiState = TrimApiState.loading;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      final savedKey = await GroqService.getSavedApiKey();

      if (!mounted || requestId != _currentRequestId || cancelToken.isCancelled) {
        return;
      }

      if (savedKey == null || savedKey.trim().isEmpty) {
        throw const GroqUnauthorizedException(
          'Missing Groq API Key. Please tap "Update Groq API Key" below.',
        );
      }

      final TrimResult result = await _trimEngine.trimIdea(
        rawIdea: widget.rawIdea,
        apiKey: savedKey,
        cancelToken: cancelToken,
        requestId: requestId,
      );

      if (!mounted || requestId != _currentRequestId || cancelToken.isCancelled) {
        return;
      }

      _result = result;
      setState(() {
        _stage = ProcessingStage.verdictReady;
        _apiState = TrimApiState.success;
        _isExecuting = false;
      });

      HapticsUtil.mediumImpact();

      // Brief physical settle before navigating into Results
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted || requestId != _currentRequestId || cancelToken.isCancelled) {
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TrimResultsScreen(result: result),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final springAnim = CurvedAnimation(
              parent: animation,
              curve: SpringPhysics.snapCurve,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(springAnim),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted || requestId != _currentRequestId || cancelToken.isCancelled) {
        return;
      }

      final TrimErrorType errorType;
      if (e is GroqException) {
        errorType = e.errorType;
      } else if (e is TimeoutException) {
        errorType = TrimErrorType.requestTimeout;
      } else {
        errorType = TrimErrorType.networkError;
      }

      setState(() {
        _apiState = TrimApiState.error;
        _errorMessage = e.toString();
        _errorType = errorType;
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _apiState == TrimApiState.error
                  ? _buildErrorState()
                  : _buildProcessingState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    final String stageLabel;
    switch (_stage) {
      case ProcessingStage.understanding:
        stageLabel = 'UNDERSTANDING';
        break;
      case ProcessingStage.trimming:
        stageLabel = 'TRIMMING';
        break;
      case ProcessingStage.locking:
        stageLabel = 'LOCKING';
        break;
      case ProcessingStage.verdictReady:
        final total = (_result?.mustHaves.length ?? 0) + (_result?.discardedBloat.length ?? 0);
        final survivors = _result?.mustHaves.length ?? 0;
        stageLabel = '$total → $survivors SURVIVE';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top product status label: TRIM · ANALYZING
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TRIM · ANALYZING',
              style: AppTypography.monoLabel.copyWith(
                fontSize: 11.0,
                letterSpacing: 1.0,
                color: const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Stage Title (Human, editorial, non-cyberpunk)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: SpringPhysics.snapCurve,
                )),
                child: child,
              ),
            );
          },
          child: Text(
            stageLabel,
            key: ValueKey<String>(stageLabel),
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Intelligent Feature Fragment Surface
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: const Color(0xFF09090D),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: const Color(0xFF1E1E24),
              width: 1.0,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildStageVisual(),
          ),
        ),
      ],
    );
  }

  Widget _buildStageVisual() {
    switch (_stage) {
      case ProcessingStage.understanding:
        return Column(
          key: const ValueKey('stage_understanding'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FEATURE EXTRACTION',
              style: AppTypography.monoLabel.copyWith(
                fontSize: 9.5,
                color: const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ..._coreFragments.map((f) => _buildFragmentChip(f, false)),
                ..._noiseFragments.map((f) => _buildFragmentChip(f, false)),
              ],
            ),
          ],
        );

      case ProcessingStage.trimming:
        return Column(
          key: const ValueKey('stage_trimming'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // SURVIVE row
            Row(
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.emerald)),
                const SizedBox(width: 6),
                Text(
                  'SURVIVE',
                  style: AppTypography.monoLabel.copyWith(fontSize: 9.5, color: AppColors.emerald),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: _coreFragments.map((f) => _buildFragmentChip(f, true, isCore: true)).toList(),
            ),
            const SizedBox(height: 14),

            // CUT row
            Row(
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.cutRed)),
                const SizedBox(width: 6),
                Text(
                  'CUT',
                  style: AppTypography.monoLabel.copyWith(fontSize: 9.5, color: const Color(0xFF71717A)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: _noiseFragments.map((f) => _buildFragmentChip(f, true, isCore: false)).toList(),
            ),
          ],
        );

      case ProcessingStage.locking:
      case ProcessingStage.verdictReady:
        return Column(
          key: const ValueKey('stage_locking'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.emerald)),
                const SizedBox(width: 6),
                Text(
                  'CORE MVP CONSOLIDATION',
                  style: AppTypography.monoLabel.copyWith(fontSize: 9.5, color: AppColors.emerald),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._coreFragments.map((f) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3.5),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1713),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 12, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
    }
  }

  Widget _buildFragmentChip(String text, bool active, {bool isCore = false}) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (!active) {
      bgColor = const Color(0xFF131318);
      borderColor = const Color(0xFF222228);
      textColor = const Color(0xFFA1A1AA);
    } else if (isCore) {
      bgColor = AppColors.emerald.withValues(alpha: 0.12);
      borderColor = AppColors.emerald.withValues(alpha: 0.35);
      textColor = AppColors.emerald;
    } else {
      bgColor = const Color(0xFF140D0D);
      borderColor = const Color(0xFF2E1C1C);
      textColor = const Color(0xFF71717A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 11.5,
          color: textColor,
          decoration: (active && !isCore) ? TextDecoration.lineThrough : null,
          decorationColor: AppColors.cutRed.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final String errorTitle;
    switch (_errorType) {
      case TrimErrorType.requestTimeout:
        errorTitle = 'REQUEST TIMED OUT';
        break;
      case TrimErrorType.requestCancelled:
        errorTitle = 'TRIMMING CANCELLED';
        break;
      case TrimErrorType.networkError:
        errorTitle = 'NETWORK ERROR';
        break;
      case TrimErrorType.parseError:
        errorTitle = 'RESPONSE PARSE ERROR';
        break;
      case TrimErrorType.httpError:
        if (_errorMessage != null &&
            (_errorMessage!.contains('401') ||
                _errorMessage!.contains('Unauthorized') ||
                _errorMessage!.contains('API Key'))) {
          errorTitle = 'UNAUTHORIZED API KEY';
        } else if (_errorMessage != null && _errorMessage!.contains('429')) {
          errorTitle = 'RATE LIMIT EXCEEDED';
        } else if (_errorMessage != null && _errorMessage!.contains('Server Error')) {
          errorTitle = 'GROQ SERVER ERROR';
        } else {
          errorTitle = 'GROQ API ERROR';
        }
        break;
      default:
        errorTitle = 'TRIMMING FAILED';
        break;
    }

    final isKeyRelated = _errorMessage != null &&
        (_errorMessage!.contains('API Key') ||
            _errorMessage!.contains('401') ||
            _errorMessage!.contains('Unauthorized'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cutRedSubtle,
            border: Border.all(color: AppColors.cutRed.withValues(alpha: 0.6), width: 1.0),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.cutRed,
            size: 24,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          errorTitle,
          style: AppTypography.monoHeader.copyWith(
            fontSize: 14.0,
            color: AppColors.cutRed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'An unexpected error occurred.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: SpringButton(
            label: 'Retry Trimming',
            onTap: !_isExecuting ? () => _executeTriage(isRetry: true) : null,
            isLoading: _isExecuting,
            isEnabled: !_isExecuting,
          ),
        ),
        if (isKeyRelated) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ApiKeyModal.show(context),
            icon: const Icon(Icons.key_rounded, size: 14, color: AppColors.orange),
            label: Text(
              'Update Groq API Key',
              style: AppTypography.monoChip.copyWith(
                color: AppColors.orange,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Return to Brain Dump',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
