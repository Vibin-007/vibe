import 'dart:math';
import 'package:flutter/material.dart';

class SquigglySlider extends StatefulWidget {
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  const SquigglySlider({
    super.key,
    required this.value,
    this.max = 1.0,
    required this.onChanged,
  });

  @override
  State<SquigglySlider> createState() => _SquigglySliderState();
}

class _SquigglySliderState extends State<SquigglySlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isDragging = true),
      onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final percent = (localPos.dx / box.size.width).clamp(0.0, 1.0);
        widget.onChanged(percent * widget.max);
      },
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SquigglyPainter(
                value: widget.value / widget.max,
                animationValue: _controller.value,
                color: Theme.of(context).primaryColor,
                isDragging: _isDragging,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double value;
  final double animationValue;
  final Color color;
  final bool isDragging;

  _SquigglyPainter({
    required this.value,
    required this.animationValue,
    required this.color,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final centerY = size.height / 2;

    // Amplitude and Frequency for the squiggle
    final amplitude = isDragging ? 10.0 : 5.0;
    const frequency = 0.1; 

    // Moves the wave
    final phaseShift = animationValue * 2 * pi;

    path.moveTo(0, centerY);

    // Draw active squiggly line
    final activeWidth = width * value;
    for (double x = 0; x <= activeWidth; x++) {
      final y = centerY + amplitude * sin((x * frequency) + phaseShift);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Draw inactive straight line (faded)
    final inactivePaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(activeWidth, centerY),
      Offset(width, centerY),
      inactivePaint,
    );

    // Draw Thumb
    final thumbX = activeWidth;
    final thumbY = centerY + amplitude * sin((thumbX * frequency) + phaseShift);
    final thumbRadius = isDragging ? 12.0 : 8.0;
    canvas.drawCircle(Offset(thumbX, thumbY), thumbRadius, transformLikePaint(paint)..style = PaintingStyle.fill);
  }
  
  Paint transformLikePaint(Paint original) {
    return Paint()..color = original.color; 
  }

  @override
  bool shouldRepaint(covariant _SquigglyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.value != value;
  }
}
