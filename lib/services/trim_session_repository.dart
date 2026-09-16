import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/trim_session.dart';

/// Local structured repository for [TrimSession] entities.
/// Implements local-first personal workspace persistence without cloud or authentication.
class TrimSessionRepository {
  static final TrimSessionRepository instance = TrimSessionRepository();

  static const String boxName = 'trim_sessions_v1';
  Box<dynamic>? _box;
  bool _initialized = false;

  TrimSessionRepository({Box<dynamic>? box}) : _box = box {
    if (box != null) {
      _initialized = true;
    }
  }

  /// Injects or resets a test box for isolated testing environments.
  @visibleForTesting
  void setTestBox(Box<dynamic>? box) {
    _box = box;
    _initialized = box != null && box.isOpen;
  }

  /// Initializes Hive storage if not already initialized.
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;

    try {
      if (!kIsWeb) {
        await Hive.initFlutter();
      }
      _box = await Hive.openBox(boxName);
      _initialized = true;
    } catch (e) {
      debugPrint('[TrimSessionRepository] Initialization note: $e');
      // If already initialized in test or web, re-attempt openBox
      _box = await Hive.openBox(boxName);
      _initialized = true;
    }
  }

  /// Ensures box is accessible.
  Future<Box<dynamic>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Upsert a [TrimSession] into the local database.
  Future<void> saveSession(TrimSession session) async {
    final box = await _ensureBox();
    await box.put(session.id, session.toJson());
  }

  /// Retrieve a specific session by [id].
  Future<TrimSession?> getSession(String id) async {
    final box = await _ensureBox();
    final raw = box.get(id);
    if (raw == null) return null;
    if (raw is Map) {
      return TrimSession.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  /// Returns all saved sessions in reverse chronological order (newest first).
  Future<List<TrimSession>> getAllSessions() async {
    final box = await _ensureBox();
    final List<TrimSession> sessions = [];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null && raw is Map) {
        try {
          sessions.add(TrimSession.fromJson(Map<String, dynamic>.from(raw)));
        } catch (e) {
          debugPrint('[TrimSessionRepository] Error deserializing session $key: $e');
        }
      }
    }

    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  /// Update the locked status for a session.
  Future<void> setLocked(String id, bool isLocked) async {
    final session = await getSession(id);
    if (session != null) {
      final updated = session.copyWith(isLocked: isLocked);
      await saveSession(updated);
    }
  }

  /// Persists generated Build Desk markdown artifacts for a specific session.
  Future<void> saveArtifacts(String id, Map<String, String> artifacts) async {
    final session = await getSession(id);
    if (session != null) {
      final updated = session.copyWith(buildDeskArtifacts: artifacts);
      await saveSession(updated);
    }
  }

  /// Atomically updates lock status and persists generated Build Desk artifacts.
  Future<void> setLockedAndArtifacts(
    String id,
    bool isLocked,
    Map<String, String>? artifacts,
  ) async {
    final session = await getSession(id);
    if (session != null) {
      final updated = session.copyWith(
        isLocked: isLocked,
        buildDeskArtifacts: artifacts ?? session.buildDeskArtifacts,
      );
      await saveSession(updated);
    }
  }

  /// Delete a saved session.
  Future<void> deleteSession(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
  }

  /// Clear all sessions (used for testing or workspace reset).
  Future<void> clear() async {
    final box = await _ensureBox();
    await box.clear();
  }

  // --- Dynamic Workspace Statistics ---

  /// Computes workspace metrics across all saved sessions.
  Future<TrimWorkspaceStats> getWorkspaceStats() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) {
      return const TrimWorkspaceStats(
        ideasTrimmed: 0,
        featuresCut: 0,
        avgScopeRemovedPercent: 0,
      );
    }

    int totalFeaturesAll = 0;
    int totalCutAll = 0;

    for (final s in sessions) {
      totalFeaturesAll += s.totalFeatureCount;
      totalCutAll += s.cutCount;
    }

    final avgRemoved = totalFeaturesAll > 0
        ? ((totalCutAll / totalFeaturesAll) * 100).round()
        : 0;

    return TrimWorkspaceStats(
      ideasTrimmed: sessions.length,
      featuresCut: totalCutAll,
      avgScopeRemovedPercent: avgRemoved,
    );
  }
}

/// Dynamic workspace metrics aggregate.
class TrimWorkspaceStats {
  final int ideasTrimmed;
  final int featuresCut;
  final int avgScopeRemovedPercent;

  const TrimWorkspaceStats({
    required this.ideasTrimmed,
    required this.featuresCut,
    required this.avgScopeRemovedPercent,
  });
}
