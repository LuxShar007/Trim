import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trim_result.dart';

/// Categorized error types for UI differentiation.
enum TrimErrorType {
  requestTimeout,
  requestCancelled,
  networkError,
  httpError,
  parseError,
}

/// Base exception for all Groq API client failures.
abstract class GroqException implements Exception {
  final String message;
  final int? statusCode;
  final TrimErrorType errorType;

  const GroqException(
    this.message, {
    this.statusCode,
    this.errorType = TrimErrorType.httpError,
  });

  @override
  String toString() => message;
}

/// HTTP 400 - Bad Request
class GroqBadRequestException extends GroqException {
  const GroqBadRequestException(super.message, [int? statusCode = 400])
      : super(statusCode: statusCode, errorType: TrimErrorType.httpError);
}

/// HTTP 401 - Unauthorized / Invalid API Key
class GroqUnauthorizedException extends GroqException {
  const GroqUnauthorizedException([String? message])
      : super(
          message ??
              'Trim service is temporarily unavailable. Please try again.',
          statusCode: 401,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 403 - Forbidden
class GroqForbiddenException extends GroqException {
  const GroqForbiddenException([String? message])
      : super(
          message ?? 'Trim service is temporarily unavailable. Please try again.',
          statusCode: 403,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 404 - Not Found
class GroqNotFoundException extends GroqException {
  const GroqNotFoundException([String? message])
      : super(
          message ?? 'Resource not found.',
          statusCode: 404,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 429 - Rate Limit Exceeded
class GroqRateLimitException extends GroqException {
  final Duration? retryAfter;

  const GroqRateLimitException([
    String? message,
    this.retryAfter,
  ]) : super(
          message ??
              'Too many trims are happening right now. Give it a moment and try again.',
          statusCode: 429,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 500+ - Server Error
class GroqServerException extends GroqException {
  const GroqServerException([String? message, int? statusCode = 500])
      : super(
          message ?? 'Trim service is temporarily paused. Please try again in a moment.',
          statusCode: statusCode,
          errorType: TrimErrorType.httpError,
        );
}

/// Network connectivity failure (SocketException / DNS failure)
class GroqNetworkException extends GroqException {
  const GroqNetworkException([String? message])
      : super(
          message ?? 'No internet connection. Please check your network and try again.',
          errorType: TrimErrorType.networkError,
        );
}

/// Request timeout (60 seconds)
class GroqTimeoutException extends GroqException {
  const GroqTimeoutException([String? message])
      : super(
          message ?? 'Request timed out after 60 seconds. Groq took too long to respond.',
          errorType: TrimErrorType.requestTimeout,
        );
}

/// Request explicitly cancelled by user navigation or retry
class GroqCancelledException extends GroqException {
  const GroqCancelledException([String? message])
      : super(
          message ?? 'Groq API trim request was cancelled.',
          errorType: TrimErrorType.requestCancelled,
        );
}

/// Malformed JSON or invalid schema in completion
class GroqParseException extends GroqException {
  const GroqParseException(super.message)
      : super(errorType: TrimErrorType.parseError);
}

/// Backward compatibility alias
typedef GroqApiException = GroqException;

/// Represents the distinct lifecycle phases of a Trim request.
enum TrimRequestPhase {
  notStarted,
  localPreparing,     // Phase A: Local Dart operation before HTTP request begins
  networkTransmitted, // Phase B: HTTP request transmitted over the network
  completed,
  cancelled,
}

/// Cooperative cancellation token for in-flight requests with phase tracking
class TrimCancellableToken {
  bool _isCancelled = false;
  TrimRequestPhase _phase = TrimRequestPhase.notStarted;
  http.Client? _activeClient;
  String? _requestId;

  bool get isCancelled => _isCancelled;
  TrimRequestPhase get phase => _phase;
  String? get requestId => _requestId;

  void attachClient(http.Client client) {
    _activeClient = client;
  }

  void setPhase(TrimRequestPhase phase, {String? requestId}) {
    _phase = phase;
    if (requestId != null) _requestId = requestId;
  }

  void cancel() {
    _isCancelled = true;
    final priorPhase = _phase;
    _phase = TrimRequestPhase.cancelled;
    try {
      _activeClient?.close();
    } catch (_) {}
    if (kDebugMode) {
      final phaseDescription = priorPhase == TrimRequestPhase.localPreparing
          ? 'Phase A (Local Dart operation before HTTP transmission)'
          : priorPhase == TrimRequestPhase.networkTransmitted
              ? 'Phase B (Request was already transmitted over network; client socket closed)'
              : priorPhase.toString();
      debugPrint(
        '[TRIM DIAGNOSTIC] [Request Cancellation] ID: $_requestId '
        'Timestamp: ${DateTime.now().toIso8601String()} Phase: $phaseDescription',
      );
    }
  }
}

/// Standalone HTTP service communicating with Trim Vercel backend (/api/trim).
class GroqService {
  /// Default backend URL for native/mobile platforms (Android/iOS).
  /// Can be overridden at build time via --dart-define=TRIM_BACKEND_URL=...
  static const String _defaultBackendUrl = String.fromEnvironment(
    'TRIM_BACKEND_URL',
    defaultValue: 'https://web-rust-chi-46.vercel.app/api/trim',
  );

  static const String _apiKeyPrefKey = 'groq_api_key';
  static const Duration _timeoutDuration = Duration(seconds: 60);

  /// Resolves the effective API endpoint:
  /// - Web: relative '/api/trim' (prevents CORS and avoids hardcoded domains)
  /// - Non-web / Android: custom override or configured HTTPS backend URL
  static String resolveEndpoint([String? customOverride]) {
    if (customOverride != null && customOverride.trim().isNotEmpty) {
      return customOverride.trim();
    }
    if (kIsWeb) {
      return '/api/trim';
    }
    return _defaultBackendUrl;
  }

  final http.Client? _customClient;
  final String? customEndpoint;
  final int defaultMaxRetries;
  final Duration? defaultInitialBackoff;

  GroqService({
    http.Client? client,
    this.customEndpoint,
    this.defaultMaxRetries = 2,
    this.defaultInitialBackoff,
  }) : _customClient = client;

  /// Retrieve stored API key from device preferences (for optional dev override).
  static Future<String?> getSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_apiKeyPrefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Save API key to device preferences (dev override).
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey.trim());
  }

  /// Clear saved API key.
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
  }

  static bool _isRequestInFlight = false;
  static TrimCancellableToken? _activeGlobalToken;
  static Future<TrimResult>? _activeInFlightFuture;
  static String? _activeInFlightRequestId;
  static int _globalRequestCounter = 0;

  /// Returns true if a Trim request is currently actively in flight across the application.
  static bool get isRequestInFlight => _isRequestInFlight;

  /// Returns the current active cancellation token if in-flight.
  static TrimCancellableToken? get activeGlobalToken => _activeGlobalToken;

  /// Resets the in-flight state (used for test isolation).
  @visibleForTesting
  static void resetInFlightState() {
    _isRequestInFlight = false;
    _activeGlobalToken = null;
    _activeInFlightFuture = null;
    _activeInFlightRequestId = null;
  }

  /// Parses the retry-after duration from HTTP response headers or response body.
  static Duration parseRetryAfter(
    Map<String, String> headers,
    String body, {
    Duration defaultFallback = const Duration(seconds: 2),
  }) {
    // 1. Check HTTP 'retry-after' header (case-insensitive)
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        final val = entry.value.trim();
        final seconds = int.tryParse(val);
        if (seconds != null && seconds > 0) {
          return Duration(seconds: seconds);
        }
        final doubleSec = double.tryParse(val);
        if (doubleSec != null && doubleSec > 0) {
          return Duration(milliseconds: (doubleSec * 1000).ceil());
        }
      }
    }

    // 2. Fallback: Parse body message for "try again in X.Xs" or "in Xs"
    try {
      final match = RegExp(r'try again in\s+([0-9.]+)\s*s', caseSensitive: false).firstMatch(body);
      if (match != null) {
        final seconds = double.tryParse(match.group(1)!);
        if (seconds != null && seconds > 0) {
          return Duration(milliseconds: (seconds * 1000).ceil());
        }
      }
    } catch (_) {}

    return defaultFallback;
  }

  static Duration _calculateBackoff(int retryIndex, {Duration? initialBackoff}) {
    if (initialBackoff != null) {
      if (initialBackoff == Duration.zero) return Duration.zero;
      return initialBackoff * (1 << retryIndex);
    }
    // Default exponential backoff: 1.5s, 3.0s (clamped to max 15s)
    final ms = (1500 * (1 << retryIndex)).clamp(500, 15000);
    return Duration(milliseconds: ms);
  }

  static Future<void> _sleepInterruptible(Duration duration, TrimCancellableToken? cancelToken) async {
    if (duration <= Duration.zero) return;
    const interval = Duration(milliseconds: 100);
    var remaining = duration;
    while (remaining > Duration.zero) {
      if (cancelToken?.isCancelled == true) {
        throw const GroqCancelledException();
      }
      final step = remaining > interval ? interval : remaining;
      await Future.delayed(step);
      remaining -= step;
    }
  }

  /// Sends the bloated idea to Trim backend (/api/trim)
  /// with true single-flight concurrency protection and controlled retry logic.
  Future<TrimResult> trimAppIdea({
    required String rawIdea,
    String? apiKey,
    http.Client? client,
    TrimCancellableToken? cancelToken,
    dynamic requestId,
    int? maxRetries,
    Duration? initialBackoff,
  }) async {
    final String clientReqId = requestId != null
        ? requestId.toString()
        : 'req_${DateTime.now().microsecondsSinceEpoch}_${++_globalRequestCounter}';

    final effectiveToken = cancelToken ?? TrimCancellableToken();
    effectiveToken.setPhase(TrimRequestPhase.localPreparing, requestId: clientReqId);

    if (kDebugMode) {
      debugPrint(
        '[TRIM DIAGNOSTIC] [Phase A - Local Prepare] Request ID: $clientReqId '
        'Timestamp: ${DateTime.now().toIso8601String()}',
      );
    }

    if (effectiveToken.isCancelled) {
      if (kDebugMode) {
        debugPrint(
          '[TRIM DIAGNOSTIC] [Phase A - Cancelled] Request ID: $clientReqId '
          'Timestamp: ${DateTime.now().toIso8601String()} (Cancelled before HTTP transmission)',
        );
      }
      throw const GroqCancelledException();
    }

    // Single-flight coalescing:
    // If a request is already in flight, reuse the active in-flight future.
    // This strictly guarantees that ONE user Trim action NEVER produces multiple /api/trim requests!
    if (_isRequestInFlight && _activeInFlightFuture != null) {
      if (kDebugMode) {
        debugPrint(
          '[TRIM DIAGNOSTIC] [Single-Flight Coalesced] Request ID: $clientReqId '
          'Timestamp: ${DateTime.now().toIso8601String()} '
          'Coalescing concurrent call into active in-flight Request ID: $_activeInFlightRequestId '
          '(Zero additional HTTP requests sent to /api/trim)',
        );
      }
      return _activeInFlightFuture!;
    }

    _isRequestInFlight = true;
    _activeGlobalToken = effectiveToken;
    _activeInFlightRequestId = clientReqId;

    final future = _executeTrimRequest(
      rawIdea: rawIdea,
      apiKey: apiKey,
      client: client,
      cancelToken: effectiveToken,
      clientRequestId: clientReqId,
      maxRetries: maxRetries,
      initialBackoff: initialBackoff,
    );
    _activeInFlightFuture = future;

    try {
      return await future;
    } finally {
      if (identical(_activeInFlightFuture, future)) {
        _isRequestInFlight = false;
        _activeGlobalToken = null;
        _activeInFlightFuture = null;
        _activeInFlightRequestId = null;
      }
    }
  }

  Future<TrimResult> _executeTrimRequest({
    required String rawIdea,
    required TrimCancellableToken cancelToken,
    required String clientRequestId,
    String? apiKey,
    http.Client? client,
    int? maxRetries,
    Duration? initialBackoff,
  }) async {
    final effectiveMaxRetries = maxRetries ?? defaultMaxRetries;
    final effectiveInitialBackoff = initialBackoff ?? defaultInitialBackoff;

    final effectiveClient = client ?? _customClient ?? http.Client();
    final bool isOwnedClient = (client == null && _customClient == null);
    cancelToken.attachClient(effectiveClient);

    final maxAttempts = 1 + effectiveMaxRetries;
    int attempt = 0;
    final stopwatch = Stopwatch()..start();

    try {
      final trimmedIdea = rawIdea.trim();
      if (trimmedIdea.isEmpty) {
        throw const GroqBadRequestException(
          'The app idea is empty. Please dump your chaotic thoughts first.',
        );
      }

      final endpointUrl = resolveEndpoint(customEndpoint);
      final uri = Uri.parse(endpointUrl);
      final payload = {
        'rawIdea': trimmedIdea,
        'clientRequestId': clientRequestId,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'x-client-request-id': clientRequestId,
      };
      if (apiKey != null && apiKey.trim().isNotEmpty) {
        headers['x-groq-key'] = apiKey.trim();
      }

      while (attempt < maxAttempts) {
        if (cancelToken.isCancelled) {
          throw const GroqCancelledException();
        }

        attempt++;
        final attemptStartTime = DateTime.now();

        // Phase B: HTTP request transmitted over network
        cancelToken.setPhase(TrimRequestPhase.networkTransmitted, requestId: clientRequestId);
        if (kDebugMode) {
          debugPrint(
            '[TRIM DIAGNOSTIC] [Phase B - Request Start] Request ID: $clientRequestId '
            'Attempt $attempt/$maxAttempts Timestamp: ${attemptStartTime.toIso8601String()} '
            'Endpoint: $endpointUrl',
          );
        }

        http.Response response;
        try {
          response = await effectiveClient
              .post(
                uri,
                headers: headers,
                body: json.encode(payload),
              )
              .timeout(_timeoutDuration);

          if (cancelToken.isCancelled) {
            if (kDebugMode) {
              debugPrint(
                '[TRIM DIAGNOSTIC] [Phase B - Cancelled] Request ID: $clientRequestId '
                'Timestamp: ${DateTime.now().toIso8601String()} '
                '(Cancelled after network transmission; socket closed locally)',
              );
            }
            throw const GroqCancelledException();
          }
        } on SocketException catch (e) {
          if (cancelToken.isCancelled) throw const GroqCancelledException();
          if (attempt < maxAttempts) {
            final backoff = _calculateBackoff(attempt - 1, initialBackoff: effectiveInitialBackoff);
            if (kDebugMode) {
              debugPrint('[TRIM DIAGNOSTIC] SocketException ($e). Retrying in ${backoff.inMilliseconds}ms...');
            }
            await _sleepInterruptible(backoff, cancelToken);
            continue;
          }
          throw const GroqNetworkException();
        } on TimeoutException catch (e) {
          if (cancelToken.isCancelled) throw const GroqCancelledException();
          if (attempt < maxAttempts) {
            final backoff = _calculateBackoff(attempt - 1, initialBackoff: effectiveInitialBackoff);
            if (kDebugMode) {
              debugPrint('[TRIM DIAGNOSTIC] TimeoutException ($e). Retrying in ${backoff.inMilliseconds}ms...');
            }
            await _sleepInterruptible(backoff, cancelToken);
            continue;
          }
          throw const GroqTimeoutException();
        } catch (e) {
          if (cancelToken.isCancelled ||
              (e is http.ClientException && e.message.contains('Client is closed'))) {
            throw const GroqCancelledException();
          }
          if (e is GroqException) rethrow;
          if (attempt < maxAttempts) {
            final backoff = _calculateBackoff(attempt - 1, initialBackoff: effectiveInitialBackoff);
            await _sleepInterruptible(backoff, cancelToken);
            continue;
          }
          throw GroqNetworkException('Connection failed: $e');
        }

        final statusCode = response.statusCode;
        final responseBody = response.body;
        final elapsed = stopwatch.elapsedMilliseconds;

        if (kDebugMode) {
          debugPrint(
            '[TRIM DIAGNOSTIC] [Request Complete] Request ID: $clientRequestId '
            'Attempt $attempt Status: $statusCode Duration: ${elapsed}ms '
            'Timestamp: ${DateTime.now().toIso8601String()}',
          );
        }

        // 200 OK: Successful completion
        if (statusCode == 200) {
          cancelToken.setPhase(TrimRequestPhase.completed, requestId: clientRequestId);
          if (responseBody.trim().isEmpty) {
            throw const GroqParseException('Groq API returned an empty response.');
          }
          return _parseSuccessfulResponse(responseBody);
        }

        // HTTP 429: Rate Limit Exceeded
        if (statusCode == 429) {
          final retryAfter = parseRetryAfter(response.headers, responseBody);
          final errorMsg = _extractErrorMessage(responseBody);

          if (attempt < maxAttempts) {
            final backoff = effectiveInitialBackoff != null
                ? effectiveInitialBackoff * attempt
                : (retryAfter.inMilliseconds > 0
                    ? retryAfter
                    : _calculateBackoff(attempt - 1, initialBackoff: const Duration(seconds: 2)));
            // Clamp backoff to maximum 15s to keep UI responsive
            final effectiveBackoff = backoff > const Duration(seconds: 15) ? const Duration(seconds: 15) : backoff;

            if (kDebugMode) {
              debugPrint(
                '[TRIM DIAGNOSTIC] HTTP 429 Rate Limit. retry-after: ${retryAfter.inSeconds}s. '
                'Backing off for ${effectiveBackoff.inMilliseconds}ms before attempt ${attempt + 1}/$maxAttempts',
              );
            }

            await _sleepInterruptible(effectiveBackoff, cancelToken);
            continue;
          }

          throw GroqRateLimitException(
            errorMsg.isNotEmpty ? errorMsg : 'Too many trims are happening right now. Give it a moment and try again.',
            retryAfter,
          );
        }

        // HTTP 401: Unauthorized / Expired API Key (Fail immediately, zero retries)
        if (statusCode == 401) {
          final errorMsg = _extractErrorMessage(responseBody);
          throw GroqUnauthorizedException(
            errorMsg.isNotEmpty ? errorMsg : 'Trim service authorization failed.',
          );
        }

        // HTTP 400: Bad Request
        if (statusCode == 400) {
          final errorMsg = _extractErrorMessage(responseBody);
          throw GroqBadRequestException(
            errorMsg.isNotEmpty ? errorMsg : 'The app idea could not be analyzed.',
          );
        }

        // HTTP 5xx: Server Error (Exponential Backoff)
        if (statusCode >= 500) {
          final errorMsg = _extractErrorMessage(responseBody);
          if (attempt < maxAttempts) {
            final backoff = _calculateBackoff(attempt - 1, initialBackoff: effectiveInitialBackoff);
            if (kDebugMode) {
              debugPrint('[TRIM DIAGNOSTIC] HTTP $statusCode Server Error. Retrying in ${backoff.inMilliseconds}ms...');
            }
            await _sleepInterruptible(backoff, cancelToken);
            continue;
          }
          throw GroqServerException(
            errorMsg.isNotEmpty ? errorMsg : 'Trim service is temporarily paused. Please try again in a moment.',
            statusCode,
          );
        } else if (statusCode == 403) {
          final errorMsg = _extractErrorMessage(responseBody);
          throw GroqForbiddenException(
            errorMsg.isNotEmpty ? errorMsg : 'Trim service is temporarily unavailable. Please try again in a moment.',
          );
        } else if (statusCode == 404) {
          final errorMsg = _extractErrorMessage(responseBody);
          throw GroqNotFoundException(
            errorMsg.isNotEmpty ? errorMsg : 'Trim endpoint not found.',
          );
        } else {
          final errorMsg = _extractErrorMessage(responseBody);
          throw GroqBadRequestException(
            errorMsg.isNotEmpty ? errorMsg : 'Unexpected response ($statusCode).',
            statusCode,
          );
        }
      }

      throw const GroqServerException('Request failed after maximum retry attempts.');
    } finally {
      if (isOwnedClient) {
        effectiveClient.close();
      }
    }
  }

  /// Parses and validates the completion string from direct TrimResult JSON or legacy envelope.
  TrimResult _parseSuccessfulResponse(String responseBody) {
    // Step 4: First decode top-level HTTP response
    final dynamic responseJson;
    try {
      responseJson = jsonDecode(responseBody);
    } catch (e) {
      if (kDebugMode) debugPrint('[TRIM DEBUG] Malformed HTTP response JSON: $e');
      throw GroqParseException('Malformed JSON response from Trim service: $e');
    }

    if (responseJson is! Map<String, dynamic>) {
      throw const GroqParseException('HTTP response is not a valid JSON map.');
    }

    // Direct TrimResult JSON contract from /api/trim
    if (responseJson.containsKey('project_name') && responseJson.containsKey('core_value')) {
      final result = TrimResult.fromJson(responseJson);
      if (kDebugMode) debugPrint('[TRIM DEBUG] Parsed TrimResult directly from backend');
      return result;
    }

    // Fallback: Extract choices[0].message.content (legacy Groq response envelope)
    final choices = responseJson['choices'];
    if (choices == null || choices is! List || choices.isEmpty) {
      throw const GroqParseException('Response missing "choices" or Trim schema keys.');
    }

    final firstChoice = choices[0];
    if (firstChoice is! Map) {
      throw const GroqParseException('Invalid choices[0] in Groq response.');
    }

    final message = firstChoice['message'];
    if (message is! Map) {
      throw const GroqParseException('Missing "message" in choices[0].');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const GroqParseException('Missing or empty content string in choices[0].message.');
    }

    if (kDebugMode) {
      debugPrint('[TRIM DEBUG] Extracted content: $content');
    }

    // Parse content separately as inner JSON string
    final dynamic resultJson;
    try {
      final cleaned = TrimResult.cleanRawJson(content);
      resultJson = jsonDecode(cleaned);
    } catch (e) {
      if (kDebugMode) debugPrint('[TRIM DEBUG] Malformed inner content JSON: $e');
      // If direct jsonDecode failed, attempt substring fallback
      try {
        final cleaned = TrimResult.cleanRawJson(content);
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          final sub = jsonDecode(cleaned.substring(start, end + 1));
          if (sub is Map<String, dynamic>) {
            final result = TrimResult.fromJson(sub);
            if (kDebugMode) debugPrint('[TRIM DEBUG] Parsed JSON successfully');
            return result;
          }
        }
      } catch (_) {}
      throw GroqParseException('Failed to parse AI completion JSON string: $e');
    }

    if (resultJson is! Map<String, dynamic>) {
      throw const GroqParseException('Parsed content is not a JSON object.');
    }

    // Step 5 & 6: Safe conversion to strongly typed TrimResult
    final result = TrimResult.fromJson(resultJson);

    if (kDebugMode) {
      debugPrint('[TRIM DEBUG] Parsed JSON successfully');
    }

    return result;
  }

  /// Extracts error message from Groq's JSON error response if available.
  static String _extractErrorMessage(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
        final err = decoded['error'];
        if (err is Map<String, dynamic> && err.containsKey('message')) {
          return err['message'].toString();
        }
      }
    } catch (_) {}
    return responseBody;
  }
}
