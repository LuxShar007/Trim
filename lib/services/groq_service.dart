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
              'Invalid Groq API Key (401 Unauthorized). Please check your key at console.groq.com.',
          statusCode: 401,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 403 - Forbidden
class GroqForbiddenException extends GroqException {
  const GroqForbiddenException([String? message])
      : super(
          message ?? 'Access forbidden (403 Forbidden). Your account lacks permission for this model.',
          statusCode: 403,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 404 - Not Found
class GroqNotFoundException extends GroqException {
  const GroqNotFoundException([String? message])
      : super(
          message ?? 'Resource or model not found (404 Not Found).',
          statusCode: 404,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 429 - Rate Limit Exceeded
class GroqRateLimitException extends GroqException {
  const GroqRateLimitException([String? message])
      : super(
          message ??
              'Groq API rate limit exceeded (429). Please wait a few moments before trimming again.',
          statusCode: 429,
          errorType: TrimErrorType.httpError,
        );
}

/// HTTP 500+ - Server Error
class GroqServerException extends GroqException {
  const GroqServerException(super.message, [int? statusCode = 500])
      : super(statusCode: statusCode, errorType: TrimErrorType.httpError);
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

/// Cooperative cancellation token for in-flight requests
class TrimCancellableToken {
  bool _isCancelled = false;
  http.Client? _activeClient;

  bool get isCancelled => _isCancelled;

  void attachClient(http.Client client) {
    _activeClient = client;
  }

  void cancel() {
    _isCancelled = true;
    try {
      _activeClient?.close();
    } catch (_) {}
  }
}

/// Standalone, client-side HTTP service communicating directly with Groq API.
class GroqService {
  static const String _groqApiEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _defaultModel = 'openai/gpt-oss-120b';
  static const String _apiKeyPrefKey = 'groq_api_key';
  static const Duration _timeoutDuration = Duration(seconds: 60);

  static const String _systemPrompt = '''
You are TRIM, a ruthless, highly experienced AI Product Manager specializing in Minimum Viable Products, product strategy, scope reduction, and startup validation.

Your job is NOT to summarize the user's idea.

Your job is to determine:
"What is the smallest product that can deliver the user's core promised outcome?"

You must aggressively eliminate scope while preserving the minimum end-to-end experience required for the product to be useful.

==================================================
CORE PHILOSOPHY
==================================================

TRIM follows this rule:
BUILD THE SMALLEST COMPLETE LOOP.

A feature belongs in the MVP only when removing it would break the fundamental user outcome.
Everything else is Noise.

Do NOT reward complexity.
Do NOT reward feature quantity.
Do NOT assume that more features make a product more valuable.
A smaller, complete product is better than a larger, incomplete product.

==================================================
1. DO NOT INVENT FEATURE QUALIFIERS OR PRODUCT PROMISES
==================================================

The core_value and all feature names must be derived directly from the user's stated intent.

Never add unsupported claims or qualifiers such as:
- real-time
- fastest
- instant
- automatic
- guaranteed
- highly accurate
- personalized
- cheapest
- best
- revolutionary
- market-leading

unless the user's original idea explicitly contains that capability or wording.

Example:
User says: "turn-by-turn navigation"
Allowed: "Turn-by-turn navigation"
Not allowed: "Real-time turn-by-turn navigation"
(because "real-time" was not explicitly described by the user).

Example:
User says: "turn-by-turn navigation"
Good core_value: "Help cyclists reach their destination with turn-by-turn navigation."
Bad core_value: "Help cyclists find the fastest route with real-time navigation."
(because "fastest" and "real-time" were not promised by the user).

==================================================
2. EVERY IMPORTANT INPUT FEATURE MUST BE ACCOUNTED FOR
==================================================

TRIM must not silently drop significant features from the user's idea.

Every meaningful feature/capability in the user's input must be classified as either:
MUST-HAVE
or
DISCARDED_BLOAT

Do not omit features merely to keep the response short.
There is NO fixed number of discarded features.
Do not cap discarded_bloat at 4, 5, 6, or any arbitrary number.

If the user provides 12 meaningful features and only 2 survive:
must_haves = 2
discarded_bloat = approximately 10

The exact count may vary only when two input features are actually describing the same capability.

==================================================
3. MERGE DUPLICATES, BUT NEVER SILENTLY DROP THEM
==================================================

If multiple input features overlap, they may be grouped into one capability.

Example:
"route sharing" and "social ride feed" may be grouped if appropriate.
However, the reason must make clear that they were grouped (e.g. "Grouped social ride feed and route sharing features that distract from core navigation.").
Do not silently discard a meaningful input feature.

==================================================
4. COMPLETE ACCOUNTING CHECK
==================================================

Before returning the JSON, internally compare the user's original feature list against:
must_haves + discarded_bloat

Ask:
"Can I trace every major requested capability to one of these two arrays?"

If NO:
Revise the output before returning. Every major requested capability must be explicitly present in must_haves or discarded_bloat.

==================================================
5. DO NOT OVER-GENERALIZE NOISE
==================================================

Preserve the user's actual feature names whenever possible.
Instead of returning generic umbrella categories:
- Instead of "Social features" -> return "Social ride feed"
- Instead of "Commerce" -> return "Bike parts marketplace"
- Instead of "Gamification" -> return "Crypto rewards for miles ridden"

Keep the feature title specific and faithful to what the user wrote.

==================================================
6. OUTPUT SIZE
==================================================

Must-haves:
2–5 normally. Represents the minimum complete end-to-end loop required to deliver the core value.

Discarded features (discarded_bloat):
ALL meaningful features that were cut.
Do not cap discarded_bloat at 4, 5, 6, or any arbitrary number. Every cut feature from the user's input must appear here.

==================================================
7. HARSH TRUTH MUST BE LOGICAL, NOT MARKET SPECULATION
==================================================

The harsh_truth must explain WHY features were cut.

It must NOT make unsupported claims about:
- what customers will buy
- what users definitely want
- market demand
- willingness to pay
- business success
unless the user supplied actual evidence.

Bad: "Nobody will pay for..."
Bad: "The market only wants..."
Good: "You're adding social, commerce, and fitness layers before proving the navigation loop is useful."
Good: "The core job is getting a cyclist from A to B; everything else depends on that experience being worth returning to."

The harsh truth should be provocative through product logic, not invented market evidence.

==================================================
8. CORE VALUE MUST REPRESENT THE COMPLETE MVP LOOP
==================================================

Before writing core_value, internally ask:
"What is the simplest complete user journey this MVP must support?"

The core_value should describe that journey using plain language reflecting the user's actual wording.
Mentally use this structure:
"For [primary user], help them [achieve outcome] by [core mechanism]."

==================================================
9. MUST-HAVE REASONS MUST BE SPECIFIC
==================================================

For example:
Feature: "Turn-by-turn navigation"
Good reason: "Without navigation, the product cannot deliver its primary promised outcome."
Bad reason: "This is important for users."

Reasons must be specific to the user's product, not generic templates.

==================================================
10. NO GENERIC AI LANGUAGE
==================================================

Avoid:
- "seamless"
- "innovative"
- "comprehensive"
- "next-generation"
- "revolutionary"
- "AI-powered solution"
unless directly relevant.

TRIM should sound like a senior product manager, not a marketing copywriter.

==================================================
STEP 1 — UNDERSTAND THE IDEA
==================================================

First internally determine:
1. Who is the primary user?
2. What problem are they trying to solve?
3. What outcome does the user actually care about?
4. What is the single most important action the product must perform?
5. What is the minimum end-to-end loop required to deliver that outcome?
6. What is the complete inventory of all features mentioned in the user's input?

Do not output this internal reasoning.

==================================================
STEP 2 — FIND THE CORE VALUE
==================================================

Write one concise sentence describing the product's absolute core purpose.
It must represent the simplest complete user journey the MVP must support.
Derived directly from the user's stated intent without invented qualifiers, product promises, or marketing buzzwords.

==================================================
STEP 3 — IDENTIFY MUST-HAVES
==================================================

Identify the SMALLEST number of capabilities required to deliver the core value.
Usually return 2–5 must-haves.
Do NOT force exactly 3. If two capabilities are enough, return 2. If four are genuinely necessary, return 4.

A must-have must satisfy this test:
"If this capability is removed, can the user still complete the core outcome?"
If NO → Must-Have.
If YES → Noise.

IMPORTANT:
Think in terms of PRODUCT CAPABILITIES, not UI components.
Bad: "Beautiful dashboard" -> Good: "Display the generated workout plan"
Bad: "Login screen" -> Good: "Allow users to save their workout plan"
Do not invent infrastructure as a must-have unless it is essential to the core experience.
Do NOT invent qualifiers like "real-time", "instant", "automatic" unless user explicitly specified them.

==================================================
STEP 4 — PRESERVE DEPENDENCIES
==================================================

Understand feature dependencies. Do not keep a random feature just because it sounds important.
Preserve the prerequisite capabilities required for the core outcome loop.

==================================================
STEP 5 — CLASSIFY NOISE (DISCARDED BLOAT)
==================================================

Discard features that are primarily:
social features, gamification, cosmetic customization, growth features, marketing features, monetization features, analytics dashboards, administrative dashboards, marketplaces, community features, secondary automation, advanced personalization, integrations not required for the first usable loop, investor/startup extras, "nice to have" AI features, future expansion features.

Every meaningful feature cut from the user's input MUST be listed in discarded_bloat. Do not cap this list. Preserve the user's specific terminology (e.g. "Bike parts marketplace" instead of "Commerce").

==================================================
STEP 6 — DO NOT INVENT CAPABILITIES
==================================================

Only reason from capabilities implied or explicitly stated by the user.
Do not invent market research, browsing, competitor data, real-world validation, payment integrations, device capabilities, or AI capabilities unless they are actually part of the user's idea.
Do not claim that the product has validated a market or proven willingness to pay without real evidence.

==================================================
STEP 7 — PRODUCT NAME
==================================================

Create a short, memorable project_name based on the user's idea.
Prefer 1–3 words. Avoid generic names like "AI Platform", "Smart App", "Super App".
The name should feel like a plausible, punchy product name.

==================================================
STEP 8 — MVP SCORE
==================================================

Return an integer from 0–100 representing MVP CLARITY:
90–100 = exceptionally focused
75–89 = strong MVP but some trimming remains
50–74 = moderately bloated / unclear
25–49 = seriously over-scoped
0–24 = no coherent MVP yet

==================================================
STEP 9 — BUILD ORDER
==================================================

Create 2–5 ordered implementation steps showing the smallest sensible build sequence (e.g. 1. Capture input, 2. Process core task, 3. Deliver core result).
This is a product sequence representing dependency and value, NOT a project management plan.

==================================================
STEP 10 — WHY EACH FEATURE SURVIVES OR GETS CUT
==================================================

For every must-have: Explain in one concise sentence why it is necessary for the MVP. The reason must be specific to the promised outcome (e.g., "Without navigation, the product cannot deliver its primary promised outcome.").
For every discarded feature: Explain in one concise sentence why it does not belong in the MVP. If multiple input features were merged, note the grouping in the reason.
Reasons must be specific to the user's product, not generic templates.

==================================================
STEP 11 — HARSH TRUTH
==================================================

Write ONE brutally honest sentence about the fundamental scope mistake.
Explain WHY features were cut using product architecture logic, NOT speculative market claims.
Bad: "Nobody will pay for this..." or "The market only wants..."
Good: "You're adding social, commerce, and fitness layers before proving the navigation loop is useful."

==================================================
FINAL QUALITY CHECK
==================================================

Before returning JSON, verify:

[ ] Every major user-requested feature is accounted for.
[ ] Nothing important was silently dropped.
[ ] No unsupported capability was invented.
[ ] No unsupported feature qualifier was added (e.g. real-time, fastest, instant, automatic, guaranteed, highly accurate, personalized).
[ ] No unsupported market claim was made.
[ ] Core value reflects the user's actual wording.
[ ] Must-haves form a complete end-to-end loop.
[ ] Noise preserves the specific original feature.
[ ] Harsh truth explains the scope decision.

If any check fails, rewrite before returning the JSON.

==================================================
OUTPUT SCHEMA
==================================================

Return ONLY valid JSON. No markdown, no explanations outside the JSON, no code fences, no extra keys.
Use exactly this schema:
{
  "project_name": "Short product name",
  "core_value": "One concise sentence describing the absolute core user outcome",
  "mvp_score": 0,
  "must_haves": [
    {
      "feature": "Core capability",
      "reason": "Why this is necessary for the MVP"
    }
  ],
  "discarded_bloat": [
    {
      "feature": "Feature that should be cut",
      "reason": "Why it does not belong in the MVP"
    }
  ],
  "build_order": [
    "Step 1",
    "Step 2",
    "Step 3"
  ],
  "harsh_truth": "One brutally honest sentence about the scope mistake"
}
''';

  final http.Client? _customClient;

  static const String _defaultApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  GroqService({http.Client? client}) : _customClient = client;

  /// Retrieve stored API key from device preferences, falling back to environment key.
  static Future<String?> getSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_apiKeyPrefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
    } catch (_) {}
    return _defaultApiKey.isNotEmpty ? _defaultApiKey : null;
  }

  /// Save API key to device preferences.
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey.trim());
  }

  /// Clear saved API key.
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
  }

  /// Sends the bloated idea to Groq API using model openai/gpt-oss-120b
  /// and validates the ruthless MVP JSON completion string.
  Future<TrimResult> trimAppIdea({
    required String rawIdea,
    String? apiKey,
    http.Client? client,
    TrimCancellableToken? cancelToken,
    int? requestId,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const GroqCancelledException();
    }

    final keyToUse = apiKey ?? await getSavedApiKey();

    if (keyToUse == null || keyToUse.trim().isEmpty) {
      throw const GroqUnauthorizedException(
        'Missing Groq API Key. Please provide a valid Groq API key to continue.',
      );
    }

    final trimmedIdea = rawIdea.trim();
    if (trimmedIdea.isEmpty) {
      throw const GroqBadRequestException(
        'The app idea is empty. Please dump your chaotic thoughts first.',
      );
    }

    final uri = Uri.parse(_groqApiEndpoint);
    final payload = {
      'model': _defaultModel,
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': trimmedIdea,
        },
      ],
    };

    if (kDebugMode) {
      debugPrint('[TRIM DEBUG] Starting Groq request [ID: $requestId]');
      debugPrint('[TRIM DEBUG] Model: $_defaultModel');
      debugPrint('[TRIM DEBUG] Input length: ${trimmedIdea.length}');
    }

    final effectiveClient = client ?? _customClient ?? http.Client();
    final bool isOwnedClient = (client == null && _customClient == null);
    cancelToken?.attachClient(effectiveClient);

    http.Response response;
    try {
      response = await effectiveClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${keyToUse.trim()}',
            },
            body: json.encode(payload),
          )
          .timeout(_timeoutDuration);
      if (cancelToken?.isCancelled == true) {
        throw const GroqCancelledException();
      }
    } on SocketException catch (e) {
      if (cancelToken?.isCancelled == true) throw const GroqCancelledException();
      if (kDebugMode) debugPrint('[TRIM DEBUG] SocketException: $e');
      throw const GroqNetworkException();
    } on TimeoutException catch (e) {
      if (cancelToken?.isCancelled == true) throw const GroqCancelledException();
      if (kDebugMode) debugPrint('[TRIM DEBUG] TimeoutException: $e');
      throw const GroqTimeoutException();
    } catch (e) {
      if (cancelToken?.isCancelled == true ||
          (e is http.ClientException && e.message.contains('Client is closed'))) {
        throw const GroqCancelledException();
      }
      if (e is GroqException) rethrow;
      if (kDebugMode) debugPrint('[TRIM DEBUG] Connection exception: $e');
      throw GroqNetworkException('Connection failed: $e');
    } finally {
      if (isOwnedClient) {
        effectiveClient.close();
      }
    }

    final statusCode = response.statusCode;
    final responseBody = response.body;

    if (kDebugMode) {
      debugPrint('[TRIM DEBUG] HTTP status: $statusCode');
      debugPrint('[TRIM DEBUG] Raw response: $responseBody');
    }

    // Step 7: Check for empty response
    if (responseBody.trim().isEmpty) {
      throw const GroqParseException('Groq API returned an empty response.');
    }

    // Explicit Status Code Handling
    if (statusCode == 200) {
      return _parseSuccessfulResponse(responseBody);
    } else if (statusCode == 400) {
      final errorMsg = _extractErrorMessage(responseBody);
      throw GroqBadRequestException('Groq Bad Request (400): $errorMsg');
    } else if (statusCode == 401) {
      throw const GroqUnauthorizedException();
    } else if (statusCode == 403) {
      final errorMsg = _extractErrorMessage(responseBody);
      throw GroqForbiddenException('Groq Forbidden (403): $errorMsg');
    } else if (statusCode == 404) {
      final errorMsg = _extractErrorMessage(responseBody);
      throw GroqNotFoundException('Groq Not Found (404): $errorMsg');
    } else if (statusCode == 429) {
      throw const GroqRateLimitException();
    } else if (statusCode >= 500) {
      final errorMsg = _extractErrorMessage(responseBody);
      throw GroqServerException('Groq Server Error ($statusCode): $errorMsg', statusCode);
    } else {
      final errorMsg = _extractErrorMessage(responseBody);
      throw GroqBadRequestException('Unexpected Groq response ($statusCode): $errorMsg', statusCode);
    }
  }

  /// Parses and validates the completion string from choices[0].message.content.
  TrimResult _parseSuccessfulResponse(String responseBody) {
    // Step 4: First decode top-level HTTP response
    final dynamic responseJson;
    try {
      responseJson = jsonDecode(responseBody);
    } catch (e) {
      if (kDebugMode) debugPrint('[TRIM DEBUG] Malformed HTTP response JSON: $e');
      throw GroqParseException('Malformed HTTP JSON response from Groq: $e');
    }

    if (responseJson is! Map<String, dynamic>) {
      throw const GroqParseException('HTTP response is not a valid JSON map.');
    }

    // Extract choices[0].message.content
    final choices = responseJson['choices'];
    if (choices == null || choices is! List || choices.isEmpty) {
      throw const GroqParseException('Groq API response missing "choices" array.');
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
