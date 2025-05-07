import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceWaveAnimation extends StatelessWidget {
  final AnimationController animationController;
  final bool isListening;
  
  const VoiceWaveAnimation({
    Key? key,
    required this.animationController,
    required this.isListening,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: VoiceWavePainter(
            animation: animationController,
            isListening: isListening,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final Animation<double> animation;
  final bool isListening;
  final Color color;
  
  VoiceWavePainter({
    required this.animation,
    required this.isListening,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Draw microphone icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Simple microphone shape
    final micPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: radius * 0.5,
          height: radius * 0.8,
        ),
        Radius.circular(radius * 0.25),
      ))
      ..addRect(Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.5),
        width: radius * 0.5,
        height: radius * 0.2,
      ));
    
    canvas.drawPath(micPath, iconPaint);
    
    if (isListening) {
      // Draw animated waves
      for (int i = 0; i < 3; i++) {
        final wavePaint = Paint()
          ..color = color.withOpacity(1.0 - (i * 0.2) - animation.value * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        final waveRadius = radius * (0.6 + i * 0.2) * (1.0 + animation.value * 0.3);
        
        // Create a wavy circle
        final wavePath = Path();
        for (int j = 0; j < 360; j += 5) {
          final angle = j * math.pi / 180;
          final waveOffset = math.sin(angle * 8 + animation.value * math.pi * 2) * 5;
          final x = center.dx + (waveRadius + waveOffset) * math.cos(angle);
          final y = center.dy + (waveRadius + waveOffset) * math.sin(angle);
          
          if (j == 0) {
            wavePath.moveTo(x, y);
          } else {
            wavePath.lineTo(x, y);
          }
        }
        wavePath.close();
        
        canvas.drawPath(wavePath, wavePaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant VoiceWavePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
           oldDelegate.isListening != isListening;
  }
}
