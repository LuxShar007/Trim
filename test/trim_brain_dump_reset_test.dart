import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trim/models/trim_result.dart';
import 'package:trim/screens/brain_dump_screen.dart';
import 'package:trim/screens/trim_results_screen.dart';
import 'package:trim/screens/trim_workspace_screen.dart';
import 'package:trim/screens/trimming_screen.dart';
import 'package:trim/services/trim_voice_service.dart';
import 'package:trim/widgets/spring_button.dart';
import 'package:trim/widgets/voice_waveform.dart';

class MockTrimVoiceService implements TrimVoiceService {
  final ValueNotifier<TrimVoiceState> _stateNotifier =
      ValueNotifier<TrimVoiceState>(TrimVoiceState.idle);
  final ValueNotifier<String> _liveWordsNotifier = ValueNotifier<String>('');
  final ValueNotifier<double> _soundLevelNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<TrimVoiceError?> _errorNotifier =
      ValueNotifier<TrimVoiceError?>(null);

  final ValueNotifier<TrimVoicePermissionState> _permissionStateNotifier =
      ValueNotifier<TrimVoicePermissionState>(TrimVoicePermissionState.granted);

  void Function(String text)? onResultHandler;
  void Function(TrimVoiceError error)? onErrorHandler;

  @override
  ValueListenable<TrimVoiceState> get stateListenable => _stateNotifier;

  @override
  ValueListenable<String> get liveWordsListenable => _liveWordsNotifier;

  @override
  ValueListenable<double> get soundLevelListenable => _soundLevelNotifier;

  @override
  ValueListenable<TrimVoiceError?> get errorListenable => _errorNotifier;

  @override
  ValueListenable<TrimVoicePermissionState> get permissionStateListenable =>
      _permissionStateNotifier;

  @override
  TrimVoiceState get state => _stateNotifier.value;

  @override
  String get liveWords => _liveWordsNotifier.value;

  @override
  double get soundLevel => _soundLevelNotifier.value;

  @override
  TrimVoiceError? get currentError => _errorNotifier.value;

  @override
  TrimVoicePermissionState get permissionState => _permissionStateNotifier.value;

  @override
  String? get currentLocaleId => 'en_IN';

  @override
  bool get isOnDeviceRecognitionAvailable => false;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> startListening({
    void Function(String text)? onResult,
    void Function(TrimVoiceError error)? onError,
  }) async {
    onResultHandler = onResult;
    onErrorHandler = onError;
    _stateNotifier.value = TrimVoiceState.listening;
    return true;
  }

  void simulateSpeech(String words, {double soundLevel = 0.6}) {
    _soundLevelNotifier.value = soundLevel;
    _liveWordsNotifier.value = words;
    onResultHandler?.call(words);
  }

  void simulateError(TrimVoiceError error) {
    _errorNotifier.value = error;
    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
    onErrorHandler?.call(error);
  }

  @override
  Future<void> stopListening() async {
    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
  }

  @override
  Future<void> cancelListening() async {
    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
    _liveWordsNotifier.value = '';
  }

  @override
  void clearError() {
    _errorNotifier.value = null;
  }

  @override
  void resetLiveWords() {
    _liveWordsNotifier.value = '';
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    _liveWordsNotifier.dispose();
    _soundLevelNotifier.dispose();
    _errorNotifier.dispose();
    _permissionStateNotifier.dispose();
  }
}

void main() {
  late MockTrimVoiceService mockVoiceService;

  setUp(() {
    mockVoiceService = MockTrimVoiceService();
    TrimVoiceService.setMockInstance(mockVoiceService);
  });

  tearDown(() {
    TrimVoiceService.setMockInstance(null);
  });

  final sampleResult = TrimResult(
    projectName: 'Minimal Focus',
    coreValue: 'Distraction-free daily focus tracker',
    mvpScore: 94,
    mustHaves: [
      const MustHave(
        feature: 'One-tap daily timer',
        reason: 'Validates primary user loop',
      ),
    ],
    discardedBloat: [
      const DiscardedFeature(
        feature: 'Crypto staking streaks',
        reason: 'Premature financialization',
      ),
    ],
    buildOrder: ['01. Daily timer engine'],
    harshTruth: 'Ship the core loop first.',
  );

  group('TRIM — Brain Dump Idea Reset & Transient State Matrix', () {
    testWidgets('TEST 1: Fresh Brain Dump starts empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('What are you building?'), findsOneWidget);
      expect(find.text('0 chars'), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      final springButton =
          tester.widget<SpringButton>(find.byType(SpringButton));
      expect(springButton.isEnabled, isFalse);
    });

    testWidgets('TEST 2: Tap Insert Bloated Idea Sample. Text appears.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      final sampleTrigger = find.text('Insert Bloated Idea Sample');
      expect(sampleTrigger, findsOneWidget);

      await tester.tap(sampleTrigger);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isNotEmpty);
      expect(find.text('0 chars'), findsNothing);

      final springButton =
          tester.widget<SpringButton>(find.byType(SpringButton));
      expect(springButton.isEnabled, isTrue);
    });

    testWidgets('TEST 3: Submit sample. Return from TrimmingScreen. Composer is empty.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Insert sample
      await tester.tap(find.text('Insert Bloated Idea Sample'));
      await tester.pump();

      // Submit
      await tester.tap(find.text('TRIM THE FAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // liquid transition
      await tester.pump(const Duration(milliseconds: 500)); // push transition

      expect(find.byType(TrimmingScreen), findsOneWidget);

      // Return back to BrainDumpScreen
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify composer is empty
      expect(find.byType(TrimmingScreen), findsNothing);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('0 chars'), findsOneWidget);
      expect(find.text('What are you building?'), findsOneWidget);
    });

    testWidgets('TEST 4: Type custom idea. Submit. Return. Composer is empty.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Type custom idea
      const customIdea = 'A super clean habit tracker with no social feed.';
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, customIdea);
      await tester.pump();

      expect(find.text('${customIdea.length} chars'), findsOneWidget);

      // Submit
      await tester.tap(find.text('TRIM THE FAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // liquid transition
      await tester.pump(const Duration(milliseconds: 500)); // push transition

      expect(find.byType(TrimmingScreen), findsOneWidget);

      // Return
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // Composer must be empty
      expect(find.byType(TrimmingScreen), findsNothing);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('0 chars'), findsOneWidget);
    });

    testWidgets('TEST 5: Voice transcript. Submit. Return. Composer is empty.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to SPEAK
      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      // Start listening
      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockVoiceService.simulateSpeech('Spoken high speed product vision');
      await tester.pump(const Duration(milliseconds: 100));

      // Stop listening
      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Spoken high speed product vision'), findsOneWidget);

      // Submit
      await tester.tap(find.text('TRIM THE FAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // liquid transition
      await tester.pump(const Duration(milliseconds: 500)); // push transition

      expect(find.byType(TrimmingScreen), findsOneWidget);

      // Return
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // Composer must be empty and back to type mode
      expect(find.byType(TrimmingScreen), findsNothing);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('0 chars'), findsOneWidget);
    });

    testWidgets('TEST 6: Tap TRIM ANOTHER IDEA. Composer is empty.',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(
        home: BrainDumpScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Enter idea and submit
      await tester.enterText(
          find.byType(TextField), 'An app with everything included.');
      await tester.pump();

      await tester.tap(find.text('TRIM THE FAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // liquid transition
      await tester.pump(const Duration(milliseconds: 500)); // push transition

      // Replace TrimmingScreen with TrimResultsScreen
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TrimResultsScreen(result: sampleResult),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TrimResultsScreen), findsOneWidget);

      // On Results Screen: Tap TRIM ANOTHER IDEA
      final trimAnotherButton = find.text('TRIM ANOTHER IDEA');
      expect(trimAnotherButton, findsOneWidget);

      await tester.tap(trimAnotherButton);
      await tester.pump();
      // Allow exit controller (250ms) + pop transition (300ms) to complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      // Returned to BrainDumpScreen: verify completely blank input
      expect(find.byType(TrimResultsScreen), findsNothing);
      expect(find.text('What are you building?'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('0 chars'), findsOneWidget);
    });

    testWidgets(
        'TEST 7: Navigate to Workspace and back. Composer remains empty unless the user intentionally entered a new idea.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0 chars'), findsOneWidget);

      // Tap Workspace folder icon
      final folderButton = find.byIcon(Icons.folder_outlined);
      expect(folderButton, findsOneWidget);

      await tester.tap(folderButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TrimWorkspaceScreen), findsOneWidget);

      // Return back
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BrainDumpScreen), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('0 chars'), findsOneWidget);
    });

    testWidgets('TEST 8: Sample button after reset still works normally.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Insert, submit, return
      await tester.tap(find.text('Insert Bloated Idea Sample'));
      await tester.pump();

      await tester.tap(find.text('TRIM THE FAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify empty
      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Tap sample button again
      await tester.tap(find.text('Insert Bloated Idea Sample'));
      await tester.pump();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isNotEmpty);
      expect(find.text('0 chars'), findsNothing);
    });

    testWidgets('TEST 9: Character counter returns to: 0 chars',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(
          find.byType(TextField), 'Testing character reset capability.');
      await tester.pump();

      expect(find.text('35 chars'), findsOneWidget);

      await tester.tap(find.text('TRIM THE FAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('0 chars'), findsOneWidget);
    });

    testWidgets('TEST 10: No stale voice error remains.',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      mockVoiceService.simulateError(TrimVoiceError.notAvailable);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(TrimVoiceError.notAvailable.displayMessage), findsOneWidget);

      // Explicit reset
      final dynamic brainDumpState =
          tester.state(find.byType(BrainDumpScreen));
      brainDumpState.resetForNewIdea();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text(TrimVoiceError.notAvailable.displayMessage), findsNothing);
      expect(find.text('0 chars'), findsOneWidget);
    });
  });
}
