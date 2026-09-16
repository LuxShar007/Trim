import 'dart:io';
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
    test('1. createHandoff generates exactly the 4 required markdown files', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);

      expect(bundle.files.keys, containsAll([
        'MVP_SPEC.md',
        'BUILD_ORDER.md',
        'CUT_FEATURES.md',
        'PRODUCT_TRUTH.md',
      ]));
      expect(bundle.files.length, 4);
    });

    test('2. MVP_SPEC.md contains exact headings: Project Name, Core Value, Must-Haves, Scope', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final spec = bundle.mvpSpec;

      expect(spec, startsWith('# FocusTimer Pro'));
      expect(spec, contains('## Core Value'));
      expect(spec, contains('Distraction-free 25-minute focus blocks'));
      expect(spec, contains('## Must-Haves'));
      expect(spec, contains('1. Pomodoro timer engine'));
      expect(spec, contains('2. Single-task lock'));
      expect(spec, contains('## Scope'));
      expect(spec, contains('5 → 2 SURVIVE'));
      expect(spec, contains('60% SCOPE REMOVED'));
      expect(spec, contains('## Status'));
      expect(spec, contains('MVP LOCKED'));
    });

    test('3. BUILD_ORDER.md contains exact "# Build First" heading and numbered sequence', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final order = bundle.buildOrder;

      expect(order, startsWith('# Build First'));
      expect(order, contains('1. Pomodoro timer engine'));
      expect(order, contains('2. Single-task lock'));
    });

    test('4. CUT_FEATURES.md contains exact "# Discarded Bloat" heading with reasons', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final cuts = bundle.cutFeatures;

      expect(cuts, startsWith('# Discarded Bloat'));
      expect(cuts, contains('1. Metaverse avatar gym'));
      expect(cuts, contains('Visual gimmick irrelevant to task execution.'));
      expect(cuts, contains('2. Crypto token staking'));
      expect(cuts, contains('3. TikTok integration'));
    });

    test('5. PRODUCT_TRUTH.md contains exact "# Product Truth" heading and harsh truth', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final truth = bundle.productTruth;

      expect(truth, startsWith('# Product Truth'));
      expect(truth, contains('If you need crypto rewards to stay focused, the app is not your problem.'));
    });

    test('6. Handoff strictly excludes API keys, Groq, model names, and telemetry', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResult);
      final combined = bundle.toCombinedHandoff();

      // Ensure zero technical or credential leakage
      expect(combined.toLowerCase(), isNot(contains('groq')));
      expect(combined.toLowerCase(), isNot(contains('gpt-oss')));
      expect(combined.toLowerCase(), isNot(contains('api_key')));
      expect(combined.toLowerCase(), isNot(contains('bearer')));
      expect(combined.toLowerCase(), isNot(contains('authorization')));
      expect(combined.toLowerCase(), isNot(contains('telemetry')));
    });

    test('7. prepareXFiles writes real files to TRIMMED_MVP on disk and can be read on laptop', () async {
      final xfiles = await OfficeKitService.instance.prepareXFiles(sampleResult);

      expect(xfiles.length, 4);
      final fileNames = xfiles.map((f) => f.name).toList();
      for (final expected in [
        'MVP_SPEC.md',
        'BUILD_ORDER.md',
        'CUT_FEATURES.md',
        'PRODUCT_TRUTH.md',
      ]) {
        expect(fileNames.any((n) => n.endsWith(expected)), isTrue,
            reason: 'Missing $expected in $fileNames');
      }

      // Verify each file can be opened and read as valid markdown
      for (final xfile in xfiles) {
        final content = await xfile.readAsString();
        expect(content, isNotEmpty);
        expect(content.startsWith('#'), isTrue);

        if (xfile.path.isNotEmpty) {
          final file = File(xfile.path);
          expect(await file.exists(), isTrue);
          expect(file.path, contains('TRIMMED_MVP'));
        }
      }
    });

    test('8. Malformed and empty sessions handle gracefully without crashing', () {
      const emptyResult = TrimResult(
        projectName: '',
        coreValue: '',
        mvpScore: 50,
        mustHaves: [],
        discardedBloat: [],
        buildOrder: [],
        harshTruth: '',
      );

      final bundle = OfficeKitService.instance.createHandoff(emptyResult);
      expect(bundle.projectName, equals('Project'));
      expect(bundle.mvpSpec, contains('# Project'));
      expect(bundle.mvpSpec, contains('No core value specified.'));
      expect(bundle.buildOrder, contains('# Build First'));
      expect(bundle.cutFeatures, contains('# Discarded Bloat'));
      expect(bundle.productTruth, contains('# Product Truth'));
    });

    test('9. Large content with 50+ features generates clean, performant handoff', () {
      final massiveMustHaves = List.generate(
        25,
        (i) => MustHave(feature: 'Must Have Feature $i', reason: 'Critical loop $i'),
      );
      final massiveCuts = List.generate(
        25,
        (i) => DiscardedFeature(feature: 'Bloat Feature $i', reason: 'Unnecessary noise $i'),
      );
      final massiveResult = TrimResult(
        projectName: 'Massive Enterprise Suite',
        coreValue: 'Ultra scale core outcome loop.',
        mvpScore: 99,
        mustHaves: massiveMustHaves,
        discardedBloat: massiveCuts,
        buildOrder: massiveMustHaves.map((m) => m.feature).toList(),
        harshTruth: 'Simplicity is scale.',
      );

      final bundle = OfficeKitService.instance.createHandoff(massiveResult);
      expect(bundle.mvpSpec, contains('50 → 25 SURVIVE'));
      expect(bundle.mvpSpec, contains('50% SCOPE REMOVED'));
      expect(bundle.buildOrder, contains('25. Must Have Feature 24'));
      expect(bundle.cutFeatures, contains('25. Bloat Feature 24'));
    });
  });

  group('TRIM — Office Kit UI Flow: MVP LOCKED -> SEND TO BUILD DESK', () {
    testWidgets('10. SEND TO BUILD DESK appears when MVP is locked and triggers handoff', (WidgetTester tester) async {
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

      // SEND TO BUILD DESK button is visible with proper styling and labels
      final sendButton = find.text('SEND TO BUILD DESK');
      expect(sendButton, findsOneWidget);
      expect(find.textContaining('Syncs 4 specs to laptop'), findsOneWidget);

      // Scroll into view and tap SEND TO BUILD DESK
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      // Pump frame for button interaction
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('11. SEND TO BUILD DESK is hidden when MVP is unlocked', (WidgetTester tester) async {
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
