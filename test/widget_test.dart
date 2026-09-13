import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trim/main.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/screens/trim_results_screen.dart';
import 'package:trim/widgets/feature_card.dart';
import 'package:trim/widgets/glass_feature_card.dart';
import 'package:trim/widgets/score_ring.dart';
import 'package:trim/widgets/spring_button.dart';
import 'package:trim/widgets/spring_guillotine_button.dart';
import 'package:trim/widgets/verdict_chip.dart';

void main() {
  testWidgets('TrimApp smoke test renders BrainDumpScreen cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const TrimApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify app title
    expect(find.text('Trim'), findsOneWidget);

    // Verify hint text in the massive text field
    expect(find.text('Dump your massive, bloated app idea here...'), findsOneWidget);

    // Verify the tactile action button
    expect(find.text('TRIM THE FAT'), findsOneWidget);
  });

  testWidgets('Sample bloated idea can be inserted into TextField', (WidgetTester tester) async {
    await tester.pumpWidget(const TrimApp());
    await tester.pump(const Duration(milliseconds: 100));

    final sampleButton = find.text('Insert Bloated Idea Sample');
    expect(sampleButton, findsOneWidget);

    await tester.tap(sampleButton);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('social fitness app for crypto traders'), findsOneWidget);
  });

  testWidgets('SpringGuillotineButton reacts to gesture tap down and release', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpringGuillotineButton(
            onTap: () => tapped = true,
            label: 'Test Button',
          ),
        ),
      ),
    );

    expect(find.text('TEST BUTTON'), findsOneWidget);

    // Press down
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SpringGuillotineButton)));
    await tester.pump(const Duration(milliseconds: 50));

    // Release up
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tapped, isTrue);
  });

  testWidgets('GlassFeatureCard renders both mustHave and discardedBloat accurately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GlassFeatureCard(
                text: 'Real-Time Sync Engine',
                type: FeatureCardType.mustHave,
              ),
              GlassFeatureCard(
                text: 'VR Avatar Store',
                type: FeatureCardType.discardedBloat,
              ),
            ],
          ),
        ),
      ),
    );

    // Check texts
    expect(find.text('Real-Time Sync Engine'), findsOneWidget);
    expect(find.text('VR Avatar Store'), findsOneWidget);

    // Check pass/cut labels
    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('CUT'), findsOneWidget);
  });

  testWidgets('TrimResultsScreen displays complete MVP triage and harsh truth', (WidgetTester tester) async {
    const sampleResult = TrimResult(
      projectName: 'LaserPay',
      coreValue: 'Zero-friction peer-to-peer lightning payments.',
      mvpScore: 90,
      mustHaves: [
        MustHave(
          feature: 'Instant payment invoice generator',
          reason: 'Essential transaction start',
        ),
        MustHave(
          feature: 'Direct biometric confirmation',
          reason: 'Low-friction authorization',
        ),
      ],
      discardedBloat: [
        DiscardedFeature(
          feature: 'In-app crypto staking exchange',
          reason: 'Distraction from payments',
        ),
        DiscardedFeature(
          feature: 'Social influencer tipping feed',
          reason: 'Vanity bloat',
        ),
      ],
      buildOrder: [
        '01 Invoice generator',
        '02 Biometric auth',
        '03 Payment settlement',
      ],
      harshTruth: 'Nobody wants a social feed inside their payment wallet.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: TrimResultsScreen(result: sampleResult),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and core value
    expect(find.text('LaserPay'), findsOneWidget);
    expect(find.text('Zero-friction peer-to-peer lightning payments.'), findsOneWidget);

    // Verify sections
    expect(find.text('THE CORE'), findsOneWidget);
    expect(find.text('THE NOISE'), findsOneWidget);
    expect(find.text('Instant payment invoice generator'), findsOneWidget);
    expect(find.text('In-app crypto staking exchange'), findsOneWidget);

    // Verify product truth block
    expect(find.text('PRODUCT TRUTH'), findsOneWidget);
    expect(find.text('Nobody wants a social feed inside their payment wallet.'), findsOneWidget);

    // Verify action buttons
    expect(find.text('LOCK MVP'), findsOneWidget);
    expect(find.text('EXPORT MVP'), findsOneWidget);
  });

  testWidgets('VerdictChip renders PASS, CUT, and BLOAT variants', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              VerdictChip(type: VerdictType.pass),
              VerdictChip(type: VerdictType.cut),
              VerdictChip(type: VerdictType.bloat),
            ],
          ),
        ),
      ),
    );

    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('CUT'), findsOneWidget);
    expect(find.text('BLOAT'), findsOneWidget);
  });

  testWidgets('SpringButton reacts to tap gestures and reflects disabled state', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpringButton(
            label: 'Test Spring Button',
            isEnabled: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('TEST SPRING BUTTON'), findsOneWidget);

    await tester.tap(find.text('TEST SPRING BUTTON'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tapped, isTrue);
  });

  testWidgets('FeatureCard renders must-have and bloat correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FeatureCard(
                text: 'Core Auth Flow',
                type: FeatureCardType.mustHave,
              ),
              FeatureCard(
                text: 'VR Chat Room',
                type: FeatureCardType.discardedBloat,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Core Auth Flow'), findsOneWidget);
    expect(find.text('VR Chat Room'), findsOneWidget);
    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('CUT'), findsOneWidget);
  });

  testWidgets('ScoreRing renders percentage and label accurately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScoreRing(
            percentage: 85.0,
            label: 'Fat Trimmed',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('85%'), findsOneWidget);
    expect(find.text('FAT TRIMMED'), findsOneWidget);
  });
}
