import 'trim_result.dart';

/// Strongly typed domain model representing a saved local Trim session.
/// Contains all fields required to completely reconstruct and reopen
/// a Verdict experience offline without invoking any LLM API.
class TrimSession {
  final String id;
  final DateTime createdAt;
  final String originalIdea;
  final String projectName;
  final String coreValue;
  final int mvpScore;
  final List<MustHave> mustHaves;
  final List<DiscardedFeature> discardedBloat;
  final List<String> buildOrder;
  final String harshTruth;
  final int totalFeatureCount;
  final int survivorCount;
  final int cutCount;
  final bool isLocked;

  const TrimSession({
    required this.id,
    required this.createdAt,
    required this.originalIdea,
    required this.projectName,
    required this.coreValue,
    required this.mvpScore,
    required this.mustHaves,
    required this.discardedBloat,
    required this.buildOrder,
    required this.harshTruth,
    required this.totalFeatureCount,
    required this.survivorCount,
    required this.cutCount,
    this.isLocked = false,
  });

  /// Factory constructor to generate a [TrimSession] from a live [TrimResult].
  factory TrimSession.fromTrimResult({
    String? id,
    DateTime? createdAt,
    required String originalIdea,
    required TrimResult result,
    bool isLocked = false,
  }) {
    final mustHaves = List<MustHave>.from(result.mustHaves);
    final discardedBloat = List<DiscardedFeature>.from(result.discardedBloat);
    final total = mustHaves.length + discardedBloat.length;
    final survivors = mustHaves.length;
    final cuts = discardedBloat.length;

    return TrimSession(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: createdAt ?? DateTime.now(),
      originalIdea: originalIdea,
      projectName: result.projectName,
      coreValue: result.coreValue,
      mvpScore: result.mvpScore,
      mustHaves: mustHaves,
      discardedBloat: discardedBloat,
      buildOrder: List<String>.from(result.buildOrder),
      harshTruth: result.harshTruth,
      totalFeatureCount: total,
      survivorCount: survivors,
      cutCount: cuts,
      isLocked: isLocked,
    );
  }

  /// Converts this saved session back into a live [TrimResult].
  TrimResult toTrimResult() {
    return TrimResult(
      projectName: projectName,
      coreValue: coreValue,
      mvpScore: mvpScore,
      mustHaves: mustHaves,
      discardedBloat: discardedBloat,
      buildOrder: buildOrder,
      harshTruth: harshTruth,
    );
  }

  /// Percentage of total features cut (0-100)
  int get percentRemoved {
    if (totalFeatureCount == 0) return 0;
    return ((cutCount / totalFeatureCount) * 100).round();
  }

  TrimSession copyWith({
    String? id,
    DateTime? createdAt,
    String? originalIdea,
    String? projectName,
    String? coreValue,
    int? mvpScore,
    List<MustHave>? mustHaves,
    List<DiscardedFeature>? discardedBloat,
    List<String>? buildOrder,
    String? harshTruth,
    int? totalFeatureCount,
    int? survivorCount,
    int? cutCount,
    bool? isLocked,
  }) {
    return TrimSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      originalIdea: originalIdea ?? this.originalIdea,
      projectName: projectName ?? this.projectName,
      coreValue: coreValue ?? this.coreValue,
      mvpScore: mvpScore ?? this.mvpScore,
      mustHaves: mustHaves ?? this.mustHaves,
      discardedBloat: discardedBloat ?? this.discardedBloat,
      buildOrder: buildOrder ?? this.buildOrder,
      harshTruth: harshTruth ?? this.harshTruth,
      totalFeatureCount: totalFeatureCount ?? this.totalFeatureCount,
      survivorCount: survivorCount ?? this.survivorCount,
      cutCount: cutCount ?? this.cutCount,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'originalIdea': originalIdea,
      'projectName': projectName,
      'coreValue': coreValue,
      'mvpScore': mvpScore,
      'mustHaves': mustHaves.map((e) => e.toJson()).toList(),
      'discardedBloat': discardedBloat.map((e) => e.toJson()).toList(),
      'buildOrder': buildOrder,
      'harshTruth': harshTruth,
      'totalFeatureCount': totalFeatureCount,
      'survivorCount': survivorCount,
      'cutCount': cutCount,
      'isLocked': isLocked,
    };
  }

  factory TrimSession.fromJson(Map<String, dynamic> json) {
    final rawMustHaves = json['mustHaves'] as List? ?? [];
    final rawBloat = json['discardedBloat'] as List? ?? [];
    final rawBuildOrder = json['buildOrder'] as List? ?? [];

    final mustHaves = rawMustHaves.map((e) => MustHave.fromJson(e)).toList();
    final discardedBloat = rawBloat.map((e) => DiscardedFeature.fromJson(e)).toList();
    final buildOrder = rawBuildOrder.map((e) => e.toString()).toList();

    final total = json['totalFeatureCount'] as int? ?? (mustHaves.length + discardedBloat.length);
    final survivors = json['survivorCount'] as int? ?? mustHaves.length;
    final cuts = json['cutCount'] as int? ?? discardedBloat.length;

    return TrimSession(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      originalIdea: json['originalIdea'] as String? ?? '',
      projectName: json['projectName'] as String? ?? 'Untitled Project',
      coreValue: json['coreValue'] as String? ?? '',
      mvpScore: json['mvpScore'] as int? ?? 85,
      mustHaves: mustHaves,
      discardedBloat: discardedBloat,
      buildOrder: buildOrder,
      harshTruth: json['harshTruth'] as String? ?? '',
      totalFeatureCount: total,
      survivorCount: survivors,
      cutCount: cuts,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  /// Formats the MVP summary into the clean Markdown document specified in Section 24.
  String toMarkdown() {
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
    if (totalFeatureCount > survivorCount) {
      buffer.writeln('$totalFeatureCount → $survivorCount');
      buffer.writeln('$percentRemoved% removed');
    } else {
      buffer.writeln('$totalFeatureCount FEATURES · FULLY FOCUSED');
      buffer.writeln('0% removed');
    }

    return buffer.toString();
  }
}
