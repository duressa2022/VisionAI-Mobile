import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class ObjectDetectionService {
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    await Tflite.loadModel(
      model: 'assets/models/yolov8n.tflite',
      labels: 'assets/models/yolov5s_labels.txt',
      numThreads: 4,
    );
    
    _isInitialized = true;
  }
  
  Future<List<Map<String, dynamic>>> processImage(CameraImage image) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Convert CameraImage to format suitable for TFLite
    final recognitions = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      threshold: 0.4,
      numResultsPerClass: 3,
    );
    
    if (recognitions == null) {
      return [];
    }
    
    // Convert recognitions to our format
    final List<Map<String, dynamic>> detections = [];
    
    for (final recognition in recognitions) {
      final x = recognition['rect']['x'] as double;
      final y = recognition['rect']['y'] as double;
      final w = recognition['rect']['w'] as double;
      final h = recognition['rect']['h'] as double;
      
      detections.add({
        'label': recognition['detectedClass'] as String,
        'confidence': recognition['confidenceInClass'] as double,
        'rect': Rect.fromLTWH(
          max(0, x),
          max(0, y),
          min(w, 1.0 - x),
          min(h, 1.0 - y),
        ),
      });
    }
    
    return detections;
  }
  
  void dispose() {
    Tflite.close();
  }
}
