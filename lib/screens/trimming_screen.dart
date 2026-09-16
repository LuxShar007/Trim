import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';
import '../models/trim_result.dart';
import '../services/groq_service.dart';
import '../services/trim_engine.dart';
import '../widgets/spring_button.dart';
import 'trim_results_screen.dart';

/// Intentional processing stages for physical idea reduction.
enum ProcessingStage {
  understanding, // Stage 1: "UNDERSTANDING" - digesting the raw idea
  featureExtraction, // Stage 2: "FEATURE EXTRACTION" - candidate features emerge
  trimming, // Stage 3: "TRIMMING" - features separate into CORE & NOISE
  consolidating, // Stage 4: "CONSOLIDATING" - noise compresses, core groups
  locking, // Stage 5: "LOCKING" - MVP is locked
  verdictReady, // Stage 6: "{TOTAL} → {SURVIVORS} SURVIVE"
}

enum TrimApiState { idle, loading, success, error }

/// Dedicated processing screen between Brain Dump and Verdict.
/// Delivers an intentional, premium physical product experience with spring physics,
/// real-state synchronization, and zero developer telemetry or fake progress bars.
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
  Duration? _rateLimitRetryAfter;
  DateTime? _lastRetryTime;
  TrimResult? _result;

  int _currentRequestId = 0;
  TrimCancellableToken? _activeCancelToken;

  // Timeline timers for intentional sequence pacing
  Timer? _stageTimer1;
  Timer? _stageTimer2;
  Timer? _stageTimer3;
  Timer? _stageTimer4;

  late final AnimationController _motionController;

  // Contextual feature fragments extracted from user's idea or actual TrimResult
  List<String> _coreFragments = [];
  List<String> _noiseFragments = [];
  int _totalFeatureCount = 0;
  int _survivorCount = 0;
  int _cutCount = 0;

  // Precomputed outward directions for noise fragments during collapse
  static const List<Offset> _noiseOutwardDirections = [
    Offset(-1.2, -0.6),
    Offset(1.2, -0.5),
    Offset(-1.1, 0.7),
    Offset(1.1, 0.8),
    Offset(0.0, -1.2),
    Offset(-1.3, 0.0),
    Offset(1.3, 0.1),
    Offset(0.0, 1.2),
  ];

  @override
  void initState() {
    super.initState();
    _trimEngine = widget.engine ?? TrimEngine();

    // Spring motion controller for physical Scope Collapse feature transitions
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _prepareFragments();
    _startStageTimeline();
    _executeTriage();
  }

  void _prepareFragments() {
    // Extract candidate keywords from raw idea for contextual realism
    final words = widget.rawIdea
        .split(RegExp(r'[,.\s]+'))
        .where((w) => w.length > 3)
        .take(8)
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
        if (words.length > 5) words[5],
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
    _totalFeatureCount = _coreFragments.length + _noiseFragments.length;
    _survivorCount = _coreFragments.length;
    _cutCount = _noiseFragments.length;
  }

  void _applyRealResult(TrimResult result) {
    _result = result;
    _coreFragments = result.mustHaves.map((m) => m.feature).toList();
    _noiseFragments = result.discardedBloat.map((b) => b.feature).toList();
    _totalFeatureCount = _coreFragments.length + _noiseFragments.length;
    _survivorCount = _coreFragments.length;
    _cutCount = _noiseFragments.length;
  }

  void _startStageTimeline() {
    _cancelTimers();

    // Stage 1 -> 2: UNDERSTANDING -> FEATURES EMERGE (750ms)
    _stageTimer1 = Timer(const Duration(milliseconds: 750), () {
      if (mounted && _stage == ProcessingStage.understanding) {
        setState(() {
          _stage = ProcessingStage.featureExtraction;
        });
        _motionController.forward(from: 0.0);
        HapticsUtil.lightClick();
      }
    });

    // Stage 2 -> 3: FEATURES EMERGE -> CORE/NOISE SEPARATION (1650ms)
    _stageTimer2 = Timer(const Duration(milliseconds: 1650), () {
      if (mounted && _stage == ProcessingStage.featureExtraction) {
        setState(() {
          _stage = ProcessingStage.trimming;
        });
        _motionController.forward(from: 0.0);
        HapticsUtil.lightClick();
      }
    });

    // Stage 3 -> 4: CORE/NOISE SEPARATION -> SCOPE COLLAPSE (2550ms)
    _stageTimer3 = Timer(const Duration(milliseconds: 2550), () {
      if (mounted && _stage == ProcessingStage.trimming) {
        setState(() {
          _stage = ProcessingStage.consolidating;
        });
        _motionController.forward(from: 0.0);
        HapticsUtil.lightClick();
      }
    });

    // Stage 4 -> 5: SCOPE COLLAPSE -> MVP LOCKED (3450ms)
    _stageTimer4 = Timer(const Duration(milliseconds: 3450), () {
      if (mounted && _stage == ProcessingStage.consolidating) {
        setState(() {
          _stage = ProcessingStage.locking;
        });
        _motionController.forward(from: 0.0);
        HapticsUtil.mediumImpact();

        // If the real AI result has already arrived, reveal verdict immediately
        if (_result != null) {
          _revealVerdictAndNavigate(_result!);
        }
      }
    });
  }

  void _cancelTimers() {
    _stageTimer1?.cancel();
    _stageTimer2?.cancel();
    _stageTimer3?.cancel();
    _stageTimer4?.cancel();
  }

  void _cancelActiveRequest() {
    _activeCancelToken?.cancel();
    _activeCancelToken = null;
    _currentRequestId++;
  }

  @override
  void dispose() {
    _cancelActiveRequest();
    _cancelTimers();
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _executeTriage({bool isRetry = false}) async {
    if (_isExecuting) {
      if (kDebugMode) {
        debugPrint('[TRIM DIAGNOSTIC] Blocked duplicate execution: request already in flight (isRetry: $isRetry)');
      }
      return;
    }

    if (isRetry) {
      final now = DateTime.now();
      if (_lastRetryTime != null &&
          now.difference(_lastRetryTime!) < const Duration(milliseconds: 750)) {
        return;
      }
      _lastRetryTime = now;
      _rateLimitRetryAfter = null;

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
      _isExecuting = false;

      // Real-state synchronization: if animation already reached LOCKING, reveal immediately,
      // otherwise briskly advance through remaining stages to avoid artificial lag.
      if (_stage == ProcessingStage.locking) {
        _revealVerdictAndNavigate(result);
      } else {
        _fastForwardToLockingAndVerdict(result);
      }
    } catch (e) {
      if (!mounted || requestId != _currentRequestId || cancelToken.isCancelled) {
        return;
      }

      final TrimErrorType errorType;
      Duration? retryAfter;
      if (e is GroqRateLimitException) {
        errorType = TrimErrorType.httpError;
        retryAfter = e.retryAfter;
      } else if (e is GroqException) {
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
        _rateLimitRetryAfter = retryAfter;
        _isExecuting = false;
      });
    }
  }

  void _fastForwardToLockingAndVerdict(TrimResult result) async {
    _cancelTimers();
    if (!mounted || _activeCancelToken?.isCancelled == true) return;

    _applyRealResult(result);

    if (_stage == ProcessingStage.understanding) {
      setState(() => _stage = ProcessingStage.featureExtraction);
      _motionController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted || _activeCancelToken?.isCancelled == true) return;
    }

    if (_stage == ProcessingStage.featureExtraction) {
      setState(() => _stage = ProcessingStage.trimming);
      _motionController.forward(from: 0.0);
      HapticsUtil.lightClick();
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted || _activeCancelToken?.isCancelled == true) return;
    }

    if (_stage == ProcessingStage.trimming) {
      setState(() => _stage = ProcessingStage.consolidating);
      _motionController.forward(from: 0.0);
      HapticsUtil.lightClick();
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || _activeCancelToken?.isCancelled == true) return;
    }

    if (_stage == ProcessingStage.consolidating) {
      setState(() => _stage = ProcessingStage.locking);
      _motionController.forward(from: 0.0);
      HapticsUtil.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _activeCancelToken?.isCancelled == true) return;
    }

    _revealVerdictAndNavigate(result);
  }

  void _revealVerdictAndNavigate(TrimResult result) async {
    if (!mounted) return;

    _applyRealResult(result);

    setState(() {
      _stage = ProcessingStage.verdictReady;
      _apiState = TrimApiState.success;
    });

    HapticsUtil.mediumImpact();

    // Intentional physical settle before navigating into Results
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted || _activeCancelToken?.isCancelled == true) {
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
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(springAnim),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: _apiState == TrimApiState.error
                      ? _buildErrorState()
                      : _buildProcessingState(),
                ),
              ),
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
      case ProcessingStage.featureExtraction:
        stageLabel = 'FEATURES EMERGE';
        break;
      case ProcessingStage.trimming:
        stageLabel = 'CORE / NOISE SEPARATION';
        break;
      case ProcessingStage.consolidating:
        stageLabel = 'SCOPE COLLAPSE';
        break;
      case ProcessingStage.locking:
        stageLabel = 'MVP LOCKED';
        break;
      case ProcessingStage.verdictReady:
        stageLabel = '$_totalFeatureCount → $_survivorCount SURVIVE';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top product status label: TRIM · ANALYZING (with glowing emerald indicator)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D12),
            borderRadius: BorderRadius.circular(100.0),
            border: Border.all(
              color: const Color(0xFF1E1E24),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.5),
                      blurRadius: 6.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TRIM · ANALYZING',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Animated Stage Title (Editorial, clean, spring transition)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.18),
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
              fontSize: _stage == ProcessingStage.verdictReady ? 24.0 : 21.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: _stage == ProcessingStage.verdictReady
                  ? AppColors.emerald
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Intelligent Physical Reduction Surface
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: SpringPhysics.snapCurve,
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFF09090D),
            borderRadius: BorderRadius.circular(
              _stage == ProcessingStage.locking || _stage == ProcessingStage.verdictReady
                  ? 20.0
                  : 16.0,
            ),
            border: Border.all(
              color: _stage == ProcessingStage.locking || _stage == ProcessingStage.verdictReady
                  ? AppColors.emerald.withValues(alpha: 0.45)
                  : const Color(0xFF1E1E24),
              width: 1.0,
            ),
            boxShadow: [
              if (_stage == ProcessingStage.locking || _stage == ProcessingStage.verdictReady)
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  blurRadius: 24.0,
                  spreadRadius: 1.0,
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
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
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF71717A),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'PARSING PRODUCT CONTEXT',
                  style: AppTypography.monoLabel.copyWith(
                    fontSize: 9.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F14),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: const Color(0xFF1B1B22),
                  width: 0.8,
                ),
              ),
              child: Text(
                widget.rawIdea.length > 120
                    ? '${widget.rawIdea.substring(0, 120)}...'
                    : widget.rawIdea,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.0,
                  height: 1.45,
                  color: const Color(0xFFA1A1AA),
                ),
              ),
            ),
          ],
        );

      case ProcessingStage.featureExtraction:
        return Column(
          key: const ValueKey('stage_feature_extraction'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'FEATURES EMERGE',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.5,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$_totalFeatureCount FEATURES',
                    style: AppTypography.monoChip.copyWith(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ..._coreFragments.map((f) => _buildAnimatedChip(f, isEmerging: true)),
                ..._noiseFragments.map((f) => _buildAnimatedChip(f, isEmerging: true)),
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
            // Core survivor candidate row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'CORE CANDIDATES ($_survivorCount)',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.5,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ESSENTIAL',
                  style: AppTypography.monoChip.copyWith(
                    fontSize: 8.5,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7.0,
              runSpacing: 7.0,
              children: _coreFragments
                  .take(4)
                  .map((f) => _buildFragmentChip(f, isCore: true, isSeparated: true))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Noise candidate row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cutRed,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'NOISE CANDIDATES ($_cutCount)',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
                Text(
                  'BLOAT',
                  style: AppTypography.monoChip.copyWith(
                    fontSize: 8.5,
                    color: AppColors.cutRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7.0,
              runSpacing: 7.0,
              children: _noiseFragments
                  .take(4)
                  .map((f) => _buildFragmentChip(f, isCore: false, isSeparated: true))
                  .toList(),
            ),
          ],
        );

      case ProcessingStage.consolidating:
        // THE SCOPE COLLAPSE:
        // Noise fragments push outward, compress, fade and disappear.
        // Core fragments move inward toward central focal point.
        return AnimatedBuilder(
          key: const ValueKey('stage_consolidating'),
          animation: _motionController,
          builder: (context, child) {
            final double progress = Curves.easeInOutCubic.transform(_motionController.value);
            final double noiseScale = (1.0 - progress * 0.85).clamp(0.01, 1.0);
            final double noiseOpacity = (1.0 - progress * 1.3).clamp(0.0, 1.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Signature Metric Badge: TOTAL -> SURVIVORS SURVIVE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'THE SCOPE COLLAPSE',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 9.5,
                            letterSpacing: 1.1,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '$_totalFeatureCount → $_survivorCount SURVIVE',
                        style: AppTypography.monoChip.copyWith(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Converging Core Survivors (inward translation toward center)
                ..._coreFragments.take(3).map((f) {
                  return Transform.scale(
                    scale: 0.96 + (0.04 * progress),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3.0),
                      padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1712),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.35 + (0.2 * progress)),
                          width: 0.9,
                        ),
                        boxShadow: [
                          if (progress > 0.4)
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.08 * progress),
                              blurRadius: 10.0,
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_rounded, size: 12, color: AppColors.emerald),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // Collapsing Noise Fragments: pushed outward, compress & fade
                if (noiseOpacity > 0.01) ...[
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF52525B),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'DISCARDED NOISE (COLLAPSING OUTWARD)',
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 9.0,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: List.generate(
                      _noiseFragments.take(4).length,
                      (i) {
                        final dir = _noiseOutwardDirections[i % _noiseOutwardDirections.length];
                        final offset = Offset(dir.dx * progress * 50.0, dir.dy * progress * 30.0);
                        return Transform.translate(
                          offset: offset,
                          child: Transform.scale(
                            scale: noiseScale,
                            child: Opacity(
                              opacity: noiseOpacity,
                              child: _buildFragmentChip(
                                _noiseFragments[i],
                                isCore: false,
                                isCompressed: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );

      case ProcessingStage.locking:
      case ProcessingStage.verdictReady:
        return Column(
          key: const ValueKey('stage_locking'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _stage == ProcessingStage.verdictReady
                          ? 'MVP LOCKED'
                          : 'LOCKING MVP SCOPE...',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$_survivorCount SURVIVED',
                    style: AppTypography.monoChip.copyWith(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._coreFragments.take(3).map((f) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B14),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.4),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 12, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF1F5F9),
                        ),
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

  Widget _buildAnimatedChip(String text, {bool isEmerging = false}) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(
        parent: _motionController,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_motionController),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: const Color(0xFF131318),
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(
              color: const Color(0xFF24242C),
              width: 0.8,
            ),
          ),
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              color: const Color(0xFFA1A1AA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFragmentChip(
    String text, {
    required bool isCore,
    bool isSeparated = false,
    bool isCompressed = false,
  }) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isCore) {
      bgColor = AppColors.emerald.withValues(alpha: 0.12);
      borderColor = AppColors.emerald.withValues(alpha: 0.35);
      textColor = AppColors.emerald;
    } else {
      bgColor = isCompressed ? const Color(0xFF100A0A) : const Color(0xFF140D0D);
      borderColor = const Color(0xFF281818);
      textColor = const Color(0xFF71717A);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompressed ? 7.0 : 8.5,
        vertical: isCompressed ? 3.5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontSize: isCompressed ? 10.5 : 11.5,
          color: textColor,
          decoration: (!isCore && isSeparated) ? TextDecoration.lineThrough : null,
          decorationColor: AppColors.cutRed.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final String errorTitle;
    final String errorDescription;

    switch (_errorType) {
      case TrimErrorType.requestTimeout:
        errorTitle = 'ANALYSIS TIMED OUT';
        errorDescription =
            'The reduction took longer than expected to process. Please tap below to retry.';
        break;
      case TrimErrorType.requestCancelled:
        errorTitle = 'TRIMMING CANCELLED';
        errorDescription =
            'The active reduction was cancelled before completion.';
        break;
      case TrimErrorType.networkError:
        errorTitle = 'CONNECTION INTERRUPTED';
        errorDescription =
            'Unable to communicate with the analysis service. Please check your internet connection.';
        break;
      case TrimErrorType.parseError:
        errorTitle = 'ANALYSIS INTERRUPTED';
        errorDescription =
            'The product specification could not be finalized. Please tap retry to run a fresh pass.';
        break;
      case TrimErrorType.httpError:
        if (_errorMessage != null &&
            (_errorMessage!.contains('429') ||
                _errorMessage!.toLowerCase().contains('rate limit') ||
                _errorMessage!.toLowerCase().contains('too many trims'))) {
          errorTitle = 'TRIM PAUSED';
          errorDescription = _rateLimitRetryAfter != null && _rateLimitRetryAfter!.inSeconds > 0
              ? 'Too many trims are happening right now. Please wait ${_rateLimitRetryAfter!.inSeconds}s before retrying.'
              : 'Too many trims are happening right now. Give it a moment and try again.';
        } else {
          errorTitle = 'SERVICE TEMPORARILY BUSY';
          errorDescription =
              'Trim AI engine is temporarily unavailable. Tap below to retry.';
        }
        break;
      default:
        errorTitle = 'ANALYSIS INTERRUPTED';
        errorDescription =
            'An unexpected issue occurred during reduction. Tap below to retry.';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cutRedSubtle,
            border: Border.all(
              color: AppColors.cutRed.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.cutRed,
            size: 24,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          errorTitle,
          textAlign: TextAlign.center,
          style: AppTypography.monoHeader.copyWith(
            fontSize: 14.0,
            letterSpacing: 0.5,
            color: AppColors.cutRed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorDescription,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13.0,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: SpringButton(
            label: 'RETRY TRIMMING',
            onTap: !_isExecuting ? () => _executeTriage(isRetry: true) : null,
            isLoading: _isExecuting,
            isEnabled: !_isExecuting,
          ),
        ),
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
