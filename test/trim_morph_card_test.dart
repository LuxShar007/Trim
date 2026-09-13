import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trim/widgets/trim_chevron.dart';
import 'package:trim/widgets/trim_glass_button.dart';
import 'package:trim/widgets/trim_morph_card.dart';
import 'package:trim/widgets/trim_scope_metric.dart';

void main() {
  group('TrimMorphCard Interaction & Expansion Tests', () {
    testWidgets('TrimMorphCard renders in COLLAPSED state with title, badge and chevron', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimMorphCard(
              text: '3D Metaverse Virtual Gym',
              reason: 'A 3D gym is a visual distraction that does not affect workouts.',
              isPass: false,
            ),
          ),
        ),
      );

      // Title & CUT badge are visible
      expect(find.text('3D Metaverse Virtual Gym'), findsOneWidget);
      expect(find.text('CUT'), findsOneWidget);
      expect(find.byType(TrimChevron), findsOneWidget);

      // Reason is collapsed (not visible)
      expect(find.text('WHY CUT?'), findsNothing);
    });

    testWidgets('Tapping CUT card expands anchored card to reveal WHY CUT? reason', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimMorphCard(
              text: '3D Metaverse Virtual Gym',
              reason: 'A 3D gym is a visual layer that does not affect workout logging.',
              isPass: false,
            ),
          ),
        ),
      );

      // Initially collapsed
      expect(find.text('WHY CUT?'), findsNothing);

      // Tap card to initiate anchored expansion
      await tester.tap(find.text('3D Metaverse Virtual Gym'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 150)); // Mid-expansion
      await tester.pumpAndSettle(); // Settled in expanded state

      // Now expanded: WHY CUT label and explanation text are present
      expect(find.text('WHY CUT?'), findsOneWidget);
      expect(
        find.text('A 3D gym is a visual layer that does not affect workout logging.'),
        findsOneWidget,
      );

      // Tap again to collapse
      await tester.tap(find.text('3D Metaverse Virtual Gym'));
      await tester.pumpAndSettle();

      // Reason is hidden again
      expect(find.text('WHY CUT?'), findsNothing);
    });

    testWidgets('Tapping Core / PASS card reveals WHY KEEP? reason', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimMorphCard(
              text: 'Workout Logging Engine',
              reason: 'Core input mechanism essential for tracking progress.',
              isPass: true,
            ),
          ),
        ),
      );

      expect(find.text('PASS'), findsOneWidget);
      expect(find.text('WHY KEEP?'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Workout Logging Engine'));
      await tester.pumpAndSettle();

      expect(find.text('WHY KEEP?'), findsOneWidget);
      expect(find.text('Core input mechanism essential for tracking progress.'), findsOneWidget);
    });

    testWidgets('TrimMorphCard without reason does not show chevron and does not expand', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimMorphCard(
              text: 'Simple Core Item',
              reason: null,
              isPass: true,
            ),
          ),
        ),
      );

      expect(find.byType(TrimChevron), findsNothing);
      await tester.tap(find.text('Simple Core Item'));
      await tester.pumpAndSettle();
      expect(find.text('WHY KEEP?'), findsNothing);
    });
  });

  group('TrimGlassButton State Morphing Tests', () {
    testWidgets('TrimGlassButton renders idle, loading, and success states', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TrimGlassButton(
                  label: 'Export Spec',
                  icon: Icons.ios_share_rounded,
                  onTap: () => tapped = true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Export Spec'), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);

      await tester.tap(find.text('Export Spec'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Test loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimGlassButton(
              label: 'Export Spec',
              morphState: TrimButtonMorphState.loading,
              loadingLabel: 'Exporting...',
              onTap: null,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Exporting...'), findsOneWidget);

      // Test success state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimGlassButton(
              label: 'Export Spec',
              morphState: TrimButtonMorphState.success,
              successLabel: 'Exported ✓',
              onTap: null,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Exported ✓'), findsOneWidget);
    });
  });

  group('TrimScopeMetric Component Tests', () {
    testWidgets('TrimScopeMetric dynamically renders total and survivor counts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimScopeMetric(
              totalFeatures: 12,
              survivorsCount: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('SURVIVE'), findsOneWidget);

      // Test zero noise state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrimScopeMetric(
              totalFeatures: 4,
              survivorsCount: 4,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4 FEATURES'), findsOneWidget);
      expect(find.text('FULLY FOCUSED'), findsOneWidget);
    });
  });

  group('Responsive & Viewport Stress Tests (360dp, 390dp, 412dp, 430dp)', () {
    for (final width in [360.0, 390.0, 412.0, 430.0]) {
      testWidgets('Renders properly without overflow at ${width.toInt()}dp width', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width * 2.0, 840.0 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const TrimScopeMetric(totalFeatures: 15, survivorsCount: 2),
                      const SizedBox(height: 12),
                      const TrimMorphCard(
                        text: 'An extremely long feature name that tests natural text wrapping across multiple lines without overflowing the card container',
                        reason: 'A lengthy explanation detailing why this complex feature introduces excessive maintenance overhead, bloats the core user onboarding experience, and does not align with the MVP core value proposition.',
                        isPass: false,
                        initiallyExpanded: true,
                      ),
                      const SizedBox(height: 8),
                      // 10+ noise cards stress test
                      ...List.generate(
                        10,
                        (i) => TrimMorphCard(
                          text: 'Bloated Feature #$i with extra descriptors',
                          reason: 'Noise item $i explanation',
                          isPass: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      });
    }
  });
}
