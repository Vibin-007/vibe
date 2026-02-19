import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double width;
  final double height;

  const WaveVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
    this.width = double.infinity,
    this.height = 100,
  });

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SynergyWavePainter(
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

class _SynergyWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isPlaying;

  _SynergyWavePainter({
    required this.animationValue,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We will draw 3 waves with different phases and slight opacity variations
    _drawWave(canvas, size, 1.0, 0.3, 1.0);
    _drawWave(canvas, size, 1.5, 0.4, 0.6);
    _drawWave(canvas, size, 2.0, 0.2, 0.3);
  }

  void _drawWave(Canvas canvas, Size size, double speed, double offset, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midHeight = size.height / 2;
    final waveLength = size.width;
    
    // Amplitude modulation: Full when playing, very low flat line when paused
    final baseAmplitude = isPlaying ? size.height * 0.4 : 2.0; 

    path.moveTo(0, midHeight);

    for (double x = 0; x <= size.width; x += 5) {
      // Calculate normalized position
      final normalizedX = x / waveLength;
      
      // Dynamic phase shift based on animation value and wave specific parameters
      final phase = (animationValue * 2 * math.pi * speed) + (offset * 2 * math.pi);
      
      // Sine wave calculation
      final sine = math.sin((normalizedX * 2 * math.pi * 2.0) + phase); // 2.0 frequency multiplier
      
      final y = midHeight + (sine * baseAmplitude);
      
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SynergyWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isPlaying != isPlaying ||
           oldDelegate.color != color;
  }
}
