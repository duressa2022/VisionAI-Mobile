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
      "Hang tight, scanning your surroundings now!",
      "Analyzing the environment, just a moment.",
      "Starting a 30-second scan, stay still!",
      "Let's see what's around you!",
      "Initiating environment scan for 30 seconds.",
      "Exploring your surroundings, please wait.",
      "Launching a detailed 30-second scan.",
      "Give me 30 seconds to scan everything!",
      "Checking out your environment now.",
      "Looking around for anything interesting.",
      "Vision is analyzing the scene now.",
      "Scanning in progress, hold on!",
      "Let’s explore what’s around you!",
      "Hold tight, gathering details nearby.",
      "Detecting objects in your environment.",
      "Processing everything I see...",
      "Working on capturing the scene!",
      "Environment analysis started.",
      "Performing a deep scan of surroundings.",
      "Capturing and analyzing for 30 seconds.",
      "Sit back, Vision is scanning the view.",
      "Your environment is being analyzed.",
      "Give me a moment to check things out.",
      "A 30-second scan begins now!",
      "Starting full-frame capture for analysis.",
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
      "Goodbye, buddy!",
      "It was great helping you today!",
      "Hope I made your day easier.",
      "Signing off now, take care!",
      "Catch you later, friend.",
      "Vision is closing, have a great day!",
      "Thanks for spending time with me!",
      "I’ll be here when you need me next.",
      "Ending session now, goodbye!",
      "See you next time!",
      "Hope I was helpful!",
      "Time to rest my lenses. Bye!",
      "Exiting Vision, goodbye!",
      "Nice working with you!",
      "Thanks for using Vision!",
      "Another mission completed!",
      "Glad I could assist you!",
      "Take care out there!",
      "Logging off now!",
      "Talk to you soon!",
      "That’s all for now, see ya!",
      "Always happy to help!",
      "Goodbye from Vision!",
      "We made a great team!",
      "Session complete, goodbye!",
      "Farewell for now!",
      "Shutting down gracefully!",
      "Catch you on the flip side!",
      "Hope I saw everything right!",
      "Let’s meet again soon!",
    ];

    // Pick a random message
    final message = (goodbyeMessages..shuffle()).first;

    await _textToSpeechService.speak(message);

    // Delay before popping the screen
    await Future.delayed(const Duration(seconds: 3));

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
