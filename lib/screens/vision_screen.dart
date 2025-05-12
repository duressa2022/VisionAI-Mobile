import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:vision_ai/services/object_detection_service.dart';
import 'package:vision_ai/services/provider.dart';
import 'package:vision_ai/services/text_to_speech_service.dart';
import 'package:vision_ai/services/api_service.dart';
import 'package:vision_ai/services/voice_recognition_service.dart';
import 'package:vision_ai/widgets/detection_overlay.dart';
import 'package:vision_ai/widgets/voice_wave_animation.dart';
import 'package:vision_ai/main.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';

class VisionScreen extends StatefulWidget {
  const VisionScreen({Key? key}) : super(key: key);

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen>
    with TickerProviderStateMixin {
  CameraController _cameraController = CameraController(
    cameras[0],
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );
  late ObjectDetectionService _objectDetectionService;
  late TextToSpeechService _textToSpeechService;
  late ApiService _apiService;
  late VoiceRecognitionService _voiceRecognitionService;
  late AnimationController _waveAnimationController;

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCapturing = false;
  bool _isListening = true;
  List<Map<String, dynamic>> _detections = [];
  String _lastDescription = "";
  String _statusText = "Say 'what is happening around' to scan";
  Timer? _captureTimer;
  List<Map<String, dynamic>> _allDetections = [];

  @override
  void initState() {
    super.initState();
    _initServices();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _waveAnimationController.repeat(reverse: true);
  }

  Future<void> _initServices() async {
    // Initialize camera
    if (cameras.isEmpty) {
      return;
    }

    await _cameraController.initialize();

    // Initialize other services
    _objectDetectionService = ObjectDetectionService();
    await _objectDetectionService.initialize();

    _textToSpeechService = TextToSpeechService(context);
    await _textToSpeechService.initialize();

    _apiService = ApiService();

    _voiceRecognitionService = VoiceRecognitionService();
    await _voiceRecognitionService.initialize();

    _voiceRecognitionService.onResult = (String text) {
      _handleVoiceCommand(text);
    };

    _voiceRecognitionService.onListeningStatusChanged = (bool isListening) {
      setState(() {
        _isListening = isListening;
      });

      // Restart listening if it stopped
      if (!isListening && mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_voiceRecognitionService.isListening) {
            _voiceRecognitionService.startListening();
          }
        });
      }
    };

    // Start listening for commands
    _voiceRecognitionService.startListening();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _handleVoiceCommand(String text) {
    final lowerText = text.toLowerCase().trim();

    final triggerPhrases = [
      "what is happening around",
      "what's happening around",
      "what is around me",
      "describe my surroundings",
      "what's around me",
      "what's going on around me",
      "can you describe the area",
      "tell me about the environment",
      "describe what's nearby",
      "see what's happening nearby",
      "explain the surroundings",
      "scan my surroundings",
      "what's in front of me",
      "show me what's around",
      "observe the environment",
      "analyze what's nearby",
      "describe the scene",
      "vision what do you see",
      "look around for me",
      "tell me what you see",
      "what is",
      "what's",
      "vision",
      "vision ai",
      "happening",
      "happening around",
      "happening around me",
      "me",
      "around",
    ];

    final stopPhrases = [
      "okay",
      "ok",
      "bye",
      "stop",
      "close",
      "end",
      "exit",
      "goodbye",
      "nice",
      "thanks",
      "thank you",
      "stop for now",
      "close service",
      "stop scanning",
      "exit vision",
      "terminate the scan",
      "stop everything",
      "no need to scan",
      "cancel vision",
      "you can stop now",
      "pause scanning",
      "that's enough",
      "end this task",
      "close the service",
      "disable the vision",
    ];

    // Try fuzzy matching (optional)
    bool fuzzyMatch(String input, List<String> options) {
      return options.any((phrase) => input.similarityTo(phrase) > 0.7);
    }

    if (triggerPhrases.contains(lowerText) ||
        fuzzyMatch(lowerText, triggerPhrases)) {
      _voiceRecognitionService.stopListening();
      _startCapturingFrames();
    } else if (stopPhrases.contains(lowerText) ||
        fuzzyMatch(lowerText, stopPhrases)) {
      _stopCapturingAndExit();
    }
  }

  void _startCapturingFrames() {
    if (_isCapturing) return;

    List<String> statusMessages = [
      "Hang tight, scanning your surroundings now! This will just take a few moments. Let’s see what we can discover together.",
      "Analyzing the environment, just a moment. I’m collecting all the visual details for a better understanding. Stay still if you can!",
      "Starting a 30-second scan, stay still! I need this time to capture everything clearly. Let’s make it count.",
      "Let's see what's around you! I’m opening my lenses wide to get a full view. This should only take a bit.",
      "Initiating environment scan for 30 seconds. I'm diving into every detail around you. Hang on while I work my magic.",
      "Exploring your surroundings, please wait. I’m processing objects, textures, and more. This won't take long.",
      "Launching a detailed 30-second scan. Please remain steady. Every second helps me see better.",
      "Give me 30 seconds to scan everything! I’ll be analyzing what I capture in real time. Thanks for your patience.",
      "Checking out your environment now. Let’s uncover everything that’s in view. Just a short moment!",
      "Looking around for anything interesting. I’ll notify you once I’ve gathered enough information. Stay tuned!",
      "Vision is analyzing the scene now. I’m picking up every detail I can. You’ll have results shortly.",
      "Scanning in progress, hold on! I’m collecting data from every angle I can see. Thanks for bearing with me.",
      "Let’s explore what’s around you! I’m processing visuals to provide the best insights possible. Sit tight!",
      "Hold tight, gathering details nearby. I’m focusing on every object and surface. Almost there!",
      "Detecting objects in your environment. From edges to colors, I’m mapping it all. Keep steady for best results.",
      "Processing everything I see... This includes lighting, depth, and shapes. I’ll let you know what I find soon.",
      "Working on capturing the scene! It’s a bit like painting a picture in real-time. Give me a few more seconds.",
      "Environment analysis started. I’ll be watching closely for all visible elements. Hold on while I work.",
      "Performing a deep scan of surroundings. Looking into objects, context, and spatial relationships. Please be patient.",
      "Capturing and analyzing for 30 seconds. I’m taking in everything around. Sit back and relax!",
      "Sit back, Vision is scanning the view. Every detail helps me understand your surroundings better. Thanks for your patience.",
      "Your environment is being analyzed. I’ll give you results as soon as I finish processing. Almost there!",
      "Give me a moment to check things out. I’m doing a thorough scan for full accuracy. Be right with you!",
      "A 30-second scan begins now! I’ll use every second to learn about your surroundings. Please hold steady!",
      "Starting full-frame capture for analysis. I’ll take in the entire scene to ensure nothing gets missed. This will be quick!",
    ];


    final randomStatus = statusMessages[
        DateTime.now().millisecondsSinceEpoch % statusMessages.length];

    setState(() {
      _isCapturing = true;
      _allDetections = [];
      _detections = [];
      _lastDescription = "";
      _statusText = randomStatus;
    });

    _cameraController.startImageStream(_processImageDuringCapture);

    _captureTimer = Timer(const Duration(seconds: 30), () {
      _stopCapturingFrames();
    });

    _textToSpeechService.speak(randomStatus);
  }

  void _stopCapturingFrames() {
    if (!_isCapturing) return;

    _captureTimer?.cancel();
    _cameraController.stopImageStream();

    setState(() {
      _isCapturing = false;
      _statusText = "Processing results...";
    });

    // Process all collected detections
    _processAllDetections();
  }

  void _stopCapturingAndExit() async {
    if (_isCapturing) {
      _captureTimer?.cancel();
      await _cameraController.stopImageStream();

      setState(() {
        _isCapturing = false;
        _detections = [];
        _allDetections = [];
        _lastDescription = "";
        _statusText = "Scanning stopped.";
      });
    }

    final goodbyeMessages = [
        "Goodbye, buddy! It was a pleasure assisting you today. Looking forward to our next session!",
        "It was great helping you today! I hope everything went smoothly. Let’s connect again soon!",
        "Hope I made your day easier. That’s always my goal! See you next time you need a hand.",
        "Signing off now, take care! Stay safe and remember I’m always here when you need me.",
        "Catch you later, friend. I enjoyed our time together! Don’t be a stranger.",
        "Vision is closing, have a great day! I’ll be right here when you return.",
        "Thanks for spending time with me! It means a lot to be part of your day. Until next time!",
        "I’ll be here when you need me next. Just reach out anytime. Goodbye for now!",
        "Ending session now, goodbye! I hope I was helpful in every way. Take care!",
        "See you next time! I’m always ready to help whenever you need it. Until then!",
        "Hope I was helpful! I’ll keep my circuits warm for your next visit.",
        "Time to rest my lenses. Bye! Until we focus again, stay awesome!",
        "Exiting Vision, goodbye! It’s been great working with you. Talk soon!",
        "Nice working with you! You made my job easy. Let’s team up again sometime!",
        "Thanks for using Vision! Your trust means the world. Come back anytime you like!",
        "Another mission completed! You did great out there. Let's do it again soon!",
        "Glad I could assist you! That’s what I’m here for. Don’t hesitate to return.",
        "Take care out there! Remember, I’m always just a click away. Goodbye for now!",
        "Logging off now! I’ll recharge while you conquer the world. See you soon!",
        "Talk to you soon! Don’t forget, Vision’s always got your back.",
        "That’s all for now, see ya! Keep being amazing until we meet again.",
        "Always happy to help! It’s what I’m built for. Reach out whenever you need support.",
        "Goodbye from Vision! Working with you is always a pleasure. Until next time!",
        "We made a great team! Let’s keep this collaboration going strong. Farewell for now!",
        "Session complete, goodbye! Take a breather, and I’ll be here when you’re ready again.",
        "Farewell for now! I’ll miss our chats, but I’ll be waiting for the next one.",
        "Shutting down gracefully! I hope your day continues to be as productive as this moment.",
        "Catch you on the flip side! Don’t forget, Vision’s always got its eye out for you.",
        "Hope I saw everything right! If not, I’ll be sharper next time. Take care!",
        "Let’s meet again soon! I’ve always got more to offer. Until then, farewell!",
];


    // Pick a random message
    final message = (goodbyeMessages..shuffle()).first;

    await _textToSpeechService.speak(message);

    // Delay before popping the screen
    await Future.delayed(const Duration(seconds: 7));

    _voiceRecognitionService.stopListening();
    Navigator.of(context).pop();
  }

  Future<void> _processImageDuringCapture(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Run object detection on the image
      final detections = await _objectDetectionService.processImage(image);

      if (detections.isNotEmpty) {
        // Add to all detections
        _allDetections.addAll(detections);

        if (mounted) {
          setState(() {
            _detections = detections;
          });
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processAllDetections() async {
    if (_allDetections.isEmpty) {
      setState(() {
        _statusText = "Say 'what is happening around' to scan again";
        _lastDescription = "No objects detected.";
      });
      await _textToSpeechService
          .speak("I couldn't detect any objects around you.");
      await _voiceRecognitionService.startListening();
      return;
    }

    try {
      final description = await _apiService.processDetections(_allDetections);

      if (mounted) {
        setState(() {
          _lastDescription = description;
          _statusText = "Say 'what is happening around' to scan again";
        });
      }

      await _textToSpeechService.speak(description);

      await _voiceRecognitionService.startListening();
    } catch (e) {
      print('Error processing all detections: $e');
      if (mounted) {
        setState(() {
          _lastDescription = "Error processing scene.";
          _statusText = "Say 'what is happening around' to scan again";
        });
      }
      await _textToSpeechService.speak("I had trouble processing what I saw.");
      await _voiceRecognitionService.startListening();
    }
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _captureTimer?.cancel();
    _cameraController.dispose();
    _objectDetectionService.dispose();
    _textToSpeechService.dispose();
    _voiceRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _visionProvider = Provider.of<VisionProvider>(context);

    if (_visionProvider.isResponded) {
      _visionProvider.setIsResponded(false);
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isCapturing = false;
          _lastDescription = "";
          _detections = [];
          _allDetections = [];
          _isListening = false;
        });
        _initServices();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Camera preview
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController.value.previewSize!.height,
                  height: _cameraController.value.previewSize!.width,
                  child: CameraPreview(_cameraController),
                ),
              ),
            ),

            // Detection overlay
            DetectionOverlay(
              detections: _detections,
              previewSize: _cameraController.value.previewSize!,
              screenSize: MediaQuery.of(context).size,
            ),

            // Voice wave animation
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: VoiceWaveAnimation(
                      animationController: _waveAnimationController,
                      isListening: _isListening,
                    ),
                  ),
                ),
              ),
            ),

            // Status text
            Positioned(
              bottom: 160,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Last description
            if (_lastDescription.isNotEmpty && !_isCapturing)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(
                      maxHeight: 150, // Set your preferred max height
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _lastDescription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

            // Back button
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
