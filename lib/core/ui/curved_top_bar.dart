import 'package:flutter/material.dart';
import '../../core/ui/glass_box.dart';

class CurvedTopBar extends StatelessWidget {
  final Widget centerWidget;
  final List<Widget> leftActions;
  final List<Widget> rightActions;
  final double height;

  const CurvedTopBar({
    super.key,
    required this.centerWidget,
    required this.leftActions,
    required this.rightActions,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background Shape
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, height),
            painter: _CurvedTopPainter(
              color: Theme.of(context).primaryColor.withOpacity(0.9), // Solid/Semi-transparent brand color
              shadowColor: Colors.black.withOpacity(0.3),
            ),
          ),
          
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 60, // Content height inside the bar
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                  children: [
                    // Left Actions
                    Row(
                      children: leftActions,
                    ),
                    
                    // Center Space (occupied by curve)
                    const SizedBox(width: 80), 
                    
                    // Right Actions
                    Row(
                      children: rightActions,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Center Widget (Floating in the curve)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              shape: const CircleBorder(),
              child: CircleAvatar(
                radius: 30, // Big center circle
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: centerWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedTopPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _CurvedTopPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    
    // Config
    final double curveHeight = 50;
    final double curveWidth = 100;
    final double centerX = size.width / 2;
    
    // Draw Top Line with Notch
    path.moveTo(0, 0);
    // Line to start of curve
    path.lineTo(centerX - curveWidth / 2 - 20, 0);
    
    // The Notch Curve
    path.cubicTo(
      centerX - curveWidth / 2, 0, // Control point 1
      centerX - curveWidth / 2, curveHeight, // Control point 2
      centerX, curveHeight, // End point (middle bottom of curve)
    );
    path.cubicTo(
      centerX + curveWidth / 2, curveHeight, // Control point 1
      centerX + curveWidth / 2, 0, // Control point 2
      centerX + curveWidth / 2 + 20, 0, // End point
    );
    
    // Complete outline
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height); // Bottom Right - wait, standard TopBar usually ends?
    // Actually typically a top bar is just the bar. 
    // The user image shows the bar IS standard height on sides, but DIPS in the middle.
    // So the bottom edge is NOT straight if the "bar" follows the dip?
    // No, usually "inverted bottom app bar" means the TOP edge is straight, and the BOTTOM edge has the dip.
    // WAIT. Re-reading image: "blue bar at top, dipping DOWN in the middle".
    // So top edge is straight (status bar side). Bottom edge has the dip.
    
    // My path above started at 0,0 (Top Left) and drew the curve along the TOP edge. THAT IS WRONG for a Top Bar notch.
    // A Top Bar notch usually hangs DOWN from the bar.
    // Let's restart path logic.
    
    path.reset();
    path.moveTo(0, 0); // Top Left
    path.lineTo(size.width, 0); // Top Right
    path.lineTo(size.width, 80); // Bottom Right (Bar Height ~80)
    
    // Bottom Edge Curve (Moving Right to Left?)
    // No, let's draw distinct shape.
    
    // Let's assume height is the total height including the dip.
    // Side height might be smaller, e.g. 60.
    final sideHeight = 70.0;
    
    // We are at Bottom Right of the full box (size.width, size.height) ?? No.
    // Let's draw counter-clockwise or clockwise. 
    // Top-Left -> Top-Right
    path.lineTo(size.width, sideHeight); // Down to side bottom
    
    // Curve logic from Right to Left
    // Line to start of right curve
    path.lineTo(centerX + curveWidth / 2 + 10, sideHeight);
    
    // Curve Down
    path.cubicTo(
      centerX + curveWidth / 2, sideHeight,
      centerX + curveWidth / 2, size.height, // Dip absolute bottom
      centerX, size.height,
    );
    
    // Curve Up
    path.cubicTo(
      centerX - curveWidth / 2, size.height,
      centerX - curveWidth / 2, sideHeight,
      centerX - curveWidth / 2 - 10, sideHeight,
    );
    
    path.lineTo(0, sideHeight);
    path.close();

    // Draw Shadow
    canvas.drawPath(path, shadowPaint);
    // Draw Shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
