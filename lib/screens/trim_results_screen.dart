import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';
import '../models/trim_result.dart';
import '../models/trim_session.dart';
import '../services/office_kit_service.dart';
import '../services/trim_session_repository.dart';
import '../widgets/trim_glass_button.dart';
import '../widgets/trim_glass_surface.dart';
import '../widgets/trim_morph_card.dart';
import '../widgets/trim_scope_metric.dart';

/// Screen presenting the ruthless AI PM triage verdict (Visual Design System V3).
/// Hierarchy:
/// 1. PROJECT NAME
/// 2. Core Value (calm, no decorative container)
/// 3. Scope Metric (dynamic survivors + percent removed)
/// 4. THE CORE (Must-haves morphing cards)
/// 5. THE NOISE (Progressive disclosure for >5 items, "NOTHING TO CUT." empty state)
/// 6. BUILD FIRST (editorial minimal sequence)
/// 7. PRODUCT TRUTH (concise, restrained orange accent, normal typography)
/// 8. LOCK MVP (tactile glass confirmation & locked state)
/// 9. EXPORT MVP (spring morph state button + clean Markdown spec)
class TrimResultsScreen extends StatefulWidget {
  final TrimResult? result;
  final TrimSession? session;
  final bool isFromHistory;

  const TrimResultsScreen({
    super.key,
    this.result,
    this.session,
    this.isFromHistory = false,
  }) : assert(result != null || session != null, 'Either result or session must be provided');

  @override
  State<TrimResultsScreen> createState() => _TrimResultsScreenState();
}

class _TrimResultsScreenState extends State<TrimResultsScreen>
    with TickerProviderStateMixin {
  late final TrimResult _result;
  late final String _sessionId;
  late bool _isLocked;
  bool _showLockConfirmation = false;
  bool _showAllNoise = false;

  late final AnimationController _coreController;
  late final AnimationController _truthController;
  late final AnimationController _exitController;

  TrimButtonMorphState _exportState = TrimButtonMorphState.idle;
  TrimButtonMorphState _buildDeskState = TrimButtonMorphState.idle;


  @override
  void initState() {
    super.initState();

    if (widget.session != null) {
      _result = widget.session!.toTrimResult();
      _sessionId = widget.session!.id;
      _isLocked = widget.session!.isLocked;
    } else {
      _result = widget.result!;
      _isLocked = false;
      final newSession = TrimSession.fromTrimResult(
        originalIdea: '',
        result: _result,
        isLocked: false,
      );
      _sessionId = newSession.id;
      TrimSessionRepository.instance.saveSession(newSession);
    }

    _coreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _truthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _coreController.forward();
        HapticsUtil.mediumImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _truthController.forward();
    });
  }

  @override
  void dispose() {
    _coreController.dispose();
    _truthController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _softExit() async {
    await _exitController.forward();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    if (_exportState != TrimButtonMorphState.idle) return;

    setState(() {
      _exportState = TrimButtonMorphState.loading;
    });

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final markdown = _result.toMarkdown(isLocked: _isLocked);

    try {
      // Ensure clipboard copy immediately succeeds across platforms
      await Clipboard.setData(ClipboardData(text: markdown));
      HapticsUtil.lightClick();

      await SharePlus.instance.share(
        ShareParams(
          text: markdown,
          subject: '${_result.projectName} — Trimmed MVP Spec',
          sharePositionOrigin: origin,
        ),
      );

      if (!mounted) return;
      setState(() {
        _exportState = TrimButtonMorphState.success;
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _exportState = TrimButtonMorphState.idle;
          });
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _exportState = TrimButtonMorphState.idle;
        });
      }
    }
  }

  Future<void> _sendToBuildDesk(BuildContext context) async {
    if (_buildDeskState != TrimButtonMorphState.idle) return;

    setState(() {
      _buildDeskState = TrimButtonMorphState.loading;
    });

    try {
      await OfficeKitService.instance.sendToBuildDesk(
        context: context,
        result: _result,
      );

      if (!mounted) return;
      setState(() {
        _buildDeskState = TrimButtonMorphState.success;
      });

      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() {
            _buildDeskState = TrimButtonMorphState.idle;
          });
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _buildDeskState = TrimButtonMorphState.idle;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalFeatures = _result.mustHaves.length + _result.discardedBloat.length;
    final survivorsCount = _result.mustHaves.length;

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        final exitProgress = _exitController.value;
        final exitScale = 1.0 - (exitProgress * 0.04);
        final exitOpacity = (1.0 - exitProgress).clamp(0.0, 1.0);

        return Transform.scale(
          scale: exitScale,
          alignment: Alignment.center,
          child: Opacity(
            opacity: exitOpacity,
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFFD4D4D8),
                            size: 22,
                          ),
                          onPressed: _softExit,
                        ),
                        // State badge (Section 32)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isLocked ? const Color(0xFF07120D) : const Color(0xFF101015),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isLocked
                                  ? AppColors.emerald.withValues(alpha: 0.35)
                                  : const Color(0xFF24242A),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLocked) ...[
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.emerald,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                _isLocked
                                    ? 'MVP LOCKED'
                                    : (widget.isFromHistory ? 'HISTORY' : 'TRIMMED MVP'),
                                style: AppTypography.monoLabel.copyWith(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: _isLocked ? AppColors.emerald : const Color(0xFFE4E4E7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _softExit,
                          child: Text(
                            widget.isFromHistory ? 'Done' : 'Restart',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. PROJECT NAME (Visually dominant, Manrope 700)
                          Text(
                            _result.projectName,
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6.0),

                          // 2. Core Value (Smaller, calm, readable, no decorative container)
                          Text(
                            _result.coreValue,
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                              color: const Color(0xFFD4D4D8),
                            ),
                          ),
                          const SizedBox(height: 28.0),

                          // 3. THE CORE
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emerald,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'THE CORE',
                                style: AppTypography.monoHeader.copyWith(
                                  color: AppColors.emerald,
                                  fontSize: 11.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            '${_result.mustHaves.length} Must-Haves',
                            style: AppTypography.monoCounter.copyWith(
                              fontSize: 12.0,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(height: 10.0),

                          if (_result.mustHaves.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No core features identified.',
                                style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF71717A)),
                              ),
                            )
                          else
                            ..._result.mustHaves.asMap().entries.map((entry) {
                              return _buildCoreCard(
                                index: entry.key,
                                child: RepaintBoundary(
                                  child: TrimMorphCard(
                                    index: entry.key,
                                    text: entry.value.feature,
                                    reason: entry.value.reason,
                                    isPass: true,
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 28.0),

                          // 4. THE NOISE
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'THE NOISE',
                                style: AppTypography.monoHeader.copyWith(
                                  color: const Color(0xFFA1A1AA),
                                  fontSize: 11.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            '${_result.discardedBloat.length} Discarded',
                            style: AppTypography.monoCounter.copyWith(
                              fontSize: 12.0,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                          const SizedBox(height: 10.0),

                          _buildNoiseSection(),

                          // 5. BUILD FIRST (Minimal build sequence)
                          if (_result.buildOrder.isNotEmpty) ...[
                            const SizedBox(height: 28.0),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BUILD FIRST',
                                  style: AppTypography.monoHeader.copyWith(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 11.5,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              '${_result.buildOrder.length} Steps',
                              style: AppTypography.monoCounter.copyWith(
                                fontSize: 12.0,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            ..._result.buildOrder.asMap().entries.map((entry) {
                              final stepNumber = (entry.key + 1).toString().padLeft(2, '0');
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 2.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF131318),
                                        borderRadius: BorderRadius.circular(4.0),
                                        border: Border.all(
                                          color: const Color(0xFF24242A),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        stepNumber,
                                        style: AppTypography.monoChip.copyWith(
                                          color: const Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 28.0),

                          // 6. PRODUCT TRUTH
                          _buildProductTruthBlock(),

                          const SizedBox(height: 28.0),

                          // 7. SCOPE:
                          TrimScopeMetric(
                            totalFeatures: totalFeatures,
                            survivorsCount: survivorsCount,
                            showHeader: true,
                          ),

                          const SizedBox(height: 28.0),

                          // 8. MVP LOCKED (Sections 29, 30, 31)
                          _buildMvpLockSection(),

                          const SizedBox(height: 14.0),

                          // 9. EXPORT MVP (Section 24)
                          Builder(
                            builder: (btnContext) {
                              return TrimGlassButton(
                                label: 'EXPORT MVP',
                                icon: Icons.ios_share_rounded,
                                variant: TrimButtonVariant.primary,
                                morphState: _exportState,
                                loadingLabel: 'EXPORTING...',
                                successLabel: 'EXPORTED ✓',
                                onTap: () => _exportMarkdown(btnContext),
                              );
                            },
                          ),
                          const SizedBox(height: 14.0),

                          // 10. TRIM ANOTHER IDEA
                          Center(
                            child: TextButton(
                              onPressed: _softExit,
                              child: Text(
                                widget.isFromHistory ? 'BACK TO WORKSPACE' : 'TRIM ANOTHER IDEA',
                                style: AppTypography.monoLabel.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  /// Section 15: Progressive Noise Disclosure with Spring Physics
  Widget _buildNoiseSection() {
    final noiseItems = _result.discardedBloat;

    if (noiseItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOTHING TO CUT.',
              style: AppTypography.monoHeader.copyWith(
                fontSize: 12.0,
                color: const Color(0xFFE4E4E7),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'This idea is already focused.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13.0,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      );
    }

    final bool hasLongNoise = noiseItems.length > 5;
    final primaryItems = hasLongNoise ? noiseItems.take(4).toList() : noiseItems;
    final secondaryItems = hasLongNoise ? noiseItems.skip(4).toList() : <DiscardedFeature>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...primaryItems.asMap().entries.map((entry) {
          return RepaintBoundary(
            child: TrimMorphCard(
              index: entry.key,
              text: entry.value.feature,
              reason: entry.value.reason,
              isPass: false,
            ),
          );
        }),
        if (hasLongNoise) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: SpringPhysics.snapCurve,
            alignment: Alignment.topCenter,
            child: _showAllNoise
                ? Column(
                    children: secondaryItems.asMap().entries.map((entry) {
                      return RepaintBoundary(
                        child: TrimMorphCard(
                          index: entry.key + 4,
                          text: entry.value.feature,
                          reason: entry.value.reason,
                          isPass: false,
                        ),
                      );
                    }).toList(),
                  )
                : const SizedBox.shrink(),
          ),
          if (!_showAllNoise)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA1A1AA),
                    backgroundColor: const Color(0xFF131318),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Color(0xFF24242A), width: 0.8),
                    ),
                  ),
                  icon: const Icon(Icons.expand_more_rounded, size: 16),
                  label: Text(
                    '+ ${secondaryItems.length} MORE CUT',
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFFD4D4D8),
                    ),
                  ),
                  onPressed: () {
                    HapticsUtil.lightClick();
                    setState(() {
                      _showAllNoise = true;
                    });
                  },
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Sections 29, 30, 31: Lock MVP & Reopen MVP
  Widget _buildMvpLockSection() {
    final survivors = _result.mustHaves.length;
    final cuts = _result.discardedBloat.length;

    if (_isLocked) {
      // Locked State (Section 30 & 31)
      return RepaintBoundary(
        child: TrimGlassSurface(
          intensity: TrimGlassIntensity.low,
          accentColor: AppColors.emerald,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: AppColors.emerald,
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'MVP LOCKED',
                        style: AppTypography.monoHeader.copyWith(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      HapticsUtil.lightClick();
                      setState(() => _isLocked = false);
                      TrimSessionRepository.instance.setLocked(_sessionId, false);
                    },
                    child: Text(
                      'REOPEN MVP',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA1A1AA),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '$survivors capabilities committed · $cuts features rejected',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE4E4E7),
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                'Build this version first.',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.0,
                  color: const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 12.0),
              // MVP LOCKED -> SEND TO BUILD DESK
              Builder(
                builder: (btnContext) {
                  return TrimGlassButton(
                    label: 'SEND TO BUILD DESK',
                    icon: Icons.laptop_mac_rounded,
                    variant: TrimButtonVariant.primary,
                    morphState: _buildDeskState,
                    loadingLabel: 'PREPARING MVP...',
                    successLabel: 'READY ON DESK ✓',
                    height: 46.0,
                    onTap: () => _sendToBuildDesk(btnContext),
                  );
                },
              ),
              const SizedBox(height: 6.0),
              Text(
                'Syncs 4 specs to laptop: MVP_SPEC.md, BUILD_ORDER.md, CUT_FEATURES.md, PRODUCT_TRUTH.md',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 9.5,
                  color: const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showLockConfirmation) {
      // Restrained glass confirmation surface (Section 29)
      return RepaintBoundary(
        child: TrimGlassSurface(
          intensity: TrimGlassIntensity.medium,
          accentColor: AppColors.emerald,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOCK MVP',
                style: AppTypography.monoHeader.copyWith(
                  fontSize: 11.5,
                  letterSpacing: 0.9,
                  color: const Color(0xFFE4E4E7),
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                '$survivors capabilities committed\n$cuts features rejected',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Build this version first.',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.0,
                  color: const Color(0xFFA1A1AA),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _showLockConfirmation = false);
                    },
                    child: Text(
                      'CANCEL',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    onPressed: () {
                      HapticsUtil.mediumImpact();
                      setState(() {
                        _isLocked = true;
                        _showLockConfirmation = false;
                      });
                      TrimSessionRepository.instance.setLocked(_sessionId, true);
                    },
                    child: Text(
                      'LOCK MVP',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Default Unlocked Action
    return RepaintBoundary(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE4E4E7),
          backgroundColor: const Color(0xFF0D0D12),
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: Color(0xFF24242A), width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        icon: const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFA1A1AA)),
        label: Text(
          'LOCK MVP',
          style: AppTypography.monoLabel.copyWith(
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFFE4E4E7),
          ),
        ),
        onPressed: () {
          HapticsUtil.lightClick();
          setState(() => _showLockConfirmation = true);
        },
      ),
    );
  }

  Widget _buildCoreCard({
    required int index,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _coreController,
      builder: (context, _) {
        final start = (0.08 * index).clamp(0.0, 0.4);
        final end = (start + 0.6).clamp(0.0, 1.0);
        final t = ((_coreController.value - start) / (end - start)).clamp(0.0, 1.0);
        final springVal = Curves.easeOutBack.transform(t);
        final scale = 0.95 + (springVal * 0.05);
        final translateY = (1.0 - t) * 5.0;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductTruthBlock() {
    return AnimatedBuilder(
      animation: _truthController,
      builder: (context, child) {
        final val = _truthController.value;
        final cardSpring = SpringPhysics.snapCurve.transform(val);
        final cardScale = 0.98 + (cardSpring * 0.02);

        final textT = ((val - 0.25) / 0.75).clamp(0.0, 1.0);
        final textOpacity = Curves.easeIn.transform(textT);

        return Transform.scale(
          scale: cardScale,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    'PRODUCT TRUTH',
                    style: AppTypography.monoHeader.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Opacity(
                opacity: textOpacity,
                child: Text(
                  _result.harshTruth,
                  style: AppTypography.productTruth.copyWith(
                    fontSize: 15.0,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF4F4F5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
