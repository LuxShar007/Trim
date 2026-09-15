import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/services/groq_service.dart';

const String sampleTriageJson = '''
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

void main() {
  setUp(() {
    GroqService.resetInFlightState();
  });

  tearDown(() {
    GroqService.resetInFlightState();
  });

  group('TRIM — True Single-Flight Request Behavior Verification', () {
    test('Scenario 1: Single tap produces exactly ONE server request', () async {
      int serverRequestsReceived = 0;
      final mockClient = MockClient((request) async {
        serverRequestsReceived++;
        expect(request.url.path, endsWith('/api/trim'));
        expect(request.headers['x-client-request-id'], isNotNull);
        return http.Response(sampleTriageJson, 200);
      });

      final service = GroqService(client: mockClient);
      final result = await service.trimAppIdea(rawIdea: 'Single tap test idea');

      expect(serverRequestsReceived, equals(1),
          reason: 'A single tap must generate exactly one server request');
      expect(result.projectName, equals('FocusLoop'));
      expect(GroqService.isRequestInFlight, isFalse);
    });

    test('Scenario 2: Double tap within 100ms produces exactly ONE server request', () async {
      int serverRequestsReceived = 0;
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) {
        serverRequestsReceived++;
        return completer.future;
      });

      final service = GroqService(client: mockClient);

      // Tap 1 at t=0ms
      final future1 = service.trimAppIdea(
        rawIdea: 'Double tap within 100ms test',
        requestId: 'tap_1',
      );

      // Wait 30ms (< 100ms) and tap 2
      await Future.delayed(const Duration(milliseconds: 30));
      final future2 = service.trimAppIdea(
        rawIdea: 'Double tap within 100ms test',
        requestId: 'tap_2',
      );

      expect(serverRequestsReceived, equals(1),
          reason: 'Double tap within 100ms must NOT transmit a second HTTP request to /api/trim');

      // Complete server response
      completer.complete(http.Response(sampleTriageJson, 200));

      final results = await Future.wait([future1, future2]);
      expect(serverRequestsReceived, equals(1),
          reason: 'Total requests reaching server must remain exactly ONE');
      expect(results[0].projectName, equals('FocusLoop'));
      expect(results[1].projectName, equals('FocusLoop'));
      expect(GroqService.isRequestInFlight, isFalse);
    });

    test('Scenario 3: Repeated rapid taps produce exactly ONE server request', () async {
      int serverRequestsReceived = 0;
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) {
        serverRequestsReceived++;
        return completer.future;
      });

      final service = GroqService(client: mockClient);

      // Rapidly fire 5 taps
      final futures = <Future<TrimResult>>[];
      for (int i = 1; i <= 5; i++) {
        futures.add(service.trimAppIdea(
          rawIdea: 'Rapid repeated taps idea',
          requestId: 'tap_$i',
        ));
      }

      // Yield to event loop to allow first request to transmit to client
      await Future.delayed(Duration.zero);

      expect(serverRequestsReceived, equals(1),
          reason: '5 rapid taps must produce exactly ONE server request');

      completer.complete(http.Response(sampleTriageJson, 200));

      final results = await Future.wait(futures);
      expect(serverRequestsReceived, equals(1),
          reason: 'Server must receive only 1 request across all 5 taps');
      for (final res in results) {
        expect(res.projectName, equals('FocusLoop'));
      }
      expect(GroqService.isRequestInFlight, isFalse);
    });

    test('Scenario 4: Tap during processing joins active in-flight request and produces ONE server request', () async {
      int serverRequestsReceived = 0;
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) {
        serverRequestsReceived++;
        return completer.future;
      });

      final service = GroqService(client: mockClient);

      // Initial tap
      final future1 = service.trimAppIdea(
        rawIdea: 'Tap during processing idea',
        requestId: 'req_initial',
      );

      // Yield so request 1 begins network transmission
      await Future.delayed(Duration.zero);
      expect(GroqService.isRequestInFlight, isTrue);
      expect(serverRequestsReceived, equals(1));

      // Simulate mid-processing delay, then tap again
      await Future.delayed(const Duration(milliseconds: 50));
      final future2 = service.trimAppIdea(
        rawIdea: 'Tap during processing idea',
        requestId: 'req_mid_processing',
      );

      expect(serverRequestsReceived, equals(1),
          reason: 'Tap during processing must not initiate a second server request');

      completer.complete(http.Response(sampleTriageJson, 200));

      final results = await Future.wait([future1, future2]);
      expect(serverRequestsReceived, equals(1));
      expect(results[0].projectName, equals('FocusLoop'));
      expect(results[1].projectName, equals('FocusLoop'));
    });

    test('Scenario 5: Retry while processing is suppressed and produces ONE server request', () async {
      int serverRequestsReceived = 0;
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) {
        serverRequestsReceived++;
        return completer.future;
      });

      final service = GroqService(client: mockClient);

      // Start initial processing
      final future1 = service.trimAppIdea(
        rawIdea: 'Retry while processing idea',
        requestId: 'req_original',
      );

      // Yield so request begins network transmission
      await Future.delayed(Duration.zero);
      expect(GroqService.isRequestInFlight, isTrue);

      // Attempt retry while processing is actively underway
      final futureRetry = service.trimAppIdea(
        rawIdea: 'Retry while processing idea',
        requestId: 'req_retry_while_processing',
      );

      expect(serverRequestsReceived, equals(1),
          reason: 'Retry while processing must NOT trigger a second HTTP request');

      completer.complete(http.Response(sampleTriageJson, 200));

      final results = await Future.wait([future1, futureRetry]);
      expect(serverRequestsReceived, equals(1));
      expect(results[0].projectName, equals('FocusLoop'));
      expect(results[1].projectName, equals('FocusLoop'));
    });

    test('Distinction A: Cancelling a local Dart operation before HTTP request begins results in ZERO server requests', () async {
      int serverRequestsReceived = 0;
      final mockClient = MockClient((request) async {
        serverRequestsReceived++;
        return http.Response(sampleTriageJson, 200);
      });

      final service = GroqService(client: mockClient);
      final cancelToken = TrimCancellableToken();

      // Cancel token locally in Phase A (before trimAppIdea even transmits)
      cancelToken.cancel();
      expect(cancelToken.isCancelled, isTrue);

      await expectLater(
        service.trimAppIdea(
          rawIdea: 'Phase A cancellation test',
          cancelToken: cancelToken,
        ),
        throwsA(isA<GroqCancelledException>()),
      );

      expect(serverRequestsReceived, equals(0),
          reason: 'Cancelling before HTTP request transmission must send 0 requests to server');
      expect(GroqService.isRequestInFlight, isFalse);
    });

    test('Distinction B: Cancelling after network transmission closes local socket, exactly ONE request reached server', () async {
      int serverRequestsReceived = 0;
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) {
        serverRequestsReceived++;
        return completer.future;
      });

      final service = GroqService(client: mockClient);
      final cancelToken = TrimCancellableToken();

      final future = service.trimAppIdea(
        rawIdea: 'Phase B cancellation test',
        cancelToken: cancelToken,
      );

      // Yield so request transmits across the wire to the mock client
      await Future.delayed(Duration.zero);

      // At this point, the request has been transmitted over the network to the server
      expect(serverRequestsReceived, equals(1),
          reason: 'Request has already reached the server in Phase B');
      expect(cancelToken.phase, equals(TrimRequestPhase.networkTransmitted));

      // User cancels after transmission
      cancelToken.cancel();
      expect(cancelToken.isCancelled, isTrue);

      if (!completer.isCompleted) {
        completer.complete(http.Response(sampleTriageJson, 200));
      }

      await expectLater(future, throwsA(isA<GroqCancelledException>()));
      expect(serverRequestsReceived, equals(1),
          reason: 'Server received exactly 1 request before client-side cancellation');
      expect(GroqService.isRequestInFlight, isFalse);
    });
  });
}
