import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/models/trim_session.dart';
import 'package:trim/screens/trim_results_screen.dart';
import 'package:trim/screens/trim_workspace_screen.dart';
import 'package:trim/services/trim_session_repository.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> testBox;

  const sampleResultLongNoise = TrimResult(
    projectName: 'SuperBloatApp',
    coreValue: 'Just the core feature',
    mvpScore: 82,
    mustHaves: [
      MustHave(feature: 'Core Search', reason: 'Primary utility'),
    ],
    discardedBloat: [
      DiscardedFeature(feature: 'Cut 1', reason: 'Bloat 1'),
      DiscardedFeature(feature: 'Cut 2', reason: 'Bloat 2'),
      DiscardedFeature(feature: 'Cut 3', reason: 'Bloat 3'),
      DiscardedFeature(feature: 'Cut 4', reason: 'Bloat 4'),
      DiscardedFeature(feature: 'Cut 5', reason: 'Bloat 5'),
      DiscardedFeature(feature: 'Cut 6', reason: 'Bloat 6'),
      DiscardedFeature(feature: 'Cut 7', reason: 'Bloat 7'),
    ],
    buildOrder: ['01 Core Search'],
    harshTruth: 'Simplicity always wins.',
  );

  // 1 & 2. Initialize Hive once and open box once for test environment
  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('trim_flow_test_');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox(TrimSessionRepository.boxName);
    // 3. Inject that same test box into repository singleton
    TrimSessionRepository.instance.setTestBox(testBox);
  });

  // 5. Ensure tearDown properly closes/disposes the test box
  tearDownAll(() async {
    TrimSessionRepository.instance.setTestBox(null);
    await testBox.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await testBox.deleteAll(testBox.keys.toList());
  });

  group('Workspace & Verdict Interaction Flows', () {
    testWidgets('TrimWorkspaceScreen renders Section 28 empty state when no sessions exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrimWorkspaceScreen(),
        ),
      );
      // Pump to let async _loadWorkspaceData resolve and replace loading indicator
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('YOUR WORKSPACE'), findsWidgets);
      expect(find.text('No decisions yet.'), findsOneWidget);
      expect(find.text('Trim your first idea to start building your product memory.'), findsOneWidget);
      expect(find.text('TRIM AN IDEA'), findsOneWidget);
    });

    testWidgets('TrimWorkspaceScreen renders telemetry and session card when populated', (WidgetTester tester) async {
      final session = TrimSession.fromTrimResult(
        id: 'ws_test_1',
        originalIdea: 'Idea 1',
        result: sampleResultLongNoise,
        isLocked: true,
      );
      await tester.runAsync(() async {
        await testBox.put(session.id, session.toJson());
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TrimWorkspaceScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify telemetry stats
      expect(find.text('IDEAS TRIMMED'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('FEATURES CUT'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      // Verify session row
      expect(find.text('SuperBloatApp'), findsOneWidget);
      expect(find.text('8 → 1'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
    });

    testWidgets('Section 15: Progressive Noise Disclosure shows 4 items initially and expands on tap', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TrimResultsScreen(
              result: sampleResultLongNoise,
            ),
          ),
        );
      });
      await tester.pumpAndSettle();

      // Initially first 4 are visible
      expect(find.text('Cut 1'), findsOneWidget);
      expect(find.text('Cut 2'), findsOneWidget);
      expect(find.text('Cut 3'), findsOneWidget);
      expect(find.text('Cut 4'), findsOneWidget);

      // Items 5, 6, 7 are hidden
      expect(find.text('Cut 5'), findsNothing);
      expect(find.text('Cut 6'), findsNothing);
      expect(find.text('Cut 7'), findsNothing);

      // + 3 MORE CUT button is present
      final moreCutFinder = find.text('+ 3 MORE CUT');
      expect(moreCutFinder, findsOneWidget);

      // Tap + 3 MORE CUT
      await tester.ensureVisible(moreCutFinder);
      await tester.tap(moreCutFinder);
      await tester.pumpAndSettle();

      // Now all items are visible
      expect(find.text('Cut 5'), findsOneWidget);
      expect(find.text('Cut 6'), findsOneWidget);
      expect(find.text('Cut 7'), findsOneWidget);

      // The disclosure button is gone
      expect(find.text('+ 3 MORE CUT'), findsNothing);
    });

    testWidgets('Sections 29-31: Lock MVP confirmation flow and reopen toggle', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TrimResultsScreen(
              result: sampleResultLongNoise,
            ),
          ),
        );
      });
      await tester.pumpAndSettle();

      // Initial unlocked state
      final lockButton = find.widgetWithText(OutlinedButton, 'LOCK MVP');
      expect(lockButton, findsOneWidget);

      // Tap LOCK MVP to trigger confirmation
      await tester.ensureVisible(lockButton);
      await tester.tap(lockButton);
      await tester.pumpAndSettle();

      // Restrained glass confirmation surface appears
      expect(find.text('1 capabilities committed\n7 features rejected'), findsOneWidget);
      expect(find.text('Build this version first.'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Confirm LOCK MVP
      final confirmButton = find.widgetWithText(ElevatedButton, 'LOCK MVP');
      expect(confirmButton, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(confirmButton);
      });
      await tester.pumpAndSettle();

      // Verified LOCKED state
      expect(find.text('MVP LOCKED'), findsWidgets);
      expect(find.text('REOPEN MVP'), findsOneWidget);

      // Reopen MVP
      await tester.runAsync(() async {
        await tester.tap(find.text('REOPEN MVP'));
      });
      await tester.pumpAndSettle();

      // Returned to unlocked
      expect(find.widgetWithText(OutlinedButton, 'LOCK MVP'), findsOneWidget);
    });
  });
}
