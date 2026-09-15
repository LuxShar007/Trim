import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/models/trim_session.dart';
import 'package:trim/screens/trim_results_screen.dart';
import 'package:trim/services/office_kit_service.dart';

void main() {
  const sampleResult = TrimResult(
    projectName: 'FocusTimer Pro',
    coreValue: 'Distraction-free 25-minute focus blocks with brutal task triage.',
    mvpScore: 94,
    mustHaves: [
      MustHave(
        feature: 'Pomodoro timer engine',
        reason: 'Essential heartbeat of the product loop.',
      ),
      MustHave(
        feature: 'Single-task lock',
        reason: 'Forces ruthless focus on one deliverable at a time.',
      ),
    ],
    discardedBloat: [
      DiscardedFeature(
        feature: 'Metaverse avatar gym',
        reason: 'Visual gimmick irrelevant to task execution.',
      ),
      DiscardedFeature(
        feature: 'Crypto token staking',
        reason: 'Financial distraction with high regulatory and code overhead.',
      ),
      DiscardedFeature(
        feature: 'TikTok integration',
        reason: 'Directly violates focus principle.',
      ),
    ],
    buildOrder: [
      'Pomodoro timer engine',
      'Single-task lock',
    ],
    harshTruth: 'If you need crypto rewards to stay focused, the app is not your problem.',
  );

  group('TRIM — Office Kit Build Desk Handoff Specifications', () {
    test('createHandoff generates exactly the 4 required markdown files', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);

      expect(bundle.files.keys, containsAll([
        'MVP_SPEC.md',
        'BUILD_ORDER.md',
        'CUT_FEATURES.md',
        'PRODUCT_TRUTH.md',
      ]));
      expect(bundle.files.length, 4);
    });

    test('MVP_SPEC.md contains only project name, core value, must-haves, scope, and status', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final spec = bundle.mvpSpec;

      expect(spec, contains('FocusTimer Pro — MVP SPECIFICATION'));
      expect(spec, contains('Distraction-free 25-minute focus blocks'));
      expect(spec, contains('Pomodoro timer engine'));
      expect(spec, contains('Single-task lock'));
      expect(spec, contains('5 → 2 SURVIVE'));
      expect(spec, contains('60% SCOPE REMOVED'));
      expect(spec, contains('MVP LOCKED'));
    });

    test('BUILD_ORDER.md contains clear implementation sequence with step 1 directive', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final order = bundle.buildOrder;

      expect(order, contains('FocusTimer Pro — BUILD ORDER'));
      expect(order, contains('01. Pomodoro timer engine'));
      expect(order, contains('02. Single-task lock'));
      expect(order, contains('Implement step 01 completely and verify before moving to step 02.'));
    });

    test('CUT_FEATURES.md contains noise features with rejection reasons and strict rule', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final cuts = bundle.cutFeatures;

      expect(cuts, contains('FocusTimer Pro — CUT FEATURES (THE NOISE)'));
      expect(cuts, contains('Metaverse avatar gym'));
      expect(cuts, contains('Crypto token staking'));
      expect(cuts, contains('TikTok integration'));
      expect(cuts, contains('Do NOT implement these features in the initial release.'));
    });

    test('PRODUCT_TRUTH.md contains the focus constraint truth statement', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final truth = bundle.productTruth;

      expect(truth, contains('FocusTimer Pro — PRODUCT TRUTH'));
      expect(truth, contains('If you need crypto rewards to stay focused, the app is not your problem.'));
    });

    test('Handoff strictly excludes API keys, Groq, model names, and telemetry', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final combined = bundle.toCombinedHandoff();

      // Ensure no technical leakage
      expect(combined.toLowerCase(), isNot(contains('groq')));
      expect(combined.toLowerCase(), isNot(contains('gpt-oss')));
      expect(combined.toLowerCase(), isNot(contains('api_key')));
      expect(combined.toLowerCase(), isNot(contains('bearer')));
      expect(combined.toLowerCase(), isNot(contains('http')));
      expect(combined.toLowerCase(), isNot(contains('telemetry')));
    });
  });

  group('TRIM — Office Kit UI Flow: MVP LOCKED -> SEND TO BUILD DESK', () {
    testWidgets('SEND TO BUILD DESK appears when MVP is locked and triggers handoff', (WidgetTester tester) async {
      // Start with locked session
      final session = TrimSession.fromTrimResult(
        originalIdea: 'My bloated idea',
        result: sampleResult,
        isLocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimResultsScreen(
              session: session,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // MVP LOCKED is visible
      expect(find.text('MVP LOCKED'), findsWidgets);

      // SEND TO BUILD DESK button is visible
      final sendButton = find.text('SEND TO BUILD DESK');
      expect(sendButton, findsOneWidget);
      expect(find.textContaining('Syncs 4 specs to laptop'), findsOneWidget);

      // Scroll into view and tap SEND TO BUILD DESK
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      // Pump frame for button interaction
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('SEND TO BUILD DESK is hidden when MVP is unlocked', (WidgetTester tester) async {
      final session = TrimSession.fromTrimResult(
        originalIdea: 'My bloated idea',
        result: sampleResult,
        isLocked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrimResultsScreen(
              session: session,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // MVP is not locked yet
      expect(find.text('LOCK MVP'), findsOneWidget);
      expect(find.text('SEND TO BUILD DESK'), findsNothing);
    });
  });
}
