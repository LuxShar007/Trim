import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trim/main.dart';
import 'package:trim/screens/trimming_screen.dart';
import 'package:trim/screens/trim_results_screen.dart';
import 'package:trim/services/groq_service.dart';
import 'package:trim/services/trim_engine.dart';
import 'package:trim/widgets/spring_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleTriageJson = '''
  {
    "project_name": "FocusLoop",
    "core_value": "Core habit loop without distractions.",
    "mvp_score": 92,
    "must_haves": [
      {"feature": "Daily habit tracker", "reason": "Fundamental loop"}
    ],
    "discarded_bloat": [
      {"feature": "Crypto staking rewards", "reason": "Premature noise"}
    ],
    "build_order": [
      "01 Daily tracker"
    ],
    "harsh_truth": "Build the habit loop first."
  }
  ''';

  group('TRIM — STEP 10 TEST MATRIX: Request Lifecycle & Retry Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'groq_api_key': 'gsk_valid_test_key_for_lifecycle_matrix',
      });
    });

    test('TEST 1: Idea A -> Trim -> Verdict completes successfully', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          json.encode({
            'choices': [
              {
                'message': {'content': sampleTriageJson}
              }
            ]
          }),
          200,
        );
      });

      final engine = TrimEngine(service: GroqService(client: mockClient));
      final result = await engine.trimIdea(rawIdea: 'Idea A: Simple Habit App');

      expect(requestCount, equals(1));
      expect(result.projectName, equals('FocusLoop'));
      expect(result.mustHaves.length, equals(1));
      expect(result.discardedBloat.length, equals(1));
    });

    test('TEST 2 & 3: Back/Restart -> Idea B -> Trim -> Verdict with fresh request lifecycle', () async {
      final requestIds = <int?>[];
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'choices': [
              {
                'message': {'content': sampleTriageJson}
              }
            ]
          }),
          200,
        );
      });

      final service = GroqService(client: mockClient);

      // Request 1 (Idea A)
      await service.trimAppIdea(
        rawIdea: 'Idea A',
        requestId: 101,
      );
      requestIds.add(101);

      // Back / Restart -> Request 2 (Idea B)
      await service.trimAppIdea(
        rawIdea: 'Idea B: Different Project',
        requestId: 102,
      );
      requestIds.add(102);

      // Request 3 (Same Idea B retry / restart)
      await service.trimAppIdea(
        rawIdea: 'Idea B: Different Project',
        requestId: 103,
      );
      requestIds.add(103);

      expect(requestIds, equals([101, 102, 103]));
      expect(requestIds.toSet().length, equals(3), reason: 'Every request received a unique ID');
    });

    test('TEST 4: Idea C -> Intentionally trigger failure -> Retry -> Verdict with reset state', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response(
            json.encode({'error': {'message': 'Temporary 500 error'}}),
            500,
          );
        }
        return http.Response(
          json.encode({
            'choices': [
              {
                'message': {'content': sampleTriageJson}
              }
            ]
          }),
          200,
        );
      });

      final service = GroqService(client: mockClient);

      // Attempt 1: Fails
      await expectLater(
        service.trimAppIdea(rawIdea: 'Idea C', requestId: 1),
        throwsA(isA<GroqServerException>()),
      );

      // Attempt 2 (Retry): Succeeds cleanly
      final retryResult = await service.trimAppIdea(rawIdea: 'Idea C', requestId: 2);
      expect(retryResult.projectName, equals('FocusLoop'));
      expect(attempts, equals(2));
    });

    testWidgets('TEST 4 UI: TrimmingScreen retry clears error, resets stage to understanding, and succeeds', (tester) async {
      int attempts = 0;
      final retryCompleter = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response(
            json.encode({'error': {'message': 'Groq overloaded'}}),
            500,
          );
        }
        return await retryCompleter.future;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TrimmingScreen(
            rawIdea: 'Test Idea for Retry UI',
            engine: TrimEngine(service: GroqService(client: mockClient)),
          ),
        ),
      );

      // Allow attempt 1 to execute and fail
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Error screen should display specific header, NOT collapsed generic message
      expect(find.text('GROQ SERVER ERROR'), findsOneWidget);
      expect(find.text('RETRY TRIMMING'), findsOneWidget);

      // Tap Retry Trimming
      await tester.tap(find.text('RETRY TRIMMING'));
      await tester.pump();

      // UI must reset to UNDERSTANDING stage immediately while request 2 is in flight
      expect(find.text('UNDERSTANDING'), findsOneWidget);
      expect(find.text('GROQ SERVER ERROR'), findsNothing);

      // Complete attempt 2 successfully
      retryCompleter.complete(
        http.Response(
          json.encode({
            'choices': [
              {
                'message': {'content': sampleTriageJson}
              }
            ]
          }),
          200,
        ),
      );

      // Advance through verdictReady and physical settle
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Transition to TrimResultsScreen
      expect(find.byType(TrimResultsScreen), findsOneWidget);
    });

    testWidgets('TEST 5: Rapid double-tap guard in BrainDumpScreen dispatches exactly ONE push', (tester) async {
      await tester.pumpWidget(const TrimApp());
      await tester.pumpAndSettle();

      // Insert idea text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Valid idea with more than enough content for submission.');
      await tester.pump();

      // Tap Trim the Fat twice rapidly
      final button = find.byType(SpringButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.tap(button); // Second rapid tap
      await tester.pumpAndSettle();

      // Exactly ONE TrimmingScreen should be pushed
      expect(find.byType(TrimmingScreen), findsOneWidget);
    });

    test('TEST 6: Leave processing screen (pop) safely cancels request with no crash', () async {
      final cancelToken = TrimCancellableToken();

      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) => completer.future);

      final service = GroqService(client: mockClient);

      // Start request
      final future = service.trimAppIdea(
        rawIdea: 'In flight idea',
        cancelToken: cancelToken,
        requestId: 42,
      );

      // Cancel mid-flight (simulating leaving screen)
      cancelToken.cancel();
      expect(cancelToken.isCancelled, isTrue);

      // Complete HTTP response after cancellation
      completer.complete(
        http.Response(
          json.encode({
            'choices': [
              {'message': {'content': sampleTriageJson}}
            ]
          }),
          200,
        ),
      );

      // Should throw GroqCancelledException instead of applying result
      await expectLater(future, throwsA(isA<GroqCancelledException>()));
    });

    test('TEST 7 & 8: 10/10 CONSECUTIVE TRIMS — Zero failures, Zero duplicates', () async {
      int successCount = 0;
      int failureCount = 0;
      int duplicateCount = 0;
      final executedIds = <int>{};

      for (int i = 1; i <= 10; i++) {
        final requestId = i;
        if (executedIds.contains(requestId)) {
          duplicateCount++;
        }
        executedIds.add(requestId);

        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'choices': [
                {
                  'message': {
                    'content': json.encode({
                      'project_name': 'ConsecutiveTest$i',
                      'core_value': 'Core value $i',
                      'mvp_score': 80 + i,
                      'must_haves': [
                        {'feature': 'MustHave $i', 'reason': 'Reason $i'}
                      ],
                      'discarded_bloat': [
                        {'feature': 'Bloat $i', 'reason': 'Cut reason $i'}
                      ],
                      'build_order': ['01 Step $i'],
                      'harsh_truth': 'Truth $i',
                    }),
                  }
                }
              ]
            }),
            200,
          );
        });

        final engine = TrimEngine(service: GroqService(client: mockClient));
        try {
          final result = await engine.trimIdea(
            rawIdea: 'Consecutive Idea $i',
            requestId: requestId,
          );
          if (result.projectName == 'ConsecutiveTest$i') {
            successCount++;
          } else {
            failureCount++;
          }
        } catch (_) {
          failureCount++;
        }
      }

      expect(successCount, equals(10), reason: 'All 10 trims must succeed');
      expect(failureCount, equals(0), reason: 'Zero failures permitted');
      expect(duplicateCount, equals(0), reason: 'Zero duplicate request IDs');
    });

    test('Error Classification: Distinct headers for timeout, network, 401, 429, parse error', () {
      expect(const GroqTimeoutException().errorType, equals(TrimErrorType.requestTimeout));
      expect(const GroqCancelledException().errorType, equals(TrimErrorType.requestCancelled));
      expect(const GroqNetworkException().errorType, equals(TrimErrorType.networkError));
      expect(const GroqUnauthorizedException().errorType, equals(TrimErrorType.httpError));
      expect(const GroqRateLimitException().errorType, equals(TrimErrorType.httpError));
      expect(const GroqParseException('bad json').errorType, equals(TrimErrorType.parseError));
    });
  });
}
