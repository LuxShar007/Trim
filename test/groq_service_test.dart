import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/services/groq_service.dart';
import 'package:trim/services/trim_engine.dart';

void main() {
  group('TrimResult Model Tests', () {
    test('correctly parses valid Groq JSON payload', () {
      const sampleJson = '''
      {
        "project_name": "GhostList",
        "core_value": "Minimalist anonymous to-do list that auto-deletes in 24 hours.",
        "mvp_score": 85,
        "must_haves": [
          {"feature": "Local-only encrypted task store", "reason": "Privacy core"},
          {"feature": "24-hour expiration ticker", "reason": "Auto-deletion hook"},
          {"feature": "Single-tap task annihilation", "reason": "Fast completion"}
        ],
        "discarded_bloat": [
          {"feature": "Social leaderboards and friend sync", "reason": "Distracting noise"},
          {"feature": "AI habit prediction engine", "reason": "Premature complexity"},
          {"feature": "Team collaboration workspaces", "reason": "Violates private use-case"}
        ],
        "build_order": [
          "01 Local encrypted store",
          "02 Expiration ticker",
          "03 Single-tap deletion"
        ],
        "harsh_truth": "Nobody needs a social network for their private grocery list."
      }
      ''';

      final result = TrimResult.fromRawJson(sampleJson);

      expect(result.projectName, equals('GhostList'));
      expect(result.coreValue, contains('to-do list'));
      expect(result.mustHaves.length, equals(3));
      expect(result.discardedBloat.length, equals(3));
      expect(result.harshTruth, contains('grocery list'));
    });

    test('generates valid markdown representation for export', () {
      const result = TrimResult(
        projectName: 'TrimTest',
        coreValue: 'Test Core Value',
        mvpScore: 88,
        mustHaves: [
          MustHave(feature: 'Feature Alpha', reason: 'Core path'),
          MustHave(feature: 'Feature Beta', reason: 'User engagement'),
        ],
        discardedBloat: [
          DiscardedFeature(feature: 'Bloat Omega', reason: 'Redundant distraction'),
        ],
        buildOrder: [
          '01 Feature Alpha',
          '02 Feature Beta',
        ],
        harshTruth: 'Simplicity always wins.',
      );

      final markdown = result.toMarkdown();

      expect(markdown, contains('# TRIMMED MVP'));
      expect(markdown, contains('TrimTest'));
      expect(markdown, contains('Test Core Value'));
      expect(markdown, contains('## Must-Haves'));
      expect(markdown, contains('1. **Feature Alpha**'));
      expect(markdown, contains('## Discarded Bloat'));
      expect(markdown, contains('- ~~Bloat Omega~~: _Redundant distraction_'));
      expect(markdown, contains('## Build First'));
      expect(markdown, contains('## Product Truth'));
      expect(markdown, contains('Simplicity always wins.'));
      expect(markdown, contains('## Scope'));
      expect(markdown, contains('3 → 2 SURVIVE'));
    });

    test('correctly parses new rich schema with mvp_score, feature reasons, and build_order', () {
      const richJson = '''
      {
        "project_name": "HyperSplit",
        "core_value": "Zero friction split.",
        "mvp_score": 94,
        "must_haves": [
          {
            "feature": "QR connection",
            "reason": "Eliminates accounts"
          }
        ],
        "discarded_bloat": [
          {
            "feature": "Social chat",
            "reason": "Irrelevant bloat"
          }
        ],
        "build_order": [
          "01 Amount entry",
          "02 QR render",
          "03 Stripe trigger"
        ],
        "harsh_truth": "Nobody chats in a bill splitter."
      }
      ''';

      final result = TrimResult.fromRawJson(richJson);

      expect(result.projectName, equals('HyperSplit'));
      expect(result.mvpScore, equals(94));
      expect(result.mustHaves.first.feature, equals('QR connection'));
      expect(result.mustHaves.first.reason, equals('Eliminates accounts'));
      expect(result.discardedBloat.first.feature, equals('Social chat'));
      expect(result.discardedBloat.first.reason, equals('Irrelevant bloat'));
      expect(result.buildOrder.length, equals(3));
      expect(result.buildOrder.first, contains('01 Amount entry'));
    });

    test('throws TrimParseException when required fields fail validation', () {
      const invalidJson = '''
      {
        "project_name": null,
        "core_value": "",
        "mvp_score": "not-an-int",
        "must_haves": [],
        "discarded_bloat": null,
        "build_order": null,
        "harsh_truth": null
      }
      ''';

      expect(
        () => TrimResult.fromRawJson(invalidJson),
        throwsA(isA<TrimParseException>()),
      );
    });

    test('throws TrimParseException when must_have item is missing reason', () {
      const missingReasonJson = '''
      {
        "project_name": "TestApp",
        "core_value": "Core value statement.",
        "mvp_score": 80,
        "must_haves": [
          {"feature": "Only feature"}
        ],
        "discarded_bloat": [
          {"feature": "Bloat", "reason": "Reason"}
        ],
        "build_order": ["01 Step"],
        "harsh_truth": "Truth."
      }
      ''';

      expect(
        () => TrimResult.fromRawJson(missingReasonJson),
        throwsA(isA<TrimParseException>()),
      );
    });

    test('safely parses JSON wrapped in markdown code fences', () {
      const markdownJson = '''
      ```json
      {
        "project_name": "FencedApp",
        "core_value": "Fenced value",
        "mvp_score": 90,
        "must_haves": [{"feature": "Core", "reason": "Reason"}],
        "discarded_bloat": [{"feature": "Bloat", "reason": "Reason"}],
        "build_order": ["01 Build"],
        "harsh_truth": "No markdown fences in production."
      }
      ```
      ''';

      final result = TrimResult.fromRawJson(markdownJson);
      expect(result.projectName, equals('FencedApp'));
      expect(result.mustHaves.first.feature, equals('Core'));
    });
  });

  group('GroqService HTTP Client Tests', () {
    test('successful trim execution with mock client verifying request structure', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/trim'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['rawIdea'], equals('A massive bloated idea with 50 features'));

        final mockResponsePayload = {
          'project_name': 'RazorApp',
          'core_value': 'One feature done right.',
          'mvp_score': 91,
          'must_haves': [
            {'feature': 'Core Action', 'reason': 'Essential'}
          ],
          'discarded_bloat': [
            {'feature': 'Everything else', 'reason': 'Bloat'}
          ],
          'build_order': ['01 Core Action'],
          'harsh_truth': 'Bloat will kill your app before users do.',
        };

        return http.Response(json.encode(mockResponsePayload), 200);
      });

      final service = GroqService(client: mockClient);
      final result = await service.trimAppIdea(
        rawIdea: 'A massive bloated idea with 50 features',
      );

      expect(result.projectName, equals('RazorApp'));
      expect(result.mustHaves.first.feature, equals('Core Action'));
      expect(result.discardedBloat.first.feature, equals('Everything else'));
    });

    test('throws GroqBadRequestException on empty idea input', () async {
      final service = GroqService();
      expect(
        () => service.trimAppIdea(rawIdea: '   ', apiKey: 'key_123'),
        throwsA(isA<GroqBadRequestException>()),
      );
    });

    test('throws GroqUnauthorizedException on 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Invalid API Key'},
          }),
          401,
        );
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'invalid_key',
        ),
        throwsA(isA<GroqUnauthorizedException>()),
      );
    });

    test('throws GroqForbiddenException on 403 Forbidden', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Access forbidden'},
          }),
          403,
        );
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'forbidden_key',
        ),
        throwsA(isA<GroqForbiddenException>()),
      );
    });

    test('throws GroqNotFoundException on 404 Not Found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Model not found'},
          }),
          404,
        );
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'key_123',
        ),
        throwsA(isA<GroqNotFoundException>()),
      );
    });

    test('throws GroqRateLimitException on 429 Rate Limit Exceeded', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Rate limit exceeded'},
          }),
          429,
        );
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'key_123',
          initialBackoff: Duration.zero,
        ),
        throwsA(isA<GroqRateLimitException>()),
      );
    });

    test('throws GroqBadRequestException on 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Bad Request: invalid payload'},
          }),
          400,
        );
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'key_123',
        ),
        throwsA(isA<GroqBadRequestException>()),
      );
    });

    test('throws GroqServerException on 500 Internal Server Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Internal Server Error'},
          }),
          500,
        );
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'key_123',
          initialBackoff: Duration.zero,
        ),
        throwsA(isA<GroqServerException>()),
      );
    });

    test('throws GroqParseException on empty response body', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'key_123',
        ),
        throwsA(isA<GroqParseException>()),
      );
    });

    test('throws GroqParseException on malformed JSON response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{not valid json', 200);
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(
          rawIdea: 'Test Idea',
          apiKey: 'key_123',
        ),
        throwsA(isA<GroqParseException>()),
      );
    });
  });

  group('Step 9 — Local Test Method for Lecture Summarizer Idea', () {
    test('successfully processes the exact student test idea with full triage fields', () async {
      const studentInput =
          'An app where students upload lecture recordings, get AI summaries, generate quizzes, '
          'track progress, compete on leaderboards, follow friends, customize profiles, '
          'receive notifications, and subscribe to premium plans.';

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/trim'));
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['rawIdea'], equals(studentInput));

        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': json.encode({
                  'project_name': 'LectureLens',
                  'core_value': 'Upload audio recordings to generate instant bulleted study summaries.',
                  'mvp_score': 88,
                  'must_haves': [
                    {
                      'feature': 'Lecture audio upload & transcription',
                      'reason': 'Fundamental input pipeline without which no summary is possible.'
                    },
                    {
                      'feature': 'AI summary generator',
                      'reason': 'The single promise of value to the student.'
                    }
                  ],
                  'discarded_bloat': [
                    {
                      'feature': 'Competitive student leaderboards',
                      'reason': 'Vanity gamification that distracts from actual studying.'
                    },
                    {
                      'feature': 'Friend follower network and social feeds',
                      'reason': 'Nobody wants another social network inside their study tool.'
                    },
                    {
                      'feature': 'Avatar and profile customization',
                      'reason': 'Cosmetic distraction offering zero educational value.'
                    },
                    {
                      'feature': 'Tiered recurring premium subscription wall',
                      'reason': 'Premature monetization friction before product-market fit.'
                    }
                  ],
                  'build_order': [
                    '01 Audio file picker and transcription queue',
                    '02 AI LLM summary prompt generator',
                    '03 Clean markdown summary study view'
                  ],
                  'harsh_truth': 'Students want high grades, not leaderboards and profile stickers.'
                }),
              },
            }
          ],
        };

        return http.Response(json.encode(mockResponse), 200);
      });

      final engine = TrimEngine(service: GroqService(client: mockClient));
      final result = await engine.testStudentPipeline(apiKey: 'gsk_test_mock');

      // Verify all expected output fields from Step 9
      expect(result.projectName, equals('LectureLens'));
      expect(result.coreValue, contains('Upload audio recordings'));
      expect(result.mvpScore, equals(88));
      expect(result.mustHaves, isNotEmpty);
      expect(result.mustHaves.first.feature, contains('transcription'));
      expect(result.mustHaves.first.reason, isNotEmpty);
      expect(result.discardedBloat, isNotEmpty);
      expect(result.discardedBloat.first.feature, contains('leaderboards'));
      expect(result.discardedBloat.first.reason, isNotEmpty);
      expect(result.buildOrder.length, equals(3));
      expect(result.harshTruth, contains('leaderboards'));
    });
  });

  group('TrimEngine Domain Repository Tests', () {
    test('delegates trimIdea execution to GroqService', () async {
      final mockClient = MockClient((request) async {
        final mockPayload = {
          'choices': [
            {
              'message': {
                'content': json.encode({
                  'project_name': 'EngineTest',
                  'core_value': 'Engine delegated test.',
                  'mvp_score': 88,
                  'must_haves': [{'feature': 'Feature A', 'reason': 'Reason A'}],
                  'discarded_bloat': [{'feature': 'Bloat A', 'reason': 'Reason B'}],
                  'build_order': ['01 Step 1'],
                  'harsh_truth': 'Truth.',
                }),
              },
            }
          ],
        };
        return http.Response(json.encode(mockPayload), 200);
      });

      final engine = TrimEngine(service: GroqService(client: mockClient));
      final result = await engine.trimIdea(rawIdea: 'Test Idea', apiKey: 'test_key');
      expect(result.projectName, equals('EngineTest'));
      expect(result.mvpScore, equals(88));
      expect(result.mustHaves.first.feature, equals('Feature A'));
    });
  });
}
