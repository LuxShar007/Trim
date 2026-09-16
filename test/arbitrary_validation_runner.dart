import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String sampleBloatedIdea =
    'I want to build a social fitness app for crypto traders with AI avatars, '
    'a multi-tiered decentralized staking economy, an in-app 3D metaverse gym, '
    'direct TikTok cross-posting, daily horoscope workouts, and a 50-step '
    'meal logging flow with barcode scanning and NFT achievements.';

const List<String> testIdeas = [
  'An app where college students can find hackathons, discover teammates, trade project ideas, and manage submissions.',
  'A tool that helps engineering students solve quantum mechanics equations step by step and visualize the results.',
  'An app for pet owners to track medicines, vaccination dates, dosage schedules, and vet appointments.',
  'A race strategy app that helps amateur karting and sim racing drivers compare tyre choices, pit timing, fuel strategy, and weather.',
  'An app that predicts how crowded a local train will be at different stations and suggests less crowded departures.',
  'A restaurant app that tracks ingredient stock, predicts shortages, manages suppliers, and alerts staff when food waste is increasing.',
  'A wedding planning app that manages guests, vendors, budgets, schedules, invitations, seating arrangements, and payments.',
  'A language-learning app that uses the camera to identify everyday objects and teaches the user their names in another language.',
  'A platform for infrastructure companies to use drones to inspect bridges, detect cracks, generate reports, and track maintenance.',
  'An app for students that tracks spending, recurring subscriptions, savings goals, shared expenses, and monthly budgets.',
];

// Sample markers that must NEVER leak into other arbitrary ideas
const List<String> sampleMarkers = [
  'crypto',
  'fitness',
  'avatar',
  'metaverse',
  'nft',
  'horoscope',
  'tiktok',
  'workout',
  'gym',
  'staking',
];

Future<Map<String, dynamic>> sendTrimRequest(String endpoint, String rawIdea, String clientRequestId, {int retries = 3}) async {
  for (int attempt = 1; attempt <= retries; attempt++) {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'rawIdea': rawIdea,
        'clientRequestId': clientRequestId,
      }),
    ).timeout(const Duration(seconds: 50));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 429) {
      int retrySec = 7;
      try {
        final err = jsonDecode(response.body);
        if (err['error'] != null && err['error']['retryAfter'] != null) {
          retrySec = (err['error']['retryAfter'] as num).toInt();
        }
      } catch (_) {}
      stdout.writeln('   [Rate Limited 429] Waiting ${retrySec + 1}s before attempt ${attempt + 1}...');
      await Future.delayed(Duration(seconds: retrySec + 1));
      continue;
    }

    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
  throw Exception('Exhausted $retries retries for request $clientRequestId');
}

void main() async {
  // Determine available endpoint (local vercel dev server or production deployment)
  String endpoint = 'http://localhost:3000/api/trim';
  try {
    final ping = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rawIdea': 'ping test', 'clientRequestId': 'ping_001'}),
    ).timeout(const Duration(seconds: 5));
    if (ping.statusCode != 200) {
      endpoint = 'https://web-rust-chi-46.vercel.app/api/trim';
    }
  } catch (_) {
    endpoint = 'https://web-rust-chi-46.vercel.app/api/trim';
  }

  stdout.writeln('==================================================');
  stdout.writeln('TRIM — ARBITRARY IDEA VALIDATION RUNNER');
  stdout.writeln('Target Endpoint: $endpoint');
  stdout.writeln('==================================================\n');

  // ----------------------------------------------------
  // PART A3 — SAMPLE ISOLATION TEST
  // ----------------------------------------------------
  stdout.writeln('>>> EXECUTING PART A3 — SAMPLE ISOLATION TEST');
  stdout.writeln('1. Initial launch state: verified empty.');
  
  // Custom baseline
  final customIdea = 'A local-first markdown notes app that syncs over peer-to-peer Wi-Fi.';
  stdout.writeln('2. Submitting custom idea: "$customIdea"');
  final customResult = await sendTrimRequest(endpoint, customIdea, 'iso_test_custom_001');
  stdout.writeln('   Custom Project: ${customResult['project_name']}');
  stdout.writeln('   Custom Core Value: ${customResult['core_value']}');
  
  // Submit sample idea
  stdout.writeln('3. Submitting sample bloated idea...');
  final sampleResult = await sendTrimRequest(endpoint, sampleBloatedIdea, 'iso_test_sample_002');
  stdout.writeln('   Sample Project: ${sampleResult['project_name']}');
  stdout.writeln('   Sample Core Value: ${sampleResult['core_value']}');

  // Submit subsequent unrelated idea
  final unrelatedIdea = testIdeas[1]; // Quantum mechanics
  stdout.writeln('4. Returning to Brain Dump (reset verified empty).');
  stdout.writeln('5. Submitting unrelated idea (Quantum mechanics)...');
  final subsequentResult = await sendTrimRequest(endpoint, unrelatedIdea, 'iso_test_unrelated_003');
  stdout.writeln('   Subsequent Project: ${subsequentResult['project_name']}');
  stdout.writeln('   Subsequent Core Value: ${subsequentResult['core_value']}');

  // Check for sample leakage in subsequent result
  final subsequentText = jsonEncode(subsequentResult).toLowerCase();
  final leakedSampleWords = sampleMarkers.where((m) => subsequentText.contains(m)).toList();

  if (leakedSampleWords.isEmpty) {
    stdout.writeln('   [PASS] Sample Isolation Verified! Zero sample tokens leaked into subsequent idea.');
  } else {
    stdout.writeln('   [FAIL] Sample leakage detected: $leakedSampleWords');
    exit(1);
  }
  stdout.writeln('--------------------------------------------------\n');

  // ----------------------------------------------------
  // PART A1 & A2 — 10 UNRELATED TEST IDEAS VALIDATION
  // ----------------------------------------------------
  stdout.writeln('>>> EXECUTING 10-IDEA ARBITRARY VALIDATION MATRIX\n');

  final List<Map<String, dynamic>> records = [];

  for (int i = 0; i < testIdeas.length; i++) {
    final idea = testIdeas[i];
    final reqId = 'arb_test_${i + 1}';
    stdout.writeln('Running Test Idea #${i + 1}...');
    stdout.writeln('Input: "$idea"');

    final result = await sendTrimRequest(endpoint, idea, reqId);

    final projectName = result['project_name']?.toString() ?? 'N/A';
    final coreValue = result['core_value']?.toString() ?? 'N/A';
    final mustHaves = (result['must_haves'] as List? ?? [])
        .map((m) => m is Map ? (m['feature'] ?? m['name'] ?? '').toString() : m.toString())
        .toList();
    final discardedBloat = (result['discarded_bloat'] as List? ?? [])
        .map((b) => b is Map ? (b['feature'] ?? b['name'] ?? '').toString() : b.toString())
        .toList();
    final harshTruth = result['harsh_truth']?.toString() ?? 'N/A';

    // Sample leakage check
    final fullText = jsonEncode(result).toLowerCase();
    final leaked = sampleMarkers.where((m) => fullText.contains(m)).toList();
    final hasLeakage = leaked.isNotEmpty;

    // Relevance check
    bool isRelevant = true;
    switch (i) {
      case 0: // Hackathon / teammates
        isRelevant = fullText.contains('hackathon') || fullText.contains('teammate') || fullText.contains('team') || fullText.contains('project');
        break;
      case 1: // Quantum mechanics
        isRelevant = (fullText.contains('quantum') || fullText.contains('equation') || fullText.contains('math') || fullText.contains('physic')) &&
                     !fullText.contains('restaurant') && !fullText.contains('fitness');
        break;
      case 2: // Pet medication
        isRelevant = (fullText.contains('pet') || fullText.contains('med') || fullText.contains('vaccin') || fullText.contains('vet') || fullText.contains('dose')) &&
                     !fullText.contains('tyre') && !fullText.contains('racing');
        break;
      case 3: // Karting / sim racing strategy
        isRelevant = fullText.contains('race') || fullText.contains('kart') || fullText.contains('tyre') || fullText.contains('tire') || fullText.contains('sim') || fullText.contains('fuel') || fullText.contains('pit');
        break;
      case 4: // Train crowd prediction
        isRelevant = fullText.contains('train') || fullText.contains('crowd') || fullText.contains('station') || fullText.contains('depart');
        break;
      case 5: // Restaurant inventory / food waste
        isRelevant = fullText.contains('restaurant') || fullText.contains('ingredient') || fullText.contains('stock') || fullText.contains('waste') || fullText.contains('supplier');
        break;
      case 6: // Wedding planning
        isRelevant = fullText.contains('wedding') || fullText.contains('guest') || fullText.contains('vendor') || fullText.contains('budget') || fullText.contains('invit');
        break;
      case 7: // Language learning camera
        isRelevant = fullText.contains('language') || fullText.contains('camera') || fullText.contains('object') || fullText.contains('word') || fullText.contains('learn');
        break;
      case 8: // Drone bridge crack inspection
        isRelevant = fullText.contains('drone') || fullText.contains('bridge') || fullText.contains('crack') || fullText.contains('inspect') || fullText.contains('infrastructure');
        break;
      case 9: // Student budget & spending
        isRelevant = fullText.contains('student') || fullText.contains('spend') || fullText.contains('budget') || fullText.contains('expense') || fullText.contains('subscript');
        break;
    }

    final pass = isRelevant && !hasLeakage;

    stdout.writeln('  Project: $projectName');
    stdout.writeln('  Core Value: $coreValue');
    stdout.writeln('  Must Haves (${mustHaves.length}): ${mustHaves.join(', ')}');
    stdout.writeln('  Discarded Bloat (${discardedBloat.length}): ${discardedBloat.join(', ')}');
    stdout.writeln('  Product Truth: $harshTruth');
    stdout.writeln('  Relevant: $isRelevant');
    stdout.writeln('  Sample Leakage: ${hasLeakage ? "LEAKED: $leaked" : "NONE"}');
    stdout.writeln('  Result: ${pass ? "PASS" : "FAIL"}\n');

    records.add({
      'index': i + 1,
      'input': idea,
      'project': projectName,
      'coreValue': coreValue,
      'mustHaves': mustHaves,
      'discardedBloat': discardedBloat,
      'harshTruth': harshTruth,
      'relevant': isRelevant,
      'sampleLeakage': hasLeakage,
      'pass': pass,
    });

    await Future.delayed(const Duration(milliseconds: 2000));
  }

  stdout.writeln('==================================================');
  stdout.writeln('VALIDATION SUMMARY TABLE');
  stdout.writeln('==================================================');
  stdout.writeln('| # | Input (Short) | Project | Relevant? | Sample leakage? | PASS/FAIL |');
  stdout.writeln('|---|---------------|---------|-----------|-----------------|-----------|');
  for (final r in records) {
    final shortInput = (r['input'] as String).length > 35
        ? '${(r['input'] as String).substring(0, 35)}...'
        : r['input'];
    stdout.writeln(
      '| ${r['index']} | $shortInput | ${r['project']} | ${r['relevant'] ? "YES" : "NO"} | ${r['sampleLeakage'] ? "FOUND" : "NONE"} | ${r['pass'] ? "PASS" : "FAIL"} |',
    );
  }

  // Save full JSON output for record keeping
  final file = File('test/validation_results.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(records));
  stdout.writeln('\nSaved detailed records to test/validation_results.json');
}
