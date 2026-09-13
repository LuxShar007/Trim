import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../widgets/api_key_modal.dart';
import '../widgets/spring_button.dart';
import 'trim_workspace_screen.dart';
import 'trimming_screen.dart';

/// The Brain Dump Screen:
/// An almost absurdly simple, distraction-free, OLED edge-to-edge canvas.
class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final TextEditingController _ideaController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasContent = false;
  int _charCount = 0;
  bool _isSubmitting = false;

  static const String _sampleBloatedIdea =
      'I want to build a social fitness app for crypto traders with AI avatars, '
      'a multi-tiered decentralized staking economy, an in-app 3D metaverse gym, '
      'direct TikTok cross-posting, daily horoscope workouts, and a 50-step '
      'meal logging flow with barcode scanning and NFT achievements.';

  @override
  void initState() {
    super.initState();
    _ideaController.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
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

  @override
  void dispose() {
    _ideaController.removeListener(_onTextChanged);
    _ideaController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitIdea() async {
    final text = _ideaController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    _focusNode.unfocus();

    try {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TrimmingScreen(rawIdea: text),
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Media query keyboard bottom inset
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isFocused = _focusNode.hasFocus;

    return Scaffold(
      backgroundColor: AppColors.canvas, // Pure OLED black
      resizeToAvoidBottomInset: false, // Custom keyboard handling for fluidity
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

                  // TOP BAR: Enlarged Trim wordmark with signature orange dot & Workspace action
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

                  const SizedBox(height: AppSpacing.xxl),

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

                  // Sub-bar with character counter and sample prompt trigger (overflow-safe)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            _ideaController.text = _sampleBloatedIdea;
                            _ideaController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _sampleBloatedIdea.length),
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
                              decorationColor: AppColors.orange.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_charCount chars',
                        style: AppTypography.monoCounter.copyWith(
                          fontSize: 11.0,
                          color: isFocused ? AppColors.textSecondary : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // MASSIVE BORDERLESS MULTILINE TEXT INPUT
                  Expanded(
                    child: AnimatedContainer(
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
                    ),
                  ),

                  // FLOATING TACTILE CTA ("TRIM THE FAT")
                  // Floats seamlessly above keyboard when active with full width
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xl,
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
                        onTap: (_hasContent && !_isSubmitting) ? _submitIdea : null,
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
}
