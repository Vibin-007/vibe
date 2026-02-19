import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MeshGradientBackground extends StatelessWidget {
  final Color dominantColor;
  final Color accentColor;

  const MeshGradientBackground({
    super.key,
    required this.dominantColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Color
        Container(color: dominantColor.withOpacity(0.4)),
        
        // Blobs
        _buildBlob(context, accentColor.withOpacity(0.3), const Offset(-0.2, -0.2), 300),
        _buildBlob(context, dominantColor.withOpacity(0.2), const Offset(1.2, 0.4), 400),
        _buildBlob(context, accentColor.withOpacity(0.15), const Offset(0.4, 1.1), 350),
        
        // Overlay for readability - Theme aware
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlob(BuildContext context, Color color, Offset position, double size) {
    return Positioned(
      left: MediaQuery.of(context).size.width * position.dx - (size / 2),
      top: MediaQuery.of(context).size.height * position.dy - (size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.0),
            ],
            // Focal point slightly off-center makes rotation visible
            focal: const Alignment(0.3, -0.2),
            radius: 0.8,
          ),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .move(
            duration: (15 + position.dx.abs() * 5).seconds, 
            begin: Offset(-60 * position.dx, -60 * position.dy), 
            end: Offset(60 * position.dx, 60 * position.dy), 
            curve: Curves.easeInOut,
          )
          .scale(
            duration: (12 + position.dy.abs() * 4).seconds, 
            begin: const Offset(0.6, 0.6), 
            end: const Offset(1.4, 1.4), 
            curve: Curves.easeInOut,
          )
          .rotate(
            duration: (25 + position.dx.abs() * 10).seconds,
            begin: 0,
            end: 1,
            curve: Curves.linear,
          ),
    ).animate().fadeIn(duration: 2.seconds);
  }
}
