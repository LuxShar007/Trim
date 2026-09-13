import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/score_ring.dart';
import '../widgets/section_header.dart';
import '../widgets/spring_button.dart';
import '../widgets/trim_glass_button.dart';
import '../widgets/trim_morph_card.dart';
import '../widgets/verdict_chip.dart';
import 'brain_dump_screen.dart';

/// Internal Design System Showcase Screen for TRIM.
/// Allows verifying visual consistency, typography hierarchy, and tactile spring motion.
class DesignShowcaseScreen extends StatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  State<DesignShowcaseScreen> createState() => _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends State<DesignShowcaseScreen> {
  double _scoreValue = 72.0;
  bool _buttonInteractive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIM DESIGN SYSTEM',
                      style: AppTypography.monoHeader.copyWith(
                        fontSize: 13.5,
                        color: AppColors.orange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Internal Component Showcase',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const BrainDumpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    'Open App',
                    style: AppTypography.monoChip.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 1. Color Palette Tokens
            Text('1. COLOR PALETTE', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _colorChip('Canvas', AppColors.canvas),
                _colorChip('Surface', AppColors.surfaceSubtle),
                _colorChip('Emerald (Pass)', AppColors.emerald),
                _colorChip('Orange (Energy)', AppColors.orange),
                _colorChip('Noise (#333)', AppColors.noiseGray),
                _colorChip('Cut Red', AppColors.cutRed),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 2. Verdict Chips
            Text('2. VERDICT CHIPS', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                VerdictChip(type: VerdictType.pass),
                SizedBox(width: 12),
                VerdictChip(type: VerdictType.cut),
                SizedBox(width: 12),
                VerdictChip(type: VerdictType.bloat),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 3. Score & Metric Component
            Text('3. SCORE & METRIC COMPONENT', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ScoreRing(
                percentage: _scoreValue,
                label: 'FAT TRIMMED (MVP DENSITY)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Slider(
              value: _scoreValue,
              min: 10.0,
              max: 95.0,
              activeColor: AppColors.emerald,
              inactiveColor: AppColors.surfaceElevated,
              onChanged: (val) => setState(() => _scoreValue = val),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 4. Section Headers
            Text('4. SECTION HEADERS', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.sm),
            const SectionHeader(
              title: 'The Core',
              count: 3,
              accentColor: AppColors.emerald,
              countLabel: 'Must-Haves',
            ),
            const SectionHeader(
              title: 'The Noise',
              count: 6,
              accentColor: AppColors.mutedText,
              countLabel: 'Discarded',
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 5. Feature Cards & TrimMorphCard
            Text('5. REUSABLE FEATURE CARDS & LIQUID MORPH', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.sm),
            const TrimMorphCard(
              text: 'Zero-latency QR payment invoice generation',
              reason: 'Core payment initiation loop essential for checkout flow.',
              isPass: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            const TrimMorphCard(
              text: 'In-app NFT avatar store & crypto staking feeds',
              reason: 'Speculative gamification bloat that adds high complexity without improving payment speed.',
              isPass: false,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 6. Tactile Spring Buttons
            Text('6. TACTILE SPRING BUTTONS & GLASS BUTTONS', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Checkbox(
                  value: _buttonInteractive,
                  activeColor: AppColors.orange,
                  onChanged: (v) => setState(() => _buttonInteractive = v ?? true),
                ),
                Text('Enable Button State', style: AppTypography.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SpringButton(
              label: 'Trim the Fat',
              icon: Icons.content_cut_rounded,
              isEnabled: _buttonInteractive,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Spring button pressed with tactile feedback!'),
                    backgroundColor: AppColors.orange,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TrimGlassButton(
              label: 'Export Spec to Markdown',
              icon: Icons.ios_share_rounded,
              variant: TrimButtonVariant.glass,
              isEnabled: _buttonInteractive,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 7. Glass Card
            Text('7. RESTRAINED GLASS CARD', style: AppTypography.monoLabel),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brutal Truth Quote Container', style: AppTypography.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '"Nobody wants a social feed inside their expense manager; users want to settle bills and leave."',
                    style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderHighlight, width: 0.8),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.computeLuminance() > 0.4 ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
