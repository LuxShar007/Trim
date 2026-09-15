import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// The active interaction state of the voice input system.
enum TrimVoiceState {
  idle,
  listening,
  processing,
}

/// Product-level error categories with non-technical messages.
enum TrimVoiceError {
  permissionDenied,
  noSpeech,
  transcriptionFailed,
  notAvailable;

  String get displayMessage {
    switch (this) {
      case TrimVoiceError.permissionDenied:
        return 'Microphone permission denied. Switched to typing.';
      case TrimVoiceError.noSpeech:
        return 'No speech detected. Speak or switch to typing.';
      case TrimVoiceError.transcriptionFailed:
        return 'Could not transcribe speech. Switched to typing.';
      case TrimVoiceError.notAvailable:
        return 'Voice input is not available on this device.';
    }
  }
}

/// Abstract contract for voice input in Trim.
abstract class TrimVoiceService {
  ValueListenable<TrimVoiceState> get stateListenable;
  ValueListenable<String> get liveWordsListenable;
  ValueListenable<double> get soundLevelListenable;
  ValueListenable<TrimVoiceError?> get errorListenable;

  TrimVoiceState get state;
  String get liveWords;
  double get soundLevel;
  TrimVoiceError? get currentError;

  Future<bool> initialize();
  Future<bool> startListening({
    void Function(String text)? onResult,
    void Function(TrimVoiceError error)? onError,
  });
  Future<void> stopListening();
  Future<void> cancelListening();
  void clearError();
  void resetLiveWords();
  void dispose();

  static TrimVoiceService? _customInstance;

  /// Global or injected instance of TrimVoiceService
  static TrimVoiceService get instance =>
      _customInstance ??= PlatformTrimVoiceService();

  @visibleForTesting
  static void setMockInstance(TrimVoiceService? mock) {
    _customInstance = mock;
  }
}

/// Platform implementation using speech_to_text
class PlatformTrimVoiceService implements TrimVoiceService {
  final SpeechToText _speech;

  final ValueNotifier<TrimVoiceState> _stateNotifier =
      ValueNotifier<TrimVoiceState>(TrimVoiceState.idle);
  final ValueNotifier<String> _liveWordsNotifier = ValueNotifier<String>('');
  final ValueNotifier<double> _soundLevelNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<TrimVoiceError?> _errorNotifier =
      ValueNotifier<TrimVoiceError?>(null);

  bool _isInitialized = false;
  void Function(String text)? _onResultCallback;
  void Function(TrimVoiceError error)? _onErrorCallback;

  PlatformTrimVoiceService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  @override
  ValueListenable<TrimVoiceState> get stateListenable => _stateNotifier;

  @override
  ValueListenable<String> get liveWordsListenable => _liveWordsNotifier;

  @override
  ValueListenable<double> get soundLevelListenable => _soundLevelNotifier;

  @override
  ValueListenable<TrimVoiceError?> get errorListenable => _errorNotifier;

  @override
  TrimVoiceState get state => _stateNotifier.value;

  @override
  String get liveWords => _liveWordsNotifier.value;

  @override
  double get soundLevel => _soundLevelNotifier.value;

  @override
  TrimVoiceError? get currentError => _errorNotifier.value;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: false,
      );
      return _isInitialized;
    } catch (_) {
      _isInitialized = false;
      return false;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    TrimVoiceError mapped;
    final msg = error.errorMsg.toLowerCase();

    if (error.permanent || msg.contains('permission') || msg.contains('denied')) {
      mapped = TrimVoiceError.permissionDenied;
    } else if (msg.contains('no_match') ||
        msg.contains('timeout') ||
        msg.contains('speech_timeout') ||
        msg.contains('no speech')) {
      mapped = TrimVoiceError.noSpeech;
    } else {
      mapped = TrimVoiceError.transcriptionFailed;
    }

    _errorNotifier.value = mapped;
    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
    _onErrorCallback?.call(mapped);
  }

  void _handleSpeechStatus(String status) {
    if (status == 'listening') {
      _stateNotifier.value = TrimVoiceState.listening;
    } else if (status == 'notListening' || status == 'done') {
      if (_stateNotifier.value == TrimVoiceState.listening) {
        _stateNotifier.value = TrimVoiceState.idle;
      }
      _soundLevelNotifier.value = 0.0;
    }
  }

  @override
  Future<bool> startListening({
    void Function(String text)? onResult,
    void Function(TrimVoiceError error)? onError,
  }) async {
    _onResultCallback = onResult;
    _onErrorCallback = onError;
    _errorNotifier.value = null;
    _liveWordsNotifier.value = '';

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        final err = TrimVoiceError.permissionDenied;
        _errorNotifier.value = err;
        onError?.call(err);
        return false;
      }
    }

    if (!_speech.isAvailable) {
      final err = TrimVoiceError.notAvailable;
      _errorNotifier.value = err;
      onError?.call(err);
      return false;
    }

    _stateNotifier.value = TrimVoiceState.listening;

    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          _liveWordsNotifier.value = words;
          _onResultCallback?.call(words);
          if (result.finalResult) {
            _stateNotifier.value = TrimVoiceState.idle;
          }
        },
        onSoundLevelChange: (level) {
          double normalized = 0.0;
          if (level > 0) {
            normalized = (level / 10.0).clamp(0.0, 1.0);
          } else if (level < 0) {
            normalized = ((level + 50.0) / 50.0).clamp(0.0, 1.0);
          }
          _soundLevelNotifier.value = normalized;
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      return true;
    } catch (_) {
      _stateNotifier.value = TrimVoiceState.idle;
      final err = TrimVoiceError.transcriptionFailed;
      _errorNotifier.value = err;
      onError?.call(err);
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    _stateNotifier.value = TrimVoiceState.processing;
    _soundLevelNotifier.value = 0.0;
    try {
      await _speech.stop();
    } catch (_) {}
    _stateNotifier.value = TrimVoiceState.idle;
  }

  @override
  Future<void> cancelListening() async {
    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
    _liveWordsNotifier.value = '';
    try {
      await _speech.cancel();
    } catch (_) {}
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
  }
}
