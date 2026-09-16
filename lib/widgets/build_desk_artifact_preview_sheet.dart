import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utilities/haptics_util.dart';
import '../services/office_kit_service.dart';

/// Clean, focused TRIM Markdown document viewer.
/// Renders persistent Build Desk specifications directly in the application
/// without external browser navigation or HTML execution hazards.
class BuildDeskArtifactPreviewSheet extends StatefulWidget {
  final String filename;
  final String content;
  final String sessionId;
  final String projectName;
  final Color accentColor;

  const BuildDeskArtifactPreviewSheet({
    super.key,
    required this.filename,
    required this.content,
    required this.sessionId,
    required this.projectName,
    this.accentColor = AppColors.orange,
  });

  /// Static helper to display the sheet modally.
  static Future<void> show({
    required BuildContext context,
    required String filename,
    required String content,
    required String sessionId,
    required String projectName,
    Color accentColor = AppColors.orange,
  }) {
    HapticsUtil.lightClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BuildDeskArtifactPreviewSheet(
        filename: filename,
        content: content,
        sessionId: sessionId,
        projectName: projectName,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<BuildDeskArtifactPreviewSheet> createState() =>
      _BuildDeskArtifactPreviewSheetState();
}

class _BuildDeskArtifactPreviewSheetState
    extends State<BuildDeskArtifactPreviewSheet> {
  bool _copied = false;
  bool _sharing = false;

  Future<void> _copyToClipboard() async {
    HapticsUtil.lightClick();
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareFile() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await OfficeKitService.instance.shareSingleArtifact(
        context: context,
        sessionId: widget.sessionId,
        filename: widget.filename,
        content: widget.content,
        projectName: widget.projectName,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border.all(color: const Color(0xFF24242A), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E36),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 4.0, 12.0, 12.0),
            child: Row(
              children: [
                // Filename & Type Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.filename,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16161C),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: const Color(0xFF27272A),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              'MARKDOWN · .md',
                              style: AppTypography.monoLabel.copyWith(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFA1A1AA),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            widget.projectName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.0,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Action: Copy
                IconButton(
                  tooltip: _copied ? 'Copied' : 'Copy markdown',
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 19,
                    color: _copied ? AppColors.emerald : const Color(0xFFA1A1AA),
                  ),
                  onPressed: _copyToClipboard,
                ),

                // Quick Action: Share
                IconButton(
                  tooltip: 'Share artifact',
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.orange,
                          ),
                        )
                      : const Icon(
                          Icons.share_rounded,
                          size: 19,
                          color: Color(0xFFA1A1AA),
                        ),
                  onPressed: _sharing ? null : _shareFile,
                ),

                // Close Button
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF71717A),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.8, color: Color(0xFF1D1D24)),

          // Scrollable Document Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 36.0),
              child: SelectableText(
                widget.content,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  height: 1.6,
                  color: const Color(0xFFD4D4D8),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
