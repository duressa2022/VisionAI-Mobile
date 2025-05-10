import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DetectionOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> detections;
  final Size previewSize;
  final Size screenSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: screenSize,
      painter: DetectionPainter(
        detections: detections,
        previewSize: previewSize,
        screenSize: screenSize,
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size previewSize;
  final Size screenSize;

  DetectionPainter({
    required this.detections,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPaint = ui.TextStyle(
      color: Colors.white,
      fontSize: 16,
      //backgroundColor: Colors.green.withOpacity(0.7),
    );

    for (final detection in detections) {
      final rect = detection['rect'] as Rect;
      final label = detection['label'] as String;
      final confidence = detection['confidence'] as double;

      // Convert rect from camera coordinates to screen coordinates
      final screenRect = _convertRect(rect);

      // Draw bounding box
      canvas.drawRect(screenRect, paint);

      // Draw label
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
        ..pushStyle(textPaint)
        ..addText('$label ${(confidence * 100).toStringAsFixed(0)}%');

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: screenRect.width));

      canvas.drawParagraph(
        paragraph,
        Offset(screenRect.left, screenRect.top - 20),
      );
    }
  }

  Rect _convertRect(Rect rect) {
    final scaleX = screenSize.width / previewSize.width;
    final scaleY = screenSize.height / previewSize.height;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
