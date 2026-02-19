import 'dart:math';
import 'package:flutter/material.dart';

class MiniPlayerVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const MiniPlayerVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<MiniPlayerVisualizer> createState() => _MiniPlayerVisualizerState();
}

class _MiniPlayerVisualizerState extends State<MiniPlayerVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    return SizedBox(
      width: 30, // Fits in mini player
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              animationValue: _controller.value,
              color: widget.color,
              isPlaying: widget.isPlaying,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isPlaying;

  _WavePainter({
    required this.animationValue,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final barWidth = width / 9; // 5 bars + 4 spaces
    final spacing = width / 9;

    for (int i = 0; i < 5; i++) {
      double barHeight;
      if (isPlaying) {
        // Generate pseudo-random wave height based on animation and index
        final offset = i * 0.5;
        final position = (animationValue + offset) % 1.0;
        // Sine wave for smooth movement
        final normalized = (sin(position * 2 * pi) + 1) / 2; 
        barHeight = height * (0.3 + 0.7 * normalized);
      } else {
        barHeight = height * 0.2; // Idle state
      }
      
      final x = i * (barWidth + spacing);
      final y = (height - barHeight) / 2;
      
      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      
      canvas.drawRRect(rRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.isPlaying != isPlaying;
  }
}
