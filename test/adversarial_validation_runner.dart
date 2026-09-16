import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const List<String> adversarialIdeas = [
  'Uber but for college students except also social networking, dating, food delivery, events, AI tutors, campus payments, NFT rewards and crypto.',
  'I want an app for my college that does everything students need.',
  'Make Instagram, Notion, Spotify and Duolingo combined but simpler.',
  'An AI robot that manages my entire engineering degree.',
  'Build a food delivery app with drone delivery, AR menus, live kitchens, loyalty NFTs, social reviews and restaurant games.',
  'A productivity app that manages tasks, email, calendar, notes, finances, fitness, sleep, relationships and shopping.',
  'Create the ultimate student app with chat, payments, exams, attendance, notes, internships, gaming, dating and events.',
  'A healthcare platform combining doctor consultations, pharmacy, fitness tracking, mental wellness, nutrition and insurance.',
  'A travel app that handles flights, hotels, maps, food, social networking, translation, payments and travel insurance.',
  'Build an AI app that replaces every tool a startup founder needs.',
];

// Markers that indicate model leakage, provider leakage, or unrelated default sample contamination
const List<String> leakageMarkers = [
  'groq',
  'gpt-oss',
  'llama',
  'openai',
  'deepseek',
  'system prompt',
  'json schema',
  'assistant:',
  'system:',
  'horoscope', // From default sample
];

Future<Map<String, dynamic>> sendTrimRequest(
  String endpoint,
  String rawIdea,
  String clientRequestId, {
  int retries = 3,
}) async {
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
      stdout.writeln('   [Rate Limited 429] Backing off for ${retrySec + 1}s before retry (attempt $attempt)...');
      await Future.delayed(Duration(seconds: retrySec + 1));
      continue;
    }

    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
  throw Exception('Exhausted $retries retries for request $clientRequestId');
}

void main() async {
  String endpoint = 'http://localhost:3000/api/trim';
  try {
    final ping = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rawIdea': 'ping', 'clientRequestId': 'ping_adv'}),
    ).timeout(const Duration(seconds: 4));
    if (ping.statusCode != 200) {
      endpoint = 'https://web-rust-chi-46.vercel.app/api/trim';
    }
  } catch (_) {
    endpoint = 'https://web-rust-chi-46.vercel.app/api/trim';
  }

  stdout.writeln('==================================================');
  stdout.writeln('TRIM — ADVERSARIAL AI VALIDATION RUNNER');
  stdout.writeln('Target Endpoint: $endpoint');
  stdout.writeln('Testing 10 Extreme Bloated / Adversarial Ideas');
  stdout.writeln('==================================================\n');

  final List<Map<String, dynamic>> records = [];

  for (int i = 0; i < adversarialIdeas.length; i++) {
    final idea = adversarialIdeas[i];
    final reqId = 'adv_test_${i + 1}';
    stdout.writeln('--------------------------------------------------');
    stdout.writeln('Running Adversarial Test #${i + 1}...');
    stdout.writeln('Input: "$idea"');

    final result = await sendTrimRequest(endpoint, idea, reqId);

    final projectName = result['project_name']?.toString().trim() ?? 'N/A';
    final coreValue = result['core_value']?.toString().trim() ?? 'N/A';
    final mustHaves = (result['must_haves'] as List? ?? [])
        .map((m) => m is Map ? (m['feature'] ?? m['name'] ?? '').toString().trim() : m.toString().trim())
        .toList();
    final discardedBloat = (result['discarded_bloat'] as List? ?? [])
        .map((b) => b is Map ? (b['feature'] ?? b['name'] ?? '').toString().trim() : b.toString().trim())
        .toList();
    final harshTruth = result['harsh_truth']?.toString().trim() ?? 'N/A';

    final fullText = jsonEncode(result).toLowerCase();

    // 1. Leakage Check: verify no system prompt, provider, or unrelated sample keywords
    final leakedWords = leakageMarkers.where((m) => fullText.contains(m)).toList();
    final bool leakageDetected = leakedWords.isNotEmpty;

    // 2. Semantic Relevance: verify project relates to user's core intent
    bool semanticRelevance = true;
    switch (i) {
      case 0: // Uber for college students + 9 bloated features
        semanticRelevance = (fullText.contains('ride') || fullText.contains('campus') || fullText.contains('transit') || fullText.contains('uber') || fullText.contains('student')) &&
            discardedBloat.isNotEmpty;
        break;
      case 1: // College app that does everything
        semanticRelevance = (fullText.contains('college') || fullText.contains('student') || fullText.contains('campus')) &&
            mustHaves.isNotEmpty;
        break;
      case 2: // Instagram + Notion + Spotify + Duolingo
        semanticRelevance = (fullText.contains('note') || fullText.contains('music') || fullText.contains('photo') || fullText.contains('learn') || fullText.contains('content') || fullText.contains('language')) &&
            discardedBloat.isNotEmpty;
        break;
      case 3: // AI robot managing entire degree
        semanticRelevance = (fullText.contains('degree') || fullText.contains('course') || fullText.contains('engineer') || fullText.contains('schedule') || fullText.contains('task') || fullText.contains('academic')) &&
            mustHaves.isNotEmpty;
        break;
      case 4: // Food delivery + drone + AR + live kitchen + NFT + games
        semanticRelevance = (fullText.contains('food') || fullText.contains('order') || fullText.contains('deliver') || fullText.contains('restaurant') || fullText.contains('meal')) &&
            discardedBloat.isNotEmpty;
        break;
      case 5: // Productivity for tasks, email, finance, sleep, relationships
        semanticRelevance = (fullText.contains('task') || fullText.contains('productiv') || fullText.contains('to-do') || fullText.contains('work')) &&
            discardedBloat.isNotEmpty;
        break;
      case 6: // Ultimate student app: chat, payments, exams, internships, dating
        semanticRelevance = (fullText.contains('student') || fullText.contains('exam') || fullText.contains('class') || fullText.contains('attend') || fullText.contains('campus')) &&
            discardedBloat.isNotEmpty;
        break;
      case 7: // Healthcare: doctor, pharmacy, fitness, mental, insurance
        semanticRelevance = (fullText.contains('health') || fullText.contains('doctor') || fullText.contains('consult') || fullText.contains('care') || fullText.contains('medic')) &&
            discardedBloat.isNotEmpty;
        break;
      case 8: // Travel: flights, hotels, maps, food, social, translation, insurance
        semanticRelevance = (fullText.contains('travel') || fullText.contains('flight') || fullText.contains('trip') || fullText.contains('hotel') || fullText.contains('booking')) &&
            discardedBloat.isNotEmpty;
        break;
      case 9: // AI app replacing every tool startup founder needs
        semanticRelevance = (fullText.contains('founder') || fullText.contains('startup') || fullText.contains('tool') || fullText.contains('pitch') || fullText.contains('task')) &&
            mustHaves.isNotEmpty;
        break;
    }

    final bool pass = semanticRelevance && !leakageDetected && mustHaves.isNotEmpty;

    stdout.writeln('  Project: $projectName');
    stdout.writeln('  Core Value: $coreValue');
    stdout.writeln('  Must Haves (${mustHaves.length}): ${mustHaves.join('; ')}');
    stdout.writeln('  Discarded Bloat (${discardedBloat.length}): ${discardedBloat.join('; ')}');
    stdout.writeln('  Product Truth: $harshTruth');
    stdout.writeln('  Semantic Relevance: $semanticRelevance');
    stdout.writeln('  Leakage Detected: ${leakageDetected ? leakedWords : "NONE"}');
    stdout.writeln('  Result: ${pass ? "PASS" : "FAIL"}\n');

    records.add({
      'index': i + 1,
      'input': idea,
      'project': projectName,
      'coreValue': coreValue,
      'mustHaves': mustHaves,
      'discardedBloat': discardedBloat,
      'productTruth': harshTruth,
      'leakageDetected': leakageDetected,
      'semanticRelevance': semanticRelevance,
      'pass': pass,
    });

    // Polite spacing between Groq requests
    await Future.delayed(const Duration(milliseconds: 2000));
  }

  stdout.writeln('==================================================');
  stdout.writeln('ADVERSARIAL VALIDATION SUMMARY TABLE');
  stdout.writeln('==================================================');
  stdout.writeln('| # | Adversarial Input | Project | Core Outcome Preserved | Bloat Cut? | Leakage? | PASS/FAIL |');
  stdout.writeln('|---|-------------------|---------|------------------------|------------|----------|-----------|');
  for (final r in records) {
    final shortInput = (r['input'] as String).length > 30
        ? '${(r['input'] as String).substring(0, 30)}...'
        : r['input'];
    stdout.writeln(
      '| ${r['index']} | $shortInput | ${r['project']} | ${r['semanticRelevance'] ? "YES" : "NO"} | ${(r['discardedBloat'] as List).isNotEmpty ? "YES (${(r['discardedBloat'] as List).length})" : "N/A"} | ${r['leakageDetected'] ? "FOUND" : "NONE"} | ${r['pass'] ? "PASS" : "FAIL"} |',
    );
  }

  // Save to test/adversarial_validation_results.json
  final file = File('test/adversarial_validation_results.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(records));
  stdout.writeln('\nSaved detailed adversarial validation records to test/adversarial_validation_results.json');
}
