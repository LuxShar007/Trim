import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utilities/haptics_util.dart';
import '../models/trim_result.dart';

/// The 4 structured specification documents for the laptop Build Desk handoff.
class OfficeKitHandoffBundle {
  final String projectName;
  final String mvpSpec;
  final String buildOrder;
  final String cutFeatures;
  final String productTruth;

  const OfficeKitHandoffBundle({
    required this.projectName,
    required this.mvpSpec,
    required this.buildOrder,
    required this.cutFeatures,
    required this.productTruth,
  });

  /// Map of file names to their markdown content.
  Map<String, String> get files => {
        'MVP_SPEC.md': mvpSpec,
        'BUILD_ORDER.md': buildOrder,
        'CUT_FEATURES.md': cutFeatures,
        'PRODUCT_TRUTH.md': productTruth,
      };

  /// Clean combined handoff text optimized for Office Kit shared clipboard sync.
  String toCombinedHandoff() {
    final buffer = StringBuffer();
    buffer.writeln('# $projectName — BUILD DESK HANDOFF');
    buffer.writeln('Prepared by TRIM for Laptop Implementation');
    buffer.writeln();
    buffer.writeln('========================================');
    buffer.writeln('FILE: MVP_SPEC.md');
    buffer.writeln('========================================');
    buffer.writeln(mvpSpec);
    buffer.writeln();
    buffer.writeln('========================================');
    buffer.writeln('FILE: BUILD_ORDER.md');
    buffer.writeln('========================================');
    buffer.writeln(buildOrder);
    buffer.writeln();
    buffer.writeln('========================================');
    buffer.writeln('FILE: CUT_FEATURES.md');
    buffer.writeln('========================================');
    buffer.writeln(cutFeatures);
    buffer.writeln();
    buffer.writeln('========================================');
    buffer.writeln('FILE: PRODUCT_TRUTH.md');
    buffer.writeln('========================================');
    buffer.writeln(productTruth);
    return buffer.toString();
  }
}

/// Service managing the phone -> laptop handoff via actual available Office Kit
/// capabilities (shared system clipboard and native cross-device file/sheet transfer).
class OfficeKitService {
  OfficeKitService._();
  static final OfficeKitService instance = OfficeKitService._();

  /// Formats the 4 structured handoff markdown specifications strictly containing:
  /// - project name
  /// - core value
  /// - must-haves
  /// - discarded bloat
  /// - build order
  /// - product truth
  /// - scope reduction
  ///
  /// Strictly excludes:
  /// - API keys, Groq, model names, credentials, technical telemetry.
  OfficeKitHandoffBundle createHandoff(TrimResult result) {
    final total = result.mustHaves.length + result.discardedBloat.length;
    final survivors = result.mustHaves.length;
    final int percentRemoved = total > 0
        ? ((result.discardedBloat.length / total) * 100).round()
        : 0;

    // 1. MVP_SPEC.md
    final specBuf = StringBuffer();
    specBuf.writeln('# ${result.projectName} — MVP SPECIFICATION');
    specBuf.writeln();
    specBuf.writeln('## Core Value');
    specBuf.writeln(result.coreValue);
    specBuf.writeln();
    specBuf.writeln('## Must-Haves');
    for (var i = 0; i < result.mustHaves.length; i++) {
      final item = result.mustHaves[i];
      specBuf.writeln('${i + 1}. **${item.feature}**');
      if (item.reason.isNotEmpty) {
        specBuf.writeln('   _${item.reason}_');
      }
    }
    specBuf.writeln();
    specBuf.writeln('## Scope');
    if (total > survivors) {
      specBuf.writeln('$total → $survivors SURVIVE');
      specBuf.writeln('$percentRemoved% SCOPE REMOVED');
    } else {
      specBuf.writeln('$total FEATURES · FULLY FOCUSED');
      specBuf.writeln('0% SCOPE REMOVED');
    }
    specBuf.writeln();
    specBuf.writeln('## Status');
    specBuf.writeln('MVP LOCKED');

    // 2. BUILD_ORDER.md
    final orderBuf = StringBuffer();
    orderBuf.writeln('# ${result.projectName} — BUILD ORDER');
    orderBuf.writeln();
    orderBuf.writeln('## Implementation Sequence');
    if (result.buildOrder.isEmpty) {
      for (var i = 0; i < result.mustHaves.length; i++) {
        orderBuf.writeln('${(i + 1).toString().padLeft(2, '0')}. ${result.mustHaves[i].feature}');
      }
    } else {
      for (var i = 0; i < result.buildOrder.length; i++) {
        orderBuf.writeln('${(i + 1).toString().padLeft(2, '0')}. ${result.buildOrder[i]}');
      }
    }
    orderBuf.writeln();
    orderBuf.writeln('## Directive');
    orderBuf.writeln('Implement step 01 completely and verify before moving to step 02.');

    // 3. CUT_FEATURES.md
    final cutBuf = StringBuffer();
    cutBuf.writeln('# ${result.projectName} — CUT FEATURES (THE NOISE)');
    cutBuf.writeln();
    cutBuf.writeln('## Discarded Bloat & Rejection Reasons');
    if (result.discardedBloat.isEmpty) {
      cutBuf.writeln('_None. Idea was submitted fully focused._');
    } else {
      for (final item in result.discardedBloat) {
        cutBuf.writeln('- ~~${item.feature}~~: _${item.reason}_');
      }
    }
    cutBuf.writeln();
    cutBuf.writeln('## Rule');
    cutBuf.writeln('Do NOT implement these features in the initial release.');

    // 4. PRODUCT_TRUTH.md
    final truthBuf = StringBuffer();
    truthBuf.writeln('# ${result.projectName} — PRODUCT TRUTH');
    truthBuf.writeln();
    truthBuf.writeln('## Focus Constraint');
    truthBuf.writeln(result.harshTruth);

    return OfficeKitHandoffBundle(
      projectName: result.projectName,
      mvpSpec: specBuf.toString().trim(),
      buildOrder: orderBuf.toString().trim(),
      cutFeatures: cutBuf.toString().trim(),
      productTruth: truthBuf.toString().trim(),
    );
  }

  /// Sends the structured handoff bundle to the Build Desk laptop using available
  /// Office Kit capabilities:
  /// 1. Shared System Clipboard (instant cross-device paste on laptop)
  /// 2. Native Cross-Device Share Sheet (Direct PC Connect / Nearby / File transfer)
  Future<bool> sendToBuildDesk({
    required BuildContext context,
    required TrimResult result,
  }) async {
    final bundle = createHandoff(result);
    final combinedMarkdown = bundle.toCombinedHandoff();

    // 1. Calculate share position origin synchronously before any async gap
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    // 2. Synchronize to shared system clipboard (Office Kit / PC Connect real-time clipboard sync)
    await Clipboard.setData(ClipboardData(text: combinedMarkdown));
    HapticsUtil.mediumImpact();

    // 3. Trigger native share sheet for direct PC file/document transfer
    await SharePlus.instance.share(
      ShareParams(
        text: combinedMarkdown,
        subject: '${bundle.projectName} — Build Desk Handoff (4 Specs)',
        sharePositionOrigin: origin,
      ),
    );

    return true;
  }
}
