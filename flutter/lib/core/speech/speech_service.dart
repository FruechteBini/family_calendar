import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());

/// Outcome of requesting microphone access (runtime permission on mobile).
enum MicrophonePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

/// Thin wrapper around [SpeechToText] with init + Android/iOS mic permission.
class SpeechService {
  /// Ruhezeit ohne neue Erkennung, bevor [SpeechToText] die Session beendet.
  static const Duration kPauseBeforeEnd = Duration(seconds: 5);

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  bool get isAvailable => _speech.isAvailable;

  bool get isListening => _speech.isListening;

  /// Ensures the native speech engine is initialized (does not request mic).
  Future<bool> ensureInitialized({
    void Function(String message)? onError,
  }) async {
    if (_initialized) {
      return _speech.isAvailable;
    }
    _initialized = await _speech.initialize(
      onError: (e) => onError?.call(e.errorMsg),
      onStatus: (_) {},
      debugLogging: kDebugMode,
    );
    return _initialized && _speech.isAvailable;
  }

  /// Requests RECORD_AUDIO (Android) / microphone (iOS). No-op on web/desktop.
  Future<MicrophonePermissionStatus> requestMicrophoneIfNeeded() async {
    if (kIsWeb) {
      return MicrophonePermissionStatus.granted;
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      return MicrophonePermissionStatus.granted;
    }
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      return MicrophonePermissionStatus.granted;
    }
    status = await Permission.microphone.request();
    if (status.isGranted) {
      return MicrophonePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return MicrophonePermissionStatus.permanentlyDenied;
    }
    return MicrophonePermissionStatus.denied;
  }

  /// Starts listening. Call [ensureInitialized] and handle permissions first.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'de_DE',
  }) async {
    await _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      localeId: localeId,
      pauseFor: kPauseBeforeEnd,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
