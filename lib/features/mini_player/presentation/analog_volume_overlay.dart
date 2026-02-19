import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/theme_bloc.dart';
import 'dart:ui';
import 'package:flutter/scheduler.dart';

class AnalogVolumeOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const AnalogVolumeOverlay({super.key, required this.onClose});

  @override
  State<AnalogVolumeOverlay> createState() => _AnalogVolumeOverlayState();
}

class _AnalogVolumeOverlayState extends State<AnalogVolumeOverlay> with SingleTickerProviderStateMixin {
  double _currentVolume = 0.5;
  double _tiltAngle = 0.0;
  StreamSubscription? _sensorSubscription;
  late Ticker _ticker;
  double _displayVolume = 0.5;
  double _targetVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _initVolume();
    _ticker = createTicker(_onTick)..start();
    _startListening();
  }

  void _onTick(Duration elapsed) {
    if ((_displayVolume - _targetVolume).abs() < 0.005) {
      if (_displayVolume != _targetVolume) {
        setState(() {
          _displayVolume = _targetVolume;
        });
      }
      return;
    }

    setState(() {
      // Smooth interpolation (Ease-out effect)
      _displayVolume += (_targetVolume - _displayVolume) * 0.15;
    });
  }

  Future<void> _initVolume() async {
    final vol = await VolumeController.instance.getVolume();
    _currentVolume = vol;
    _targetVolume = vol;
    _displayVolume = vol;
    if (mounted) setState(() {});
  }

  void _startListening() {
    _sensorSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      
      final x = event.x;
      
      // Adjusted Deadzone and Sensitivity
      double delta = 0;
      if (x < -1.5) { 
        delta = 0.015; // Slightly slower increment for better control
      } else if (x > 1.5) {
        delta = -0.015; 
      }
      
      if (delta != 0) {
         // Update Target
         _targetVolume = (_targetVolume + delta).clamp(0.0, 1.0);
         
         // Update System Volume immediately for responsiveness
         VolumeController.instance.setVolume(_targetVolume);
      }
      
      // Always update tilt for immediate feedback
      setState(() {
         _tiltAngle = x.clamp(-9.8, 9.8) / 9.8; 
      });
      
      // Sync tracking var
      _currentVolume = _targetVolume;
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 20),
                
                // The Analog Dial
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CustomPaint(
                    painter: AnalogVolumePainter(
                      volume: _displayVolume,
                      tilt: _tiltAngle,
                      color: primaryColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                Text(
                  "${(_displayVolume * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace'
                  ),
                ),

              ],
            ),
          ),
          
          // Gesture Detector to catch release if this is an overlay
          // Actually, MiniPlayer will handle the "Long Press End" or we need a way to detect lift.
          // If this is a dialog/overlay, user might tap outside to close.
          Positioned.fill(
             child: GestureDetector(
               onTap: widget.onClose,
               behavior: HitTestBehavior.translucent,
               child: const SizedBox(),
             ),
          ),
        ],
      ),
    );
  }
}

class AnalogVolumePainter extends CustomPainter {
  final double volume;
  final double tilt;
  final Color color;

  AnalogVolumePainter({required this.volume, required this.tilt, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 1. Draw Outer Ring (Static)
    final paintRing = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawCircle(center, radius, paintRing);
    
    // 2. Draw Volume Arc
    final paintVolume = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20;
      
    // -225 degrees to +45 degrees (270 degree span)
    const startAngle = -1.25 * pi; // -225 deg
    const sweepSpan = 1.5 * pi;    // 270 deg
    final sweepAngle = sweepSpan * volume;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paintVolume,
    );
    
    // 3. Draw "Liquid" Tilt Indicator inside
    // Simulates a level bubble or weighted needle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Tilt rotates the inner dial
    canvas.rotate(tilt * -1.5); // Reverse tilt for stability feel
    
    final paintNeedle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Draw a "Knob" line
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, -50), width: 6, height: 40), 
      paintNeedle
    );
    
    // Draw Center Cap
    final paintCap = Paint()..color = Colors.grey[900]!;
    canvas.drawCircle(Offset.zero, radius * 0.6, paintCap);
    
    // Draw Center Knob Border
    final paintCapBorder = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, radius * 0.6, paintCapBorder);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnalogVolumePainter oldDelegate) {
     return oldDelegate.volume != volume || oldDelegate.tilt != tilt || oldDelegate.color != color;
  }
}
