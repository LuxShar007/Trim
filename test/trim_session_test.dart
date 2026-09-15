import 'package:flutter_test/flutter_test.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/models/trim_session.dart';

void main() {
  group('TrimSession Domain & Serialization Tests', () {
    const sampleResult = TrimResult(
      projectName: 'StudySnap',
      coreValue: 'Snap any textbook equation to get instant visual steps.',
      mvpScore: 92,
      mustHaves: [
        MustHave(feature: 'Camera equation OCR', reason: 'Critical input path'),
        MustHave(feature: 'Step-by-step solver', reason: 'Core value promise'),
        MustHave(feature: 'Offline equation caching', reason: 'High reliability in classrooms'),
      ],
      discardedBloat: [
        DiscardedFeature(feature: 'Crypto study rewards', reason: 'Complete noise'),
        DiscardedFeature(feature: 'Social discussion forum', reason: 'Dilutes focus'),
      ],
      buildOrder: [
        '01 Camera equation OCR',
        '02 Step-by-step solver',
        '03 Offline equation caching',
      ],
      harshTruth: 'Students just want the math steps solved, not another chat app.',
    );

    test('creates TrimSession from TrimResult with accurate metrics', () {
      final session = TrimSession.fromTrimResult(
        originalIdea: 'An app to solve math with crypto coins',
        result: sampleResult,
        isLocked: false,
      );

      expect(session.projectName, equals('StudySnap'));
      expect(session.totalFeatureCount, equals(5));
      expect(session.survivorCount, equals(3));
      expect(session.cutCount, equals(2));
      expect(session.percentRemoved, equals(40)); // 2/5 * 100
      expect(session.isLocked, isFalse);
    });

    test('serializes to JSON and reconstructs identically', () {
      final original = TrimSession.fromTrimResult(
        originalIdea: 'Raw prompt text',
        result: sampleResult,
        isLocked: true,
      );

      final jsonMap = original.toJson();
      final restored = TrimSession.fromJson(jsonMap);

      expect(restored.id, equals(original.id));
      expect(restored.projectName, equals('StudySnap'));
      expect(restored.coreValue, equals(original.coreValue));
      expect(restored.mustHaves.length, equals(3));
      expect(restored.discardedBloat.length, equals(2));
      expect(restored.buildOrder.length, equals(3));
      expect(restored.harshTruth, equals(original.harshTruth));
      expect(restored.totalFeatureCount, equals(5));
      expect(restored.survivorCount, equals(3));
      expect(restored.cutCount, equals(2));
      expect(restored.isLocked, isTrue);
    });

    test('converts to TrimResult for offline verdict reopening', () {
      final session = TrimSession.fromTrimResult(
        originalIdea: 'Raw prompt text',
        result: sampleResult,
        isLocked: true,
      );

      final result = session.toTrimResult();

      expect(result.projectName, equals('StudySnap'));
      expect(result.coreValue, equals(sampleResult.coreValue));
      expect(result.mustHaves.length, equals(3));
      expect(result.discardedBloat.length, equals(2));
      expect(result.buildOrder, equals(sampleResult.buildOrder));
      expect(result.harshTruth, equals(sampleResult.harshTruth));
    });

    test('generates Section 24 compliant markdown with locked status and scope reduction', () {
      final session = TrimSession.fromTrimResult(
        originalIdea: 'Test prompt',
        result: sampleResult,
        isLocked: true,
      );

      final md = session.toMarkdown();

      expect(md, contains('# TRIMMED MVP'));
      expect(md, contains('StudySnap'));
      expect(md, contains('Snap any textbook equation'));
      expect(md, contains('## Must-Haves'));
      expect(md, contains('1. **Camera equation OCR**'));
      expect(md, contains('## Discarded Bloat'));
      expect(md, contains('- ~~Crypto study rewards~~: _Complete noise_'));
      expect(md, contains('## Build First'));
      expect(md, contains('1. 01 Camera equation OCR'));
      expect(md, contains('## Product Truth'));
      expect(md, contains('Students just want the math steps solved'));
      expect(md, contains('## Scope'));
      expect(md, contains('5 → 3 SURVIVE'));
      expect(md, contains('40% SCOPE REMOVED'));
      expect(md, contains('MVP LOCKED'));
    });
  });
}
