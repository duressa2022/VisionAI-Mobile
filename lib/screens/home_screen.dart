import 'package:flutter/material.dart';
import 'package:vision_ai/widgets/voice_wave_animation.dart';
import 'package:vision_ai/services/voice_recognition_service.dart';
import 'package:vision_ai/screens/vision_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final VoiceRecognitionService _voiceRecognitionService = VoiceRecognitionService();
  bool _isListening = false;
  String _statusText = "Tap to start listening";
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _initVoiceRecognition();
  }

  Future<void> _initVoiceRecognition() async {
    await _voiceRecognitionService.initialize();
    
    _voiceRecognitionService.onResult = (String text) {
      if (text.toLowerCase().contains("hey vision")) {
        _navigateToVisionScreen();
      }
    };
    
    _voiceRecognitionService.onListeningStatusChanged = (bool isListening) {
      setState(() {
        _isListening = isListening;
        _statusText = isListening ? "Listening..." : "Tap to start listening";
        
        if (isListening) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
        }
      });
    };
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceRecognitionService.stopListening();
    } else {
      await _voiceRecognitionService.startListening();
    }
  }

  void _navigateToVisionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VisionScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _voiceRecognitionService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Vision AI",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Say \"Hey Vision\" to start",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: VoiceWaveAnimation(
                      animationController: _animationController,
                      isListening: _isListening,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Vision AI helps visually impaired users understand their environment through real-time object detection and audio descriptions.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
