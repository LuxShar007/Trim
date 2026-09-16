import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/models/trim_session.dart';
import 'package:trim/screens/trim_results_screen.dart';
import 'package:trim/screens/trim_workspace_screen.dart';
import 'package:trim/services/office_kit_service.dart';
import 'package:trim/services/trim_session_repository.dart';
import 'package:trim/widgets/build_desk_artifact_preview_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> testBox;
  late TrimSessionRepository repository;

  const sampleResultA = TrimResult(
    projectName: 'CampusConnect',
    coreValue: 'Hyper-local study group coordination for college courses.',
    mvpScore: 91,
    mustHaves: [
      MustHave(feature: 'Course study rooms', reason: 'Direct academic value'),
      MustHave(feature: 'Verified .edu roster', reason: 'Trust & safety'),
    ],
    discardedBloat: [
      DiscardedFeature(feature: 'Campus dating mode', reason: 'Dilutes academic focus'),
      DiscardedFeature(feature: 'Crypto token tipping', reason: 'High friction distraction'),
      DiscardedFeature(feature: 'Food delivery hub', reason: 'Out of scope bloat'),
    ],
    buildOrder: ['01 Course study rooms', '02 Verified roster'],
    harshTruth: 'Students want peer study partners, not another noisy social network.',
  );

  const sampleResultB = TrimResult(
    projectName: 'FitTrack',
    coreValue: 'Single-tap workout repetition logger.',
    mvpScore: 88,
    mustHaves: [
      MustHave(feature: 'Set/rep logger', reason: 'Core workout utility'),
    ],
    discardedBloat: [
      DiscardedFeature(feature: 'Influencer video feed', reason: 'Distraction during workout'),
    ],
    buildOrder: ['01 Set/rep logger'],
    harshTruth: 'Log your sets and lift; stop watching workout reels.',
  );

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('trim_artifacts_test_');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox(TrimSessionRepository.boxName);
    TrimSessionRepository.instance.setTestBox(testBox);
    repository = TrimSessionRepository.instance;
  });

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

  group('TRIM — Workspace Build Desk Artifacts Matrix', () {
    test('1. Artifact Generation produces exactly the 4 required Build Desk files', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);

      expect(bundle.files.length, 4);
      expect(bundle.files.containsKey('MVP_SPEC.md'), isTrue);
      expect(bundle.files.containsKey('BUILD_ORDER.md'), isTrue);
      expect(bundle.files.containsKey('CUT_FEATURES.md'), isTrue);
      expect(bundle.files.containsKey('PRODUCT_TRUTH.md'), isTrue);
    });

    test('2. Exact File Contents match specifications and contain no sensitive data', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);

      // MVP_SPEC.md
      expect(bundle.mvpSpec, contains('# CampusConnect'));
      expect(bundle.mvpSpec, contains('## Core Value'));
      expect(bundle.mvpSpec, contains('Course study rooms'));
      expect(bundle.mvpSpec, contains('## Scope'));
      expect(bundle.mvpSpec, contains('5 → 2 SURVIVE'));
      expect(bundle.mvpSpec, contains('60% SCOPE REMOVED'));

      // BUILD_ORDER.md
      expect(bundle.buildOrder, contains('# Build First'));
      expect(bundle.buildOrder, contains('01 Course study rooms'));

      // CUT_FEATURES.md
      expect(bundle.cutFeatures, contains('# Discarded Bloat'));
      expect(bundle.cutFeatures, contains('Campus dating mode'));
      expect(bundle.cutFeatures, contains('Dilutes academic focus'));

      // PRODUCT_TRUTH.md
      expect(bundle.productTruth, contains('# Product Truth'));
      expect(bundle.productTruth, contains(sampleResultA.harshTruth));

      // Security check: No API keys or LLM provider leak
      for (final content in bundle.files.values) {
        expect(content.toLowerCase(), isNot(contains('gsk_')));
        expect(content.toLowerCase(), isNot(contains('api_key')));
        expect(content.toLowerCase(), isNot(contains('groq')));
        expect(content.toLowerCase(), isNot(contains('llama')));
      }
    });

    test('3. TrimSession serialization preserves buildDeskArtifacts in JSON', () {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);
      final session = TrimSession.fromTrimResult(
        id: 'session-101',
        originalIdea: 'College app for students',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: bundle.files,
      );

      expect(session.hasBuildDeskArtifacts, isTrue);

      final json = session.toJson();
      expect(json['buildDeskArtifacts'], isNotNull);
      expect((json['buildDeskArtifacts'] as Map).length, 4);

      final reconstructed = TrimSession.fromJson(json);
      expect(reconstructed.hasBuildDeskArtifacts, isTrue);
      expect(reconstructed.buildDeskArtifacts!['MVP_SPEC.md'], equals(bundle.files['MVP_SPEC.md']));
      expect(reconstructed.buildDeskArtifacts!['BUILD_ORDER.md'], equals(bundle.files['BUILD_ORDER.md']));
    });

    test('4. Workspace Retrieval persists and recovers artifacts from repository', () async {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);
      final session = TrimSession.fromTrimResult(
        id: 'session-retrieval',
        originalIdea: 'Test idea',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: bundle.files,
      );

      await repository.saveSession(session);

      final retrieved = await repository.getSession('session-retrieval');
      expect(retrieved, isNotNull);
      expect(retrieved!.hasBuildDeskArtifacts, isTrue);
      expect(retrieved.buildDeskArtifacts!.length, 4);
      expect(retrieved.buildDeskArtifacts!['MVP_SPEC.md'], contains('# CampusConnect'));
    });

    test('5. App Restart Persistence recovers artifacts across fresh repository instance', () async {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);
      final session = TrimSession.fromTrimResult(
        id: 'restart-session',
        originalIdea: 'Test idea for restart',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: bundle.files,
      );

      await repository.saveSession(session);

      // Emulate app restart: create a new repository instance pointing to the same box
      final freshRepo = TrimSessionRepository(box: testBox);

      final recovered = await freshRepo.getSession('restart-session');
      expect(recovered, isNotNull);
      expect(recovered!.hasBuildDeskArtifacts, isTrue);
      expect(recovered.buildDeskArtifacts!['PRODUCT_TRUTH.md'], equals(bundle.files['PRODUCT_TRUTH.md']));
    });

    test('6. Session Isolation maintains independent artifacts for unrelated ideas', () async {
      final bundleA = OfficeKitService.instance.createHandoff(sampleResultA);
      final bundleB = OfficeKitService.instance.createHandoff(sampleResultB);

      final sessionA = TrimSession.fromTrimResult(
        id: 'session-A',
        originalIdea: 'Campus Connect Idea',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: bundleA.files,
      );

      final sessionB = TrimSession.fromTrimResult(
        id: 'session-B',
        originalIdea: 'FitTrack Idea',
        result: sampleResultB,
        isLocked: true,
        buildDeskArtifacts: bundleB.files,
      );

      await repository.saveSession(sessionA);
      await repository.saveSession(sessionB);

      final fetchA = await repository.getSession('session-A');
      final fetchB = await repository.getSession('session-B');

      expect(fetchA!.buildDeskArtifacts!['MVP_SPEC.md'], contains('# CampusConnect'));
      expect(fetchA.buildDeskArtifacts!['MVP_SPEC.md'], isNot(contains('FitTrack')));

      expect(fetchB!.buildDeskArtifacts!['MVP_SPEC.md'], contains('# FitTrack'));
      expect(fetchB.buildDeskArtifacts!['MVP_SPEC.md'], isNot(contains('CampusConnect')));
    });

    test('7. Legacy Session Behavior handles older sessions without artifacts', () async {
      // Legacy session without buildDeskArtifacts
      final legacySession = TrimSession.fromTrimResult(
        id: 'legacy-session-99',
        originalIdea: 'Legacy product idea',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: null,
      );

      await repository.saveSession(legacySession);

      final fetched = await repository.getSession('legacy-session-99');
      expect(fetched!.hasBuildDeskArtifacts, isFalse);
      expect(fetched.buildDeskArtifacts, isNull);

      // On explicit GENERATE BUILD FILES action:
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);
      await repository.saveArtifacts('legacy-session-99', bundle.files);

      final updated = await repository.getSession('legacy-session-99');
      expect(updated!.hasBuildDeskArtifacts, isTrue);
      expect(updated.buildDeskArtifacts!.length, 4);
    });

    test('8. Multi-File and Single-File Preparation generates valid XFiles', () async {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);

      // Multi-file
      final xfiles = await OfficeKitService.instance.prepareXFilesFromArtifacts(
        'test-session',
        bundle.files,
      );
      expect(xfiles.length, 4);
      for (final xf in xfiles) {
        expect(xf.mimeType, 'text/markdown');
        expect(xf.name.endsWith('.md'), isTrue);
      }

      // Single file
      final singleXFile = await OfficeKitService.instance.prepareSingleXFile(
        'test-session',
        'MVP_SPEC.md',
        bundle.mvpSpec,
      );
      expect(singleXFile.name.endsWith('MVP_SPEC.md'), isTrue);
      expect(singleXFile.mimeType, 'text/markdown');
    });

    testWidgets('9. Individual Preview Sheet renders filename, type, and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildDeskArtifactPreviewSheet(
              filename: 'MVP_SPEC.md',
              content: '# Test Project\n## Must Haves\n1. Core feature',
              sessionId: 'test-preview-id',
              projectName: 'Test Project',
            ),
          ),
        ),
      );

      expect(find.text('MVP_SPEC.md'), findsOneWidget);
      expect(find.text('MARKDOWN · .md'), findsOneWidget);
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.textContaining('# Test Project'), findsOneWidget);
    });

    testWidgets('10. Workspace List displays BUILD DESK · 4 FILES on sessions with artifacts', (tester) async {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);
      final sessionWithArtifacts = TrimSession.fromTrimResult(
        id: 'session-with-files',
        originalIdea: 'Session with files',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: bundle.files,
      );

      final sessionWithoutArtifacts = TrimSession.fromTrimResult(
        id: 'session-no-files',
        originalIdea: 'Session without files',
        result: sampleResultB,
        isLocked: false,
        buildDeskArtifacts: null,
      );

      await tester.runAsync(() async {
        await repository.saveSession(sessionWithArtifacts);
        await repository.saveSession(sessionWithoutArtifacts);
        await tester.pumpWidget(
          const MaterialApp(
            home: TrimWorkspaceScreen(),
          ),
        );
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CampusConnect'), findsOneWidget);
      expect(find.text('FitTrack'), findsOneWidget);
      expect(find.text('BUILD DESK · 4 FILES'), findsOneWidget);
    });

    testWidgets('11. TrimResultsScreen displays 4 artifact cards when session has artifacts', (tester) async {
      final bundle = OfficeKitService.instance.createHandoff(sampleResultA);
      final session = TrimSession.fromTrimResult(
        id: 'session-view-test',
        originalIdea: 'Session view idea',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: bundle.files,
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: TrimResultsScreen(
              session: session,
              isFromHistory: true,
            ),
          ),
        );
      });
      await tester.pumpAndSettle();

      expect(find.text('BUILD DESK'), findsOneWidget);
      expect(find.text('MVP_SPEC.md'), findsOneWidget);
      expect(find.text('BUILD_ORDER.md'), findsOneWidget);
      expect(find.text('CUT_FEATURES.md'), findsOneWidget);
      expect(find.text('PRODUCT_TRUTH.md'), findsOneWidget);
      expect(find.text('SHARE ALL BUILD FILES'), findsOneWidget);
    });

    testWidgets('12. TrimResultsScreen displays legacy banner and generates files on tap', (tester) async {
      final legacySession = TrimSession.fromTrimResult(
        id: 'legacy-screen-test',
        originalIdea: 'Legacy screen idea',
        result: sampleResultA,
        isLocked: true,
        buildDeskArtifacts: null,
      );

      await tester.runAsync(() async {
        await repository.saveSession(legacySession);
        await tester.pumpWidget(
          MaterialApp(
            home: TrimResultsScreen(
              session: legacySession,
              isFromHistory: true,
            ),
          ),
        );
      });
      await tester.pumpAndSettle();

      expect(find.text('BUILD DESK'), findsOneWidget);
      expect(find.text('Artifacts unavailable for this older session.'), findsOneWidget);
      expect(find.text('GENERATE BUILD FILES'), findsOneWidget);

      // Tap GENERATE BUILD FILES
      await tester.ensureVisible(find.text('GENERATE BUILD FILES'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('GENERATE BUILD FILES'));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should now show the 4 files and SHARE ALL BUILD FILES button
      expect(find.text('MVP_SPEC.md'), findsOneWidget);
      expect(find.text('BUILD_ORDER.md'), findsOneWidget);
      expect(find.text('CUT_FEATURES.md'), findsOneWidget);
      expect(find.text('PRODUCT_TRUTH.md'), findsOneWidget);
      expect(find.text('SHARE ALL BUILD FILES'), findsOneWidget);
    });
  });
}
