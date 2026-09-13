import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations/spring_physics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../models/trim_session.dart';
import '../services/trim_session_repository.dart';
import '../widgets/spring_button.dart';
import '../widgets/trim_glass_surface.dart';
import 'trim_results_screen.dart';

/// The Local Trim Workspace:
/// A minimalist, personal, local-first product memory workspace.
/// Zero cloud, zero authentication, zero account overhead.
class TrimWorkspaceScreen extends StatefulWidget {
  const TrimWorkspaceScreen({super.key});

  @override
  State<TrimWorkspaceScreen> createState() => _TrimWorkspaceScreenState();
}

class _TrimWorkspaceScreenState extends State<TrimWorkspaceScreen> {
  final TrimSessionRepository _repository = TrimSessionRepository.instance;
  List<TrimSession> _sessions = [];
  TrimWorkspaceStats _stats = const TrimWorkspaceStats(
    ideasTrimmed: 0,
    featuresCut: 0,
    avgScopeRemovedPercent: 0,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    final sessions = await _repository.getAllSessions();
    final stats = await _repository.getWorkspaceStats();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _openSession(TrimSession session) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrimResultsScreen(
          session: session,
          isFromHistory: true,
        ),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
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

    // Refresh after returning in case lock state changed
    if (mounted) {
      _loadWorkspaceData();
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1 && dt.day == now.day) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute';
    } else if (difference.inDays < 2) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Yesterday, $hour:$minute';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
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
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFFD4D4D8),
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7.0,
                            height: 7.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(width: 7.0),
                          Text(
                            'Trim',
                            style: GoogleFonts.manrope(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 44), // Visual balance for back button
                    ],
                  ),
                ),

                // Workspace Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.orange,
                          ),
                        )
                      : _sessions.isEmpty
                          ? _buildEmptyState()
                          : _buildWorkspaceList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section 28: Empty Workspace State
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF101015),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF24242A), width: 0.8),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color: AppColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            'YOUR WORKSPACE',
            style: AppTypography.monoHeader.copyWith(
              fontSize: 12.0,
              letterSpacing: 1.2,
              color: const Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'No decisions yet.',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Trim your first idea to start building your product memory.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14.0,
              color: const Color(0xFF71717A),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            width: 220,
            child: SpringButton(
              label: 'TRIM AN IDEA',
              icon: Icons.add_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// Populated Workspace List (Sections 25 & 27)
  Widget _buildWorkspaceList() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title: "YOUR WORKSPACE"
          Text(
            'YOUR WORKSPACE',
            style: AppTypography.monoHeader.copyWith(
              fontSize: 11.0,
              letterSpacing: 1.2,
              color: const Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 14.0),

          // Dynamic Stats Telemetry Grid (Section 25)
          TrimGlassSurface(
            intensity: TrimGlassIntensity.low,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  value: '${_stats.ideasTrimmed}',
                  label: 'IDEAS TRIMMED',
                  accentColor: Colors.white,
                ),
                Container(
                  width: 1.0,
                  height: 36.0,
                  color: const Color(0xFF24242A),
                ),
                _buildStatItem(
                  value: '${_stats.featuresCut}',
                  label: 'FEATURES CUT',
                  accentColor: const Color(0xFFF87171),
                ),
                Container(
                  width: 1.0,
                  height: 36.0,
                  color: const Color(0xFF24242A),
                ),
                _buildStatItem(
                  value: '${_stats.avgScopeRemovedPercent}%',
                  label: 'AVG SCOPE REMOVED',
                  accentColor: AppColors.emerald,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28.0),

          // RECENT TRIMS Header
          Row(
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
                'RECENT TRIMS',
                style: AppTypography.monoHeader.copyWith(
                  color: const Color(0xFFE4E4E7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_sessions.length})',
                style: AppTypography.monoCounter,
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Saved Session Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10.0),
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return _buildSessionCard(session);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color accentColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 22.0,
            fontWeight: FontWeight.w800,
            color: accentColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: AppTypography.monoLabel.copyWith(
            fontSize: 9.0,
            letterSpacing: 0.6,
            color: const Color(0xFFA1A1AA),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(TrimSession session) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSession(session),
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D11),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: session.isLocked
                    ? AppColors.emerald.withValues(alpha: 0.3)
                    : const Color(0xFF24242A),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (session.isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: AppColors.emerald.withValues(alpha: 0.4),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 10,
                                    color: AppColors.emerald,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LOCKED',
                                    style: AppTypography.monoChip.copyWith(
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          // Scope reduction: 18 → 3
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14141A),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              session.totalFeatureCount > session.survivorCount
                                  ? '${session.totalFeatureCount} → ${session.survivorCount}'
                                  : '${session.totalFeatureCount} FOCUSED',
                              style: AppTypography.monoLabel.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(session.createdAt),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF52525B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
