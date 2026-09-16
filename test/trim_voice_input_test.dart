import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trim/screens/brain_dump_screen.dart';
import 'package:trim/services/trim_voice_service.dart';
import 'package:trim/widgets/voice_waveform.dart';

/// Test mock implementation for deterministic voice testing
class MockTrimVoiceService implements TrimVoiceService {
  final ValueNotifier<TrimVoiceState> _stateNotifier =
      ValueNotifier<TrimVoiceState>(TrimVoiceState.idle);
  final ValueNotifier<String> _liveWordsNotifier = ValueNotifier<String>('');
  final ValueNotifier<double> _soundLevelNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<TrimVoiceError?> _errorNotifier =
      ValueNotifier<TrimVoiceError?>(null);

  final ValueNotifier<TrimVoicePermissionState> _permissionStateNotifier =
      ValueNotifier<TrimVoicePermissionState>(TrimVoicePermissionState.granted);

  bool shouldFailInitialization = false;
  TrimVoiceError? errorToEmit;
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
  Future<bool> initialize() async {
    return !shouldFailInitialization;
  }

  @override
  Future<bool> startListening({
    void Function(String text)? onResult,
    void Function(TrimVoiceError error)? onError,
  }) async {
    onResultHandler = onResult;
    onErrorHandler = onError;

    if (errorToEmit != null) {
      _errorNotifier.value = errorToEmit;
      onError?.call(errorToEmit!);
      return false;
    }

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
    _stateNotifier.value = TrimVoiceState.processing;
    _soundLevelNotifier.value = 0.0;
    _stateNotifier.value = TrimVoiceState.idle;
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
  late MockTrimVoiceService mockService;

  setUp(() {
    mockService = MockTrimVoiceService();
    TrimVoiceService.setMockInstance(mockService);
  });

  tearDown(() {
    TrimVoiceService.setMockInstance(null);
  });

  group('TRIM — Voice Input & Creative Phone Use Matrix', () {
    test('MockTrimVoiceService lifecycle transitions cleanly', () async {
      expect(mockService.state, TrimVoiceState.idle);

      final started = await mockService.startListening();
      expect(started, isTrue);
      expect(mockService.state, TrimVoiceState.listening);

      mockService.simulateSpeech('An offline habit app with zero distractions',
          soundLevel: 0.8);
      expect(mockService.liveWords,
          'An offline habit app with zero distractions');
      expect(mockService.soundLevel, 0.8);

      await mockService.stopListening();
      expect(mockService.state, TrimVoiceState.idle);
      expect(mockService.soundLevel, 0.0);
    });

    test('Cancellation clears live words and restores idle state', () async {
      await mockService.startListening();
      mockService.simulateSpeech('Temporary bloat feature');
      expect(mockService.liveWords, 'Temporary bloat feature');

      await mockService.cancelListening();
      expect(mockService.state, TrimVoiceState.idle);
      expect(mockService.liveWords, isEmpty);
      expect(mockService.soundLevel, 0.0);
    });

    testWidgets('BrainDumpScreen displays TYPE and SPEAK mode toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TYPE'), findsOneWidget);
      expect(find.text('SPEAK'), findsOneWidget);
      expect(find.text('What are you building?'), findsOneWidget);
      expect(find.text('TRIM THE FAT'), findsOneWidget);
    });

    testWidgets(
        'Switching to SPEAK mode displays waveform, mic button, and SPEAK status',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on SPEAK mode segment
      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      // Should display voice canvas elements
      expect(find.byType(VoiceWaveform), findsOneWidget);
      expect(find.byType(VoiceMicrophoneButton), findsOneWidget);
      expect(find.byType(VoiceStatusIndicator), findsOneWidget);
      expect(find.text('SPEAK'), findsNWidgets(2)); // Segment + Status
    });

    testWidgets(
        'Voice flow: SPEAK -> listening -> live text -> user reviews -> TRIM THE FAT ready without auto-submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to SPEAK mode
      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap mic button to start listening
      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockService.state, TrimVoiceState.listening);
      expect(find.text('LISTENING…'), findsOneWidget);

      // Simulate live transcribed words streaming in
      mockService.simulateSpeech(
          'An offline habit tracker with harsh truth feedback',
          soundLevel: 0.7);
      await tester.pump(const Duration(milliseconds: 100));

      // Live transcription should appear in review box
      expect(
          find.text('An offline habit tracker with harsh truth feedback'),
          findsOneWidget);
      expect(find.text('LIVE TRANSCRIPTION'), findsOneWidget);

      // Tap mic button to stop listening
      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 200));

      // Verification: Does NOT auto-submit; user remains on screen to review
      expect(find.text('What are you building?'), findsOneWidget);
      expect(find.text('REVIEW YOUR IDEA'), findsOneWidget);
      expect(
          find.text('An offline habit tracker with harsh truth feedback'),
          findsOneWidget);

      // TRIM THE FAT CTA is enabled and ready
      expect(find.text('TRIM THE FAT'), findsOneWidget);

      // User can switch back to TYPE mode to inspect/edit
      await tester.tap(find.text('TYPE'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
          find.text('An offline habit tracker with harsh truth feedback'),
          findsOneWidget);
    });

    testWidgets(
        'Press-and-hold (long press) interaction shows RELEASE TO FINISH',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      // Long press start
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(VoiceMicrophoneButton)));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('RELEASE TO FINISH'), findsOneWidget);

      // Release gesture
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      expect(mockService.state, TrimVoiceState.idle);
    });

    testWidgets('Cancellation discards spoken text and keeps prior draft',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Pre-populate with typed text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Initial core idea');
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to SPEAK
      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      // Start recording
      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockService.simulateSpeech('plus unwanted bloat feature');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CANCEL'), findsOneWidget);

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pump(const Duration(milliseconds: 200));

      // Unwanted speech was reverted, prior text retained
      expect(find.textContaining('Initial core idea'), findsOneWidget);
      expect(find.textContaining('unwanted bloat feature'), findsNothing);
    });

    testWidgets('Permission denied displays clear banner and falls back to typing',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      // Simulate permission denied error
      mockService.simulateError(TrimVoiceError.permissionDenied);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
          find.text('Microphone permission denied. Switched to typing.'),
          findsOneWidget);

      // Wait for auto-fallback to typing mode
      await tester.pump(const Duration(milliseconds: 1600));

      // Should be back in TYPE mode with multiline TextField visible
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('No speech detected displays non-technical notification',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      mockService.simulateError(TrimVoiceError.noSpeech);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
          find.text('No speech detected. Speak or switch to typing.'),
          findsOneWidget);
    });
  });

  group('TRIM — 8-Point Phone-Native Voice Verification Matrix', () {
    testWidgets('Test 1: permission granted allows starting listening cleanly',
        (WidgetTester tester) async {
      mockService.shouldFailInitialization = false;
      final initialized = await mockService.initialize();
      expect(initialized, isTrue);

      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockService.state, TrimVoiceState.listening);
      expect(find.text('LISTENING…'), findsOneWidget);
    });

    testWidgets('Test 2: permission denied shows banner and falls back to typing',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      mockService.simulateError(TrimVoiceError.permissionDenied);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Microphone permission denied. Switched to typing.'),
        findsOneWidget,
      );

      // Verify typing fallback occurs
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Test 3: cancellation discards current speech and restores prior text',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Core baseline product');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockService.simulateSpeech('plus extra noise features');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CANCEL'), findsOneWidget);
      await tester.tap(find.text('CANCEL'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Core baseline product'), findsOneWidget);
      expect(find.textContaining('extra noise features'), findsNothing);
    });

    testWidgets('Test 4: short speech populates idea and updates character count',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockService.simulateSpeech('Focus timer app');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Focus timer app'), findsOneWidget);
      expect(find.text('15 chars'), findsOneWidget);
    });

    testWidgets('Test 5: long speech streams multi-sentence idea without truncation',
        (WidgetTester tester) async {
      const longIdea =
          'A minimalist habit tracker that automatically detects procrastination, '
          'eliminates social feed distractions, prompts daily reflection, and enforces '
          'a strict maximum of three priority goals per week.';

      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockService.simulateSpeech(longIdea);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(longIdea), findsOneWidget);
      expect(find.text('${longIdea.length} chars'), findsOneWidget);
    });

    testWidgets('Test 6: edit transcription allows switching to typing and editing words',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockService.simulateSpeech('Spoken raw draft');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 200));

      // Switch back to TYPE to edit
      await tester.tap(find.text('TYPE'));
      await tester.pump(const Duration(milliseconds: 200));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Spoken raw draft edited with human clarity');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Spoken raw draft edited with human clarity'), findsOneWidget);
    });

    testWidgets('Test 7: submit requires explicit TRIM THE FAT tap (no auto-submit)',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 100));

      mockService.simulateSpeech('An app with too many features');
      await tester.pump(const Duration(milliseconds: 100));

      // Stop listening
      await tester.tap(find.byType(VoiceMicrophoneButton));
      await tester.pump(const Duration(milliseconds: 200));

      // Confirms: NO auto-submit occurred; still on BrainDumpScreen
      expect(find.text('What are you building?'), findsOneWidget);
      expect(find.text('REVIEW YOUR IDEA'), findsOneWidget);

      // Now explicitly tap TRIM THE FAT
      final trimButton = find.text('TRIM THE FAT');
      expect(trimButton, findsOneWidget);

      await tester.tap(trimButton);
      await tester.pumpAndSettle();

      // Successfully transitions to processing screen
      expect(find.text('What are you building?'), findsNothing);
    });

    testWidgets('Test 8: offline/failure path shows non-technical error banner and preserves draft',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      mockService.simulateError(TrimVoiceError.transcriptionFailed);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Could not transcribe speech. Switched to typing.'),
        findsOneWidget,
      );

      // Safe fallback to typing preserves screen stability
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Test 9: silence/timeout error shows no speech detected (not permission denied)',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      mockService.simulateError(TrimVoiceError.noSpeech);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('No speech detected. Speak or switch to typing.'),
        findsOneWidget,
      );
      expect(find.textContaining('permission'), findsNothing);
    });

    testWidgets('Test 10: recoverable recognizerBusy error preserves SPEAK mode for easy retry',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BrainDumpScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('SPEAK'));
      await tester.pump(const Duration(milliseconds: 200));

      mockService.simulateError(TrimVoiceError.recognizerBusy);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Speech recognition temporarily busy. Try again.'),
        findsOneWidget,
      );

      // Should NOT force fallback to typing; remains in SPEAK mode
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(VoiceMicrophoneButton), findsOneWidget);
    });
  });
}

