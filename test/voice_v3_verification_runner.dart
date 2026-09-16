import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:trim/services/trim_voice_service.dart';

class FakeSpeechToText extends Fake implements SpeechToText {
  bool initResult = true;
  bool permissionResult = true;
  bool availableResult = true;
  Function(SpeechRecognitionError error)? registeredOnError;
  Function(String status)? registeredOnStatus;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    registeredOnError = onError;
    registeredOnStatus = onStatus;
    return initResult;
  }

  @override
  Future<bool> get hasPermission async => permissionResult;

  @override
  bool get isAvailable => availableResult;

  @override
  bool get hasRecognized => true;

  @override
  Future<List<LocaleName>> locales() async => [
        LocaleName('en_IN', 'English (India)'),
        LocaleName('en_US', 'English (United States)'),
      ];

  void triggerError(String errorMsg, bool permanent) {
    registeredOnError?.call(SpeechRecognitionError(errorMsg, permanent));
  }

  void triggerStatus(String status) {
    registeredOnStatus?.call(status);
  }
}

void main() {
  group('TRIM Voice V3 — Android Speech Reliability Verification', () {
    late FakeSpeechToText fakeSpeech;
    late PlatformTrimVoiceService service;

    setUp(() {
      fakeSpeech = FakeSpeechToText();
      service = PlatformTrimVoiceService(speech: fakeSpeech);
    });

    test('1. Timeout after speech does NOT report permission denied', () async {
      await service.initialize();
      expect(service.permissionState, TrimVoicePermissionState.granted);

      // Trigger timeout error via SpeechToText callback
      fakeSpeech.triggerError('error_speech_timeout', true);

      // Reports noSpeech cleanly, NEVER permissionDenied
      expect(service.currentError, TrimVoiceError.noSpeech);
      expect(service.currentError!.displayMessage, contains('No speech detected'));
      expect(service.currentError!.displayMessage, isNot(contains('permission')));
    });

    test('2. Recognizer busy error maps to recognizerBusy with retry advice', () async {
      await service.initialize();

      fakeSpeech.triggerError('error_recognizer_busy', false);
      expect(service.currentError, TrimVoiceError.recognizerBusy);
      expect(service.currentError!.displayMessage, contains('temporarily busy'));
    });

    test('3. Explicit permission denied is the ONLY path setting permissionDenied', () async {
      await service.initialize();

      fakeSpeech.triggerError('error_permission', true);
      expect(service.currentError, TrimVoiceError.permissionDenied);
      expect(service.permissionState, TrimVoicePermissionState.permanentlyDenied);
      expect(service.currentError!.displayMessage, contains('Microphone permission denied'));
    });

    test('4. Network/service error maps to serviceUnavailable', () async {
      await service.initialize();

      fakeSpeech.triggerError('error_network', true);
      expect(service.currentError, TrimVoiceError.serviceUnavailable);
      expect(service.currentError!.displayMessage, contains('Recognition service unavailable'));
    });

    test('5. En-IN is selected by default for Indian English product dictation', () async {
      await service.initialize();
      expect(service.currentLocaleId, 'en_IN');
    });
  });
}
