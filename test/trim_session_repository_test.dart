import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/models/trim_session.dart';
import 'package:trim/services/trim_session_repository.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> testBox;
  late TrimSessionRepository repository;

  const sampleResult1 = TrimResult(
    projectName: 'PlantSnap',
    coreValue: 'Instant leaf disease diagnosis',
    mvpScore: 90,
    mustHaves: [
      MustHave(feature: 'Leaf scanner', reason: 'Primary input'),
      MustHave(feature: 'Disease match', reason: 'Core value'),
    ],
    discardedBloat: [
      DiscardedFeature(feature: 'Plant marketplace', reason: 'Noise'),
      DiscardedFeature(feature: 'Florist chat', reason: 'Noise'),
      DiscardedFeature(feature: 'NFT badges', reason: 'Noise'),
    ],
    buildOrder: ['01 Leaf scanner', '02 Disease match'],
    harshTruth: 'Gardeners want treatment solutions, not digital collectibles.',
  );

  const sampleResult2 = TrimResult(
    projectName: 'ShopMate',
    coreValue: 'Minimal grocery shopping checklist',
    mvpScore: 95,
    mustHaves: [
      MustHave(feature: 'Aisle sorted list', reason: 'Speed'),
    ],
    discardedBloat: [
      DiscardedFeature(feature: 'Social coupon feed', reason: 'Bloat'),
    ],
    buildOrder: ['01 Aisle list'],
    harshTruth: 'Get in and out of the grocery store faster.',
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('trim_repo_test_');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox('test_sessions_${DateTime.now().microsecondsSinceEpoch}');
    repository = TrimSessionRepository(box: testBox);
  });

  tearDown(() async {
    await testBox.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('TrimSessionRepository Persistence & Ordering Tests', () {
    test('saves and retrieves sessions', () async {
      final session = TrimSession.fromTrimResult(
        id: 'session_1',
        originalIdea: 'Idea 1',
        result: sampleResult1,
        isLocked: false,
      );

      await repository.saveSession(session);

      final retrieved = await repository.getSession('session_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.projectName, equals('PlantSnap'));
      expect(retrieved.isLocked, isFalse);
    });

    test('returns sessions sorted in reverse chronological order (newest first)', () async {
      final sessionOld = TrimSession.fromTrimResult(
        id: 'old_session',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        originalIdea: 'Old idea',
        result: sampleResult1,
      );

      final sessionNew = TrimSession.fromTrimResult(
        id: 'new_session',
        createdAt: DateTime.now(),
        originalIdea: 'New idea',
        result: sampleResult2,
      );

      await repository.saveSession(sessionOld);
      await repository.saveSession(sessionNew);

      final all = await repository.getAllSessions();
      expect(all.length, equals(2));
      expect(all.first.id, equals('new_session'));
      expect(all.last.id, equals('old_session'));
    });

    test('toggles and persists locked status', () async {
      final session = TrimSession.fromTrimResult(
        id: 'lock_test',
        originalIdea: 'Idea to lock',
        result: sampleResult1,
        isLocked: false,
      );

      await repository.saveSession(session);
      expect((await repository.getSession('lock_test'))!.isLocked, isFalse);

      await repository.setLocked('lock_test', true);
      expect((await repository.getSession('lock_test'))!.isLocked, isTrue);

      await repository.setLocked('lock_test', false);
      expect((await repository.getSession('lock_test'))!.isLocked, isFalse);
    });

    test('dynamically calculates workspace statistics', () async {
      // Session 1: 2 must-haves, 3 discarded = 5 total, 3 cut
      final s1 = TrimSession.fromTrimResult(
        id: 's1',
        originalIdea: 'Idea 1',
        result: sampleResult1,
      );

      // Session 2: 1 must-have, 1 discarded = 2 total, 1 cut
      final s2 = TrimSession.fromTrimResult(
        id: 's2',
        originalIdea: 'Idea 2',
        result: sampleResult2,
      );

      await repository.saveSession(s1);
      await repository.saveSession(s2);

      final stats = await repository.getWorkspaceStats();
      expect(stats.ideasTrimmed, equals(2));
      expect(stats.featuresCut, equals(4)); // 3 + 1
      // Total features = 5 + 2 = 7. Cut = 4. 4 / 7 * 100 = 57%
      expect(stats.avgScopeRemovedPercent, equals(57));
    });

    test('returns zero stats when workspace has no saved sessions', () async {
      final stats = await repository.getWorkspaceStats();
      expect(stats.ideasTrimmed, equals(0));
      expect(stats.featuresCut, equals(0));
      expect(stats.avgScopeRemovedPercent, equals(0));
    });
  });
}
