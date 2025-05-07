import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vision_ai/services/object_detection_service.dart';
import 'package:vision_ai/services/text_to_speech_service.dart';
import 'package:vision_ai/services/api_service.dart';
import 'package:vision_ai/widgets/detection_overlay.dart';
import 'package:vision_ai/widgets/voice_wave_animation.dart';
import 'package:vision_ai/main.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({Key? key}) : super(key: key);

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen>
    with TickerProviderStateMixin {
  late CameraController _cameraController;
  late ObjectDetectionService _objectDetectionService;
  late TextToSpeechService _textToSpeechService;
  late ApiService _apiService;
  late AnimationController _waveAnimationController;

  bool _isInitialized = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _detections = [];
  String _lastDescription = "";

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

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController.initialize();

    // Set up camera stream processing
    _cameraController.startImageStream(_processImage);

    // Initialize other services
    _objectDetectionService = ObjectDetectionService();
    await _objectDetectionService.initialize();

    _textToSpeechService = TextToSpeechService();
    await _textToSpeechService.initialize();

    _apiService = ApiService();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Run object detection on the image
      final detections = await _objectDetectionService.processImage(image);

      if (detections.isNotEmpty) {
        // Send detections to backend for processing
        final description = await _apiService.processDetections(detections);

        if (description != _lastDescription) {
          _lastDescription = description;

          // Speak the description
          await _textToSpeechService.speak(description);
        }

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

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _cameraController.stopImageStream();
    _cameraController.dispose();
    _objectDetectionService.dispose();
    _textToSpeechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
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
                    isListening: true,
                  ),
                ),
              ),
            ),
          ),

          // Last description
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
                _lastDescription.isEmpty
                    ? "Looking for objects..."
                    : _lastDescription,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
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
    );
  }
}
