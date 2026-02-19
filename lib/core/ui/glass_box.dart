import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;
  final BorderRadius? borderRadius;
  final double sigmaX;
  final double sigmaY;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const GlassBox({
    super.key,
    this.width,
    this.height,
    this.child,
    this.borderRadius,
    this.sigmaX = 20.0,
    this.sigmaY = 20.0,
    this.opacity = 0.15, // Default subtle iOS tint
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(opacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
