import 'package:flutter/material.dart';
import 'package:vision_ai/services/text_to_speech_service.dart';
import 'package:vision_ai/widgets/voice_wave_animation.dart';
import 'package:vision_ai/services/voice_recognition_service.dart';
import 'package:vision_ai/screens/vision_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final VoiceRecognitionService _voiceRecognitionService =
      VoiceRecognitionService();
  late TextToSpeechService _textToSpeechService;
  bool _isListening = false;
  String _statusText = "Tap to start listening";
  late AnimationController _animationController;

  @override
  void initState() {
    _textToSpeechService = TextToSpeechService(context);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _initVoiceRecognition();
  }

  Future<void> _initVoiceRecognition() async {
    await _voiceRecognitionService.initialize();
    await _textToSpeechService.initialize();

    _voiceRecognitionService.onResult = (String text) async {
      final lowerText = text.toLowerCase();

      if (lowerText.contains("hey vision") ||
          lowerText.contains("vision") ||
          lowerText.contains("hey")) {
        // Step 1: Define random messages
        List<String> greetings = [
          "Hello there! Launching Vision now.",
          "Hi buddy, getting Vision ready for you.",
          "Hey! I'm opening Vision just for you.",
          "Greetings! Vision will be up shortly.",
          "Yo! Vision is on its way.",
          "Good to see you! Launching Vision.",
          "Vision coming right up, my friend!",
          "Opening Vision. Hope you're doing great!",
          "Hey, superstar! Starting Vision now.",
          "Salutations! Preparing Vision screen.",
          "Hey genius, Vision is loading.",
          "Launching Vision, hold tight!",
          "Get ready, Vision is starting.",
          "Hi! Just a second, loading Vision.",
          "Hey there, starting Vision in a moment.",
          "Vision is warming up for you.",
          "What’s up! Vision is on its way.",
          "Activating Vision just for you.",
          "Time for some Vision magic!",
          "Hold on tight, Vision is launching now.",
        ];

        // Step 2: Pick a random greeting
        final random = greetings[DateTime.now().millisecondsSinceEpoch % greetings.length];

        // Step 3: Speak the greeting
        await _textToSpeechService.speak(random);

        // Step 4: Wait for 10 seconds
        await Future.delayed(Duration(seconds: 4));

        // Step 5: Navigate to Vision screen
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
