import 'package:speech_to_text/speech_to_text.dart';

class VoiceRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Callbacks
  Function(String)? onResult;
  Function(bool)? onListeningStatusChanged;

  Future<void> initialize() async {
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) {
        if (status == 'listening') {
          onListeningStatusChanged?.call(true);
        } else if (status == 'notListening') {
          onListeningStatusChanged?.call(false);
        }
      },
    );
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    onListeningStatusChanged?.call(false);
  }

  void dispose() {
    _speechToText.cancel();
  }
}
