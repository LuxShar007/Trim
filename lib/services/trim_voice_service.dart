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

/// Explicit microphone permission state for transparent diagnostics.
enum TrimVoicePermissionState {
  notRequested,
  requesting,
  granted,
  permanentlyDenied,
  unavailable,
}

/// Product-level error categories with non-technical messages.
enum TrimVoiceError {
  permissionDenied,
  noSpeech,
  recognizerBusy,
  serviceUnavailable,
  transcriptionFailed,
  notAvailable;

  String get displayMessage {
    switch (this) {
      case TrimVoiceError.permissionDenied:
        return 'Microphone permission denied. Switched to typing.';
      case TrimVoiceError.noSpeech:
        return 'No speech detected. Speak or switch to typing.';
      case TrimVoiceError.recognizerBusy:
        return 'Speech recognition temporarily busy. Try again.';
      case TrimVoiceError.serviceUnavailable:
        return 'Recognition service unavailable. Switched to typing.';
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
  ValueListenable<TrimVoicePermissionState> get permissionStateListenable =>
      ValueNotifier<TrimVoicePermissionState>(TrimVoicePermissionState.granted);

  TrimVoiceState get state;
  String get liveWords;
  double get soundLevel;
  TrimVoiceError? get currentError;
  TrimVoicePermissionState get permissionState => TrimVoicePermissionState.granted;
  String? get currentLocaleId => 'en_IN';
  bool get isOnDeviceRecognitionAvailable => false;

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

/// Platform implementation using speech_to_text with modern Android SpeechRecognizer support.
class PlatformTrimVoiceService implements TrimVoiceService {
  final SpeechToText _speech;

  final ValueNotifier<TrimVoiceState> _stateNotifier =
      ValueNotifier<TrimVoiceState>(TrimVoiceState.idle);
  final ValueNotifier<String> _liveWordsNotifier = ValueNotifier<String>('');
  final ValueNotifier<double> _soundLevelNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<TrimVoiceError?> _errorNotifier =
      ValueNotifier<TrimVoiceError?>(null);
  final ValueNotifier<TrimVoicePermissionState> _permissionStateNotifier =
      ValueNotifier<TrimVoicePermissionState>(TrimVoicePermissionState.notRequested);

  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _selectedLocaleId;
  bool _isOnDeviceRecognitionAvailable = false;

  // Partial vs final transcript accumulators
  String _finalizedTranscript = '';
  String _currentPartialWords = '';

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
  String? get currentLocaleId => _selectedLocaleId;

  @override
  bool get isOnDeviceRecognitionAvailable => _isOnDeviceRecognitionAvailable;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _permissionStateNotifier.value = TrimVoicePermissionState.requesting;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: false,
      );

      final hasPerm = await _speech.hasPermission;
      _hasPermission = hasPerm;

      if (hasPerm) {
        _permissionStateNotifier.value = TrimVoicePermissionState.granted;
      } else if (!_speech.isAvailable) {
        _permissionStateNotifier.value = TrimVoicePermissionState.unavailable;
      } else {
        _permissionStateNotifier.value = TrimVoicePermissionState.permanentlyDenied;
      }

      if (_isInitialized) {
        // Query locales and prefer Indian English (en-IN) for accurate product idea capture
        try {
          final locales = await _speech.locales();
          if (locales.isNotEmpty) {
            final inLocale = locales.firstWhere(
              (l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'en_in',
              orElse: () => locales.firstWhere(
                (l) => l.localeId.toLowerCase().startsWith('en'),
                orElse: () => locales.first,
              ),
            );
            _selectedLocaleId = inLocale.localeId;
          } else {
            _selectedLocaleId = 'en_IN';
          }
        } catch (_) {
          _selectedLocaleId = 'en_IN';
        }

        // Detect whether on-device capability exists on this runtime
        try {
          _isOnDeviceRecognitionAvailable = _speech.hasRecognized;
        } catch (_) {
          _isOnDeviceRecognitionAvailable = false;
        }
      }

      return _isInitialized;
    } catch (_) {
      _isInitialized = false;
      _permissionStateNotifier.value = TrimVoicePermissionState.unavailable;
      return false;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    final msg = error.errorMsg.toLowerCase();
    TrimVoiceError? mapped;

    // 1. Explicit permission denial
    if (msg.contains('error_permission') ||
        (msg.contains('permission') && msg.contains('denied')) ||
        !_hasPermission) {
      mapped = TrimVoiceError.permissionDenied;
      _permissionStateNotifier.value = TrimVoicePermissionState.permanentlyDenied;
    }
    // 2. No speech detected or silence timeout
    else if (msg.contains('no_match') ||
        msg.contains('speech_timeout') ||
        msg.contains('no speech')) {
      // If words were already transcribed, silence is just a natural end-of-thought, NOT a failure!
      if (_finalizedTranscript.isNotEmpty || _currentPartialWords.isNotEmpty) {
        if (_currentPartialWords.isNotEmpty) {
          _commitFinalResult(_currentPartialWords);
        }
        mapped = null; // Clean completion without error banner
      } else {
        mapped = TrimVoiceError.noSpeech;
      }
    }
    // 3. Busy recognizer
    else if (msg.contains('busy') || msg.contains('error_recognizer_busy')) {
      mapped = TrimVoiceError.recognizerBusy;
    }
    // 4. Network or service error
    else if (msg.contains('network') ||
        msg.contains('server') ||
        msg.contains('error_network') ||
        msg.contains('service')) {
      mapped = TrimVoiceError.serviceUnavailable;
    }
    // 5. Generic client error
    else {
      if (_finalizedTranscript.isNotEmpty || _currentPartialWords.isNotEmpty) {
        if (_currentPartialWords.isNotEmpty) {
          _commitFinalResult(_currentPartialWords);
        }
        mapped = null;
      } else {
        mapped = TrimVoiceError.transcriptionFailed;
      }
    }

    if (mapped != null) {
      _errorNotifier.value = mapped;
      _onErrorCallback?.call(mapped);
    }

    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
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
    // Avoid stacking multiple recognizers
    if (_stateNotifier.value == TrimVoiceState.listening) {
      await stopListening();
    }

    _onResultCallback = onResult;
    _onErrorCallback = onError;
    _errorNotifier.value = null;
    _currentPartialWords = '';

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        final hasPerm = await _speech.hasPermission;
        final err = !hasPerm
            ? TrimVoiceError.permissionDenied
            : TrimVoiceError.notAvailable;
        _errorNotifier.value = err;
        onError?.call(err);
        return false;
      }
    }

    final hasPerm = await _speech.hasPermission;
    _hasPermission = hasPerm;
    if (!hasPerm) {
      final err = TrimVoiceError.permissionDenied;
      _errorNotifier.value = err;
      onError?.call(err);
      return false;
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
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            _currentPartialWords = words;
            final fullTranscript = _buildAccumulatedTranscript();
            _liveWordsNotifier.value = fullTranscript;
            _onResultCallback?.call(fullTranscript);
          }
          if (result.finalResult) {
            if (words.isNotEmpty) {
              _commitFinalResult(words);
            }
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
          cancelOnError: false, // Do not terminate on non-fatal warnings
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 90), // Support long product pitches
          pauseFor: const Duration(seconds: 8),  // 8s allowance for natural mid-sentence pauses
          localeId: _selectedLocaleId ?? 'en_IN',
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

  void _commitFinalResult(String finalChunk) {
    final sanitizedChunk = _normalizeSpacing(finalChunk);
    if (sanitizedChunk.isEmpty) return;

    if (_finalizedTranscript.isEmpty) {
      _finalizedTranscript = sanitizedChunk;
    } else {
      if (!_finalizedTranscript.endsWith(sanitizedChunk)) {
        _finalizedTranscript = '$_finalizedTranscript $sanitizedChunk';
      }
    }
    _currentPartialWords = '';
    _liveWordsNotifier.value = _finalizedTranscript;
  }

  String _buildAccumulatedTranscript() {
    if (_currentPartialWords.isEmpty) {
      return _finalizedTranscript;
    }
    if (_finalizedTranscript.isEmpty) {
      return _currentPartialWords;
    }
    if (_currentPartialWords.startsWith(_finalizedTranscript)) {
      return _currentPartialWords;
    }
    return '$_finalizedTranscript $_currentPartialWords';
  }

  String _normalizeSpacing(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Future<void> stopListening() async {
    _stateNotifier.value = TrimVoiceState.processing;
    _soundLevelNotifier.value = 0.0;
    try {
      await _speech.stop();
    } catch (_) {}
    if (_currentPartialWords.isNotEmpty) {
      _commitFinalResult(_currentPartialWords);
    }
    _stateNotifier.value = TrimVoiceState.idle;
  }

  @override
  Future<void> cancelListening() async {
    _stateNotifier.value = TrimVoiceState.idle;
    _soundLevelNotifier.value = 0.0;
    _liveWordsNotifier.value = '';
    _currentPartialWords = '';
    _finalizedTranscript = '';
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
    _currentPartialWords = '';
    _finalizedTranscript = '';
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
