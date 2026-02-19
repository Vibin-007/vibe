import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class ActionFeedback {
  static void show(BuildContext context, {
    required IconData icon, 
    required String text, 
    required Color color,
    bool isBurn = false,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _FeedbackWidget(
        icon: icon, 
        text: text, 
        color: color,
        isBurn: isBurn,
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2500), () {
      entry.remove();
    });
  }
}

class _FeedbackWidget extends StatefulWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isBurn;

  const _FeedbackWidget({
    required this.icon,
    required this.text,
    required this.color,
    this.isBurn = false,
  });

  @override
  State<_FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<_FeedbackWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 2000)
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
    
    _slide = Tween<double>(begin: 30, end: -50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Optional Backdrop Blur for focus
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
                  
                  Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isBurn) 
                                 _buildFireIcon()
                              else
                                 Icon(widget.icon, size: 48, color: widget.color),
                                 
                              const SizedBox(height: 16),
                              Text(
                                widget.text,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  letterSpacing: 1.2,
                                  decoration: TextDecoration.none, // Explicitly no underline
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildFireIcon() {
     // A simple animated fire stack or just a big icon
     return Stack(
       alignment: Alignment.center,
       children: [
         Icon(Icons.local_fire_department_rounded, size: 52, color: Colors.orangeAccent),
         Icon(Icons.local_fire_department_rounded, size: 48, color: Colors.redAccent),
       ],
     );
  }
}
