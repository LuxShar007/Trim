import 'dart:convert';

/// Exception thrown when the API response cannot be validated or parsed.
class TrimParseException implements Exception {
  final String message;
  final String? missingField;

  const TrimParseException(this.message, [this.missingField]);

  @override
  String toString() => message;
}

/// Represents an essential core feature and the reason it is necessary.
class MustHave {
  final String feature;
  final String reason;

  const MustHave({
    required this.feature,
    required this.reason,
  });

  /// Validates that both feature and reason exist and are non-empty.
  factory MustHave.fromJson(dynamic json) {
    if (json is Map) {
      final feat = (json['feature'] ?? json['name'] ?? json['title'] ?? '').toString().trim();
      final rsn = (json['reason'] ?? json['description'] ?? '').toString().trim();
      if (feat.isEmpty || feat.toLowerCase() == 'null') {
        throw const TrimParseException('MustHave feature title cannot be empty', 'feature');
      }
      if (rsn.isEmpty || rsn.toLowerCase() == 'null') {
        throw const TrimParseException('MustHave feature reason cannot be empty', 'reason');
      }
      return MustHave(feature: feat, reason: rsn);
    }
    throw const TrimParseException('MustHave item must be a JSON object with "feature" and "reason"', 'must_haves');
  }

  Map<String, dynamic> toJson() => {
    'feature': feature,
    'reason': reason,
  };

  @override
  String toString() => feature;

  @override
  bool operator ==(Object other) {
    if (other is String) return feature == other;
    if (other is MustHave) return feature == other.feature && reason == other.reason;
    return false;
  }

  @override
  int get hashCode => Object.hash(feature, reason);
}

/// Represents a rejected bloat feature and the brutal justification for its removal.
class DiscardedFeature {
  final String feature;
  final String reason;

  const DiscardedFeature({
    required this.feature,
    required this.reason,
  });

  /// Validates that both feature and reason exist and are non-empty.
  factory DiscardedFeature.fromJson(dynamic json) {
    if (json is Map) {
      final feat = (json['feature'] ?? json['name'] ?? json['title'] ?? '').toString().trim();
      final rsn = (json['reason'] ?? json['description'] ?? '').toString().trim();
      if (feat.isEmpty || feat.toLowerCase() == 'null') {
        throw const TrimParseException('DiscardedFeature title cannot be empty', 'feature');
      }
      if (rsn.isEmpty || rsn.toLowerCase() == 'null') {
        throw const TrimParseException('DiscardedFeature reason cannot be empty', 'reason');
      }
      return DiscardedFeature(feature: feat, reason: rsn);
    }
    throw const TrimParseException('DiscardedFeature item must be a JSON object with "feature" and "reason"', 'discarded_bloat');
  }

  Map<String, dynamic> toJson() => {
    'feature': feature,
    'reason': reason,
  };

  @override
  String toString() => feature;

  @override
  bool operator ==(Object other) {
    if (other is String) return feature == other;
    if (other is DiscardedFeature) return feature == other.feature && reason == other.reason;
    return false;
  }

  @override
  int get hashCode => Object.hash(feature, reason);
}

/// Backward compatibility alias
typedef TrimFeature = MustHave;

/// Strongly typed Dart model representing the ruthless product management triage output.
class TrimResult {
  final String projectName;
  final String coreValue;
  final int mvpScore;
  final List<MustHave> mustHaves;
  final List<DiscardedFeature> discardedBloat;
  final List<String> buildOrder;
  final String harshTruth;

  const TrimResult({
    required this.projectName,
    required this.coreValue,
    this.mvpScore = 85,
    required this.mustHaves,
    required this.discardedBloat,
    this.buildOrder = const [],
    required this.harshTruth,
  });

  /// Factory constructor that strictly validates every field from Groq API response.
  /// Throws [TrimParseException] if any required field is missing or invalid.
  factory TrimResult.fromJson(Map<String, dynamic> json) {
    // 1. Validate project_name
    final rawProjectName = json['project_name'];
    if (rawProjectName == null || rawProjectName.toString().trim().isEmpty) {
      throw const TrimParseException('Missing or empty "project_name" in AI PM response.', 'project_name');
    }
    final projectName = rawProjectName.toString().trim();
    if (projectName.toLowerCase() == 'null') {
      throw const TrimParseException('Invalid "project_name" value in AI PM response.', 'project_name');
    }

    // 2. Validate core_value
    final rawCoreValue = json['core_value'];
    if (rawCoreValue == null || rawCoreValue.toString().trim().isEmpty) {
      throw const TrimParseException('Missing or empty "core_value" in AI PM response.', 'core_value');
    }
    final coreValue = rawCoreValue.toString().trim();
    if (coreValue.toLowerCase() == 'null') {
      throw const TrimParseException('Invalid "core_value" value in AI PM response.', 'core_value');
    }

    // 3. Validate mvp_score
    final rawScore = json['mvp_score'];
    if (rawScore == null) {
      throw const TrimParseException('Missing "mvp_score" in AI PM response.', 'mvp_score');
    }
    final int score;
    if (rawScore is num) {
      score = rawScore.toInt().clamp(0, 100);
    } else if (rawScore is String && int.tryParse(rawScore) != null) {
      score = int.parse(rawScore).clamp(0, 100);
    } else {
      throw const TrimParseException('Invalid "mvp_score" format; expected integer 0-100.', 'mvp_score');
    }

    // 4. Validate must_haves
    final rawMustHaves = json['must_haves'];
    if (rawMustHaves == null || rawMustHaves is! List || rawMustHaves.isEmpty) {
      throw const TrimParseException('Missing or empty "must_haves" list in AI PM response.', 'must_haves');
    }
    final mustHaves = rawMustHaves
        .map((item) => MustHave.fromJson(item))
        .toList();

    // 5. Validate discarded_bloat
    final rawBloat = json['discarded_bloat'];
    if (rawBloat == null || rawBloat is! List) {
      throw const TrimParseException('Missing "discarded_bloat" list in AI PM response.', 'discarded_bloat');
    }
    final discardedBloat = rawBloat
        .map((item) => DiscardedFeature.fromJson(item))
        .toList();

    // 6. Validate build_order
    final rawBuildOrder = json['build_order'];
    if (rawBuildOrder == null || rawBuildOrder is! List || rawBuildOrder.isEmpty) {
      throw const TrimParseException('Missing or empty "build_order" list in AI PM response.', 'build_order');
    }
    final buildOrder = rawBuildOrder
        .map((item) => item?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toList();
    if (buildOrder.isEmpty) {
      throw const TrimParseException('"build_order" contains no valid steps in AI PM response.', 'build_order');
    }

    // 7. Validate harsh_truth
    final rawHarshTruth = json['harsh_truth'];
    if (rawHarshTruth == null || rawHarshTruth.toString().trim().isEmpty) {
      throw const TrimParseException('Missing or empty "harsh_truth" in AI PM response.', 'harsh_truth');
    }
    final harshTruth = rawHarshTruth.toString().trim();
    if (harshTruth.toLowerCase() == 'null') {
      throw const TrimParseException('Invalid "harsh_truth" value in AI PM response.', 'harsh_truth');
    }

    return TrimResult(
      projectName: projectName,
      coreValue: coreValue,
      mvpScore: score,
      mustHaves: mustHaves,
      discardedBloat: discardedBloat,
      buildOrder: buildOrder,
      harshTruth: harshTruth,
    );
  }

  /// Clean markdown fences from raw JSON string if present
  static String cleanRawJson(String rawJson) {
    var cleaned = rawJson.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  /// Parses raw JSON string into [TrimResult].
  factory TrimResult.fromRawJson(String rawJson) {
    final cleaned = cleanRawJson(rawJson);
    final dynamic decoded;
    try {
      decoded = json.decode(cleaned);
    } catch (e) {
      // Try substring from first { to last }
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        try {
          final subDecoded = json.decode(cleaned.substring(start, end + 1));
          if (subDecoded is Map<String, dynamic>) {
            return TrimResult.fromJson(subDecoded);
          }
        } catch (_) {}
      }
      throw TrimParseException('Failed to parse AI response as JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const TrimParseException('AI response content is not a valid JSON object.');
    }
    return TrimResult.fromJson(decoded);
  }

  /// Converts this [TrimResult] into a JSON map matching the schema.
  Map<String, dynamic> toJson() {
    return {
      'project_name': projectName,
      'core_value': coreValue,
      'mvp_score': mvpScore,
      'must_haves': mustHaves.map((e) => e.toJson()).toList(),
      'discarded_bloat': discardedBloat.map((e) => e.toJson()).toList(),
      'build_order': buildOrder,
      'harsh_truth': harshTruth,
    };
  }

  /// Formats the MVP summary into the clean Markdown document specified in Section 24.
  String toMarkdown({bool isLocked = false}) {
    final buffer = StringBuffer();
    buffer.writeln('# $projectName');
    buffer.writeln();
    buffer.writeln('## Core Value');
    buffer.writeln(coreValue);
    buffer.writeln();
    buffer.writeln('## MVP');
    buffer.writeln();
    buffer.writeln('### Must-Haves');
    for (var i = 0; i < mustHaves.length; i++) {
      final item = mustHaves[i];
      buffer.writeln('${i + 1}. **${item.feature}**');
      if (item.reason.isNotEmpty) {
        buffer.writeln('   _${item.reason}_');
      }
    }
    buffer.writeln();
    buffer.writeln('### Explicitly Cut');
    if (discardedBloat.isEmpty) {
      buffer.writeln('_None. Idea is fully focused._');
    } else {
      for (final item in discardedBloat) {
        buffer.writeln('- ~~${item.feature}~~: _${item.reason}_');
      }
    }
    buffer.writeln();
    buffer.writeln('## Build First');
    for (var i = 0; i < buildOrder.length; i++) {
      buffer.writeln('${i + 1}. ${buildOrder[i]}');
    }
    buffer.writeln();
    buffer.writeln('## Product Truth');
    buffer.writeln();
    buffer.writeln(harshTruth);
    buffer.writeln();
    buffer.writeln('## MVP Status');
    buffer.writeln(isLocked ? 'Locked' : 'Unlocked');
    buffer.writeln();
    buffer.writeln('## Scope Reduction');
    final total = mustHaves.length + discardedBloat.length;
    final survivors = mustHaves.length;
    if (total > survivors) {
      final percentRemoved = ((discardedBloat.length / total) * 100).round();
      buffer.writeln('$total → $survivors');
      buffer.writeln('$percentRemoved% removed');
    } else {
      buffer.writeln('$total FEATURES · FULLY FOCUSED');
      buffer.writeln('0% removed');
    }

    return buffer.toString();
  }
}
