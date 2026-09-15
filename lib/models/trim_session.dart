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
  final String productTruth;
  final int totalFeatureCount;
  final int survivorCount;
  final int cutCount;
  final int scopeReduction;
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
    required this.productTruth,
    required this.totalFeatureCount,
    required this.survivorCount,
    required this.cutCount,
    required this.scopeReduction,
    this.isLocked = false,
  });

  /// Backward compatibility alias for harshTruth
  String get harshTruth => productTruth;

  /// Backward compatibility alias for percentRemoved
  int get percentRemoved => scopeReduction;

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
    final reduction = total > 0 ? ((cuts / total) * 100).round() : 0;

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
      productTruth: result.harshTruth,
      totalFeatureCount: total,
      survivorCount: survivors,
      cutCount: cuts,
      scopeReduction: reduction,
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
      harshTruth: productTruth,
    );
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
    String? productTruth,
    int? totalFeatureCount,
    int? survivorCount,
    int? cutCount,
    int? scopeReduction,
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
      productTruth: productTruth ?? this.productTruth,
      totalFeatureCount: totalFeatureCount ?? this.totalFeatureCount,
      survivorCount: survivorCount ?? this.survivorCount,
      cutCount: cutCount ?? this.cutCount,
      scopeReduction: scopeReduction ?? this.scopeReduction,
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
      'productTruth': productTruth,
      'harshTruth': productTruth, // for backward compatibility
      'totalFeatureCount': totalFeatureCount,
      'survivorCount': survivorCount,
      'cutCount': cutCount,
      'scopeReduction': scopeReduction,
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
    final reduction = json['scopeReduction'] as int? ??
        (total > 0 ? ((cuts / total) * 100).round() : 0);

    final truth = (json['productTruth'] ?? json['harshTruth']) as String? ?? '';

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
      productTruth: truth,
      totalFeatureCount: total,
      survivorCount: survivors,
      cutCount: cuts,
      scopeReduction: reduction,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  /// Formats the MVP summary into the clean Markdown document specified for EXPORT MVP.
  String toMarkdown() => toTrimResult().toMarkdown(isLocked: isLocked);
}
