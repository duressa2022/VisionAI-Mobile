import 'package:flutter/foundation.dart';

class VisionProvider extends ChangeNotifier {
  // Singleton instance
  static final VisionProvider _instance = VisionProvider._internal();

  // Private constructor
  VisionProvider._internal();
  bool _isSpeaking = false;
  bool _isResponded = false;

  // Factory constructor to return the singleton instance
  factory VisionProvider() {
    return _instance;
  }
  bool get isSpeaking => _isSpeaking;
  bool get isResponded => _isResponded;
  void setIsResponded(bool isResponded) {
    _isResponded = isResponded;
    notifyListeners();
  }
  void setSpeaking(bool isSpeaking) {
    _isSpeaking = isSpeaking;
    notifyListeners();
  }

  // Method to get the current vision provider
  String getCurrentVisionProvider() {
    return "Vision Provider: Google Cloud Vision";
  }
}
