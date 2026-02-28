import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Manages the SpeechToText lifecycle for continuous voice input.
///
/// Usage:
/// ```dart
/// final svc = VoiceInputService();
/// await svc.initialize();
/// svc.addListener(() { /* react to isListening / liveTranscript changes */ });
/// await svc.startListening();
/// // ... user finishes speaking ...
/// await svc.stopListening(); // returns the full transcript
/// svc.dispose();
/// ```
class VoiceInputService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  bool _speechEnabled = false;
  bool _isListening = false;
  String _liveTranscript = '';
  String _accumulatedTranscript = '';

  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  String get liveTranscript => _liveTranscript;

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> initialize({
    void Function(String message)? onPermanentError,
  }) async {
    _speechEnabled = await _speech.initialize(
      onError: (error) {
        if (!error.permanent) return; // transient errors are handled by restart
        _isListening = false;
        _liveTranscript = '';
        _accumulatedTranscript = '';
        notifyListeners();
        onPermanentError?.call(
          error.errorMsg.isNotEmpty
              ? error.errorMsg
              : 'Speech recognition failed',
        );
      },
      onStatus: (status) {
        // When the recognizer stops naturally, restart if the user hasn't stopped.
        if (_isListening && (status == 'done' || status == 'doneNoResult')) {
          _listenOnce();
        }
      },
    );
    notifyListeners();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Starts continuous listening. Resets any previous transcript.
  Future<void> startListening() async {
    if (!_speechEnabled || _isListening) return;
    _isListening = true;
    _liveTranscript = '';
    _accumulatedTranscript = '';
    notifyListeners();
    await _listenOnce();
  }

  /// Stops listening and returns the full accumulated transcript.
  Future<String> stopListening() async {
    if (!_isListening) return _liveTranscript;
    final result = _liveTranscript;
    _isListening = false;
    _liveTranscript = '';
    _accumulatedTranscript = '';
    notifyListeners();
    await _speech.stop();
    return result;
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _listenOnce() async {
    if (!_isListening) return;
    await _speech.listen(
      onResult: (result) {
        if (!_isListening) return;
        final prefix = _accumulatedTranscript.isEmpty
            ? ''
            : '$_accumulatedTranscript ';
        final full = (prefix + result.recognizedWords).trim();
        _liveTranscript = full;
        notifyListeners();
        if (result.finalResult) {
          _accumulatedTranscript = full;
          // Restart is triggered by onStatus 'done'
        }
      },
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
