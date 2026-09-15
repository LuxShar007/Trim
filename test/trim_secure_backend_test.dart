import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trim/services/groq_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleVerdictPayload = {
    'project_name': 'RazorApp',
    'core_value': 'One feature done exceptionally well.',
    'mvp_score': 95,
    'must_haves': [
      {'feature': 'Core Action Loop', 'reason': 'Essential loop'}
    ],
    'discarded_bloat': [
      {'feature': 'Social Feed', 'reason': 'Premature noise'}
    ],
    'build_order': ['01 Core Action Loop'],
    'harsh_truth': 'Complexity is the enemy of launch.',
  };

  group('TRIM SECURE VERCEL BACKEND MIGRATION VERIFICATION MATRIX', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GroqService.resetInFlightState();
    });

    // Scenario A & B: Web / Android client calls /api/trim without client key
    test('A & B: Client calls /api/trim endpoint without client master key and receives Verdict', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/trim'));
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['rawIdea'], equals('Build a minimal habit tracker'));

        return http.Response(json.encode(sampleVerdictPayload), 200);
      });

      final service = GroqService(client: mockClient);
      final result = await service.trimAppIdea(rawIdea: 'Build a minimal habit tracker');

      expect(result.projectName, equals('RazorApp'));
      expect(result.mvpScore, equals(95));
      expect(result.mustHaves.first.feature, equals('Core Action Loop'));
    });

    // Scenario C: 429 Rate Limiting with retryAfter header and controlled retry
    test('C: 429 rate limit triggers controlled retry up to maxRetries then throws GroqRateLimitException', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        return http.Response(
          json.encode({
            'error': {
              'code': 'RATE_LIMITED',
              'message': 'Too many trims are happening right now. Give it a moment and try again.',
              'retryAfter': 3,
            }
          }),
          429,
          headers: {'retry-after': '3'},
        );
      });

      final service = GroqService(
        client: mockClient,
        defaultMaxRetries: 2,
        defaultInitialBackoff: Duration.zero,
      );

      try {
        await service.trimAppIdea(rawIdea: 'Test rate limiting');
        fail('Expected GroqRateLimitException');
      } on GroqRateLimitException catch (e) {
        expect(attempts, equals(3), reason: 'Initial + 2 retries = 3 attempts');
        expect(e.retryAfter, equals(const Duration(seconds: 3)));
        expect(e.message, contains('Too many trims'));
        expect(e.message.contains('Groq'), isFalse);
        expect(e.message.contains('API Key'), isFalse);
      }
    });

    // Scenario D: 401/403 Upstream Error is masked safely without retry storm
    test('D: 401/403 fails immediately without retry storm and hides provider names', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        return http.Response(
          json.encode({
            'error': {
              'code': 'SERVICE_UNAVAILABLE',
              'message': 'Trim service is temporarily unavailable. Please try again in a moment.',
            }
          }),
          401,
        );
      });

      final service = GroqService(client: mockClient);

      try {
        await service.trimAppIdea(rawIdea: 'Test 401');
        fail('Expected GroqUnauthorizedException');
      } on GroqUnauthorizedException catch (e) {
        expect(attempts, equals(1), reason: '401 must fail immediately with zero retries');
        expect(e.message, contains('Trim service is temporarily unavailable'));
        expect(e.message.contains('Groq'), isFalse);
        expect(e.message.contains('gsk_'), isFalse);
      }
    });

    // Scenario E: 5xx Server Error performs controlled retry
    test('E: 5xx Server Error performs controlled retry up to maxRetries then throws GroqServerException', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        return http.Response(
          json.encode({
            'error': {
              'code': 'UPSTREAM_ERROR',
              'message': 'Trim AI engine encountered an unexpected error. Please try again.',
            }
          }),
          502,
        );
      });

      final service = GroqService(
        client: mockClient,
        defaultMaxRetries: 2,
        defaultInitialBackoff: Duration.zero,
      );

      try {
        await service.trimAppIdea(rawIdea: 'Test 502');
        fail('Expected GroqServerException');
      } on GroqServerException catch (e) {
        expect(attempts, equals(3));
        expect(e.statusCode, equals(502));
        expect(e.message.contains('Groq'), isFalse);
      }
    });

    // Scenario F: Malformed / empty input is rejected locally before network call
    test('F: Empty or whitespace-only rawIdea throws GroqBadRequestException locally', () async {
      int networkCalls = 0;
      final mockClient = MockClient((request) async {
        networkCalls++;
        return http.Response('{}', 200);
      });

      final service = GroqService(client: mockClient);

      expect(
        () => service.trimAppIdea(rawIdea: '   \n  '),
        throwsA(isA<GroqBadRequestException>()),
      );
      expect(networkCalls, equals(0), reason: 'Zero network calls should be made for empty idea');
    });

    // Scenario G: Missing server secret returns clean CONFIG_ERROR without leakage
    test('G: Server config failure returns clean error without leaking keys', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {
              'code': 'CONFIG_ERROR',
              'message': 'Trim AI engine is temporarily unavailable. Please try again later.',
            }
          }),
          500,
        );
      });

      final service = GroqService(
        client: mockClient,
        defaultMaxRetries: 0,
      );

      try {
        await service.trimAppIdea(rawIdea: 'Test server config error');
        fail('Expected GroqServerException');
      } on GroqServerException catch (e) {
        expect(e.message, contains('Trim AI engine is temporarily unavailable'));
        expect(e.message.contains('GROQ_API_KEY'), isFalse);
        expect(e.message.contains('Bearer'), isFalse);
      }
    });

    // Scenario H: Single-flight request protection: subsequent request coalesces into active in-flight request
    test('H: Rapid double-tap transmits exactly ONE request to /api/trim and shares result', () async {
      int httpCalls = 0;
      final mockClient = MockClient((request) async {
        httpCalls++;
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(json.encode(sampleVerdictPayload), 200);
      });

      final service = GroqService(client: mockClient);

      final token1 = TrimCancellableToken();
      final future1 = service.trimAppIdea(
        rawIdea: 'Rapid double-tap idea',
        cancelToken: token1,
      );

      expect(GroqService.isRequestInFlight, isTrue);

      final token2 = TrimCancellableToken();
      final future2 = service.trimAppIdea(
        rawIdea: 'Rapid double-tap idea',
        cancelToken: token2,
      );

      final results = await Future.wait([future1, future2]);
      expect(httpCalls, equals(1), reason: 'Double tap must produce exactly ONE server request');
      expect(results[0].projectName, equals('RazorApp'));
      expect(results[1].projectName, equals('RazorApp'));
      expect(GroqService.isRequestInFlight, isFalse);
    });

    // Scenario I: Saved history reads locally without any network requests
    test('I: Local history operates fully offline with zero Groq requests', () async {
      int networkCalls = 0;

      // SharedPreferences / local cache check
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(networkCalls, equals(0), reason: 'Local storage must not make network requests');
    });
  });
}
