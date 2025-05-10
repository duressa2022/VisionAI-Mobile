import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import './provider.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  BuildContext context;
  TextToSpeechService(this.context);

  Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      print(
          '======================================================================');
      Provider.of<VisionProvider>(context).setSpeaking(false);
      Provider.of<VisionProvider>(context).setIsResponded(true);
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    // If already speaking, stop current speech
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  bool get isSpeaking => _isSpeaking;

  void dispose() {
    _flutterTts.stop();
  }
}
