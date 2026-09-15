import 'package:http/http.dart' as http;
import '../models/trim_result.dart';
import 'groq_service.dart';

/// Domain engine / repository mediating between the presentation UI layer
/// and the low-level client-side GroqService HTTP client.
class TrimEngine {
  final GroqService _service;

  /// Development-only test prompt as mandated by test specifications
  static const String testStudentIdea =
      'An app where students upload lecture recordings, get AI summaries, generate quizzes, '
      'track progress, compete on leaderboards, follow friends, customize profiles, '
      'receive notifications, and subscribe to premium plans.';

  TrimEngine({GroqService? service}) : _service = service ?? GroqService();

  /// Executes ruthless MVP triage on raw input text using Groq API (openai/gpt-oss-120b).
  Future<TrimResult> trimIdea({
    required String rawIdea,
    String? apiKey,
    http.Client? client,
    TrimCancellableToken? cancelToken,
    int? requestId,
    int? maxRetries,
    Duration? initialBackoff,
  }) async {
    return await _service.trimAppIdea(
      rawIdea: rawIdea,
      apiKey: apiKey,
      client: client,
      cancelToken: cancelToken,
      requestId: requestId,
      maxRetries: maxRetries,
      initialBackoff: initialBackoff,
    );
  }

  /// Development-only test pipeline executing with the exact test input
  Future<TrimResult> testStudentPipeline({String? apiKey}) async {
    return await trimIdea(
      rawIdea: testStudentIdea,
      apiKey: apiKey,
    );
  }
}
