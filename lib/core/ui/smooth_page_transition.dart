import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Main entrance animation
            var curve = Curves.easeOutQuart;
            var curveTween = CurveTween(curve: curve);

            // Scale transition (subtle zoom from 0.95 to 1.0)
            var scaleTween = Tween<double>(begin: 0.95, end: 1.0).chain(curveTween);
            var scaleAnimation = animation.drive(scaleTween);

            // Fade transition
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(curveTween);
            var fadeAnimation = animation.drive(fadeTween);

            // Slide transition (gentle slide up)
            var slideTween = Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).chain(curveTween);
            var slideAnimation = animation.drive(slideTween);

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}
