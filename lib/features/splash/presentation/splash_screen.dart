import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../now_playing/presentation/widgets/mesh_gradient_background.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Navigate after total animation duration
    Future.delayed(const Duration(milliseconds: 4000), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dynamic Background
          MeshGradientBackground(
            dominantColor: primaryColor,
            accentColor: isDark ? Colors.purpleAccent : Colors.blueAccent,
          ).animate().fadeIn(duration: 800.ms),

          // 2. Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Living Equalizer Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: contentColor.withOpacity(0.05),
                    border: Border.all(color: contentColor.withOpacity(0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                      )
                    ]
                  ),
                  child: Center(
                    child: _AnimatedEqualizerLogo(color: contentColor),
                  ),
                )
                .animate()
                .rotate(duration: 800.ms, curve: Curves.easeOutBack, begin: -0.5, end: 0)
                .scale(duration: 800.ms, curve: Curves.easeOutBack, begin: const Offset(0.5, 0.5))
                .fadeIn(duration: 400.ms)
                .then()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .boxShadow(
                   begin: BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 30, spreadRadius: -5),
                   end: BoxShadow(color: primaryColor.withOpacity(0.6), blurRadius: 50, spreadRadius: 10),
                   duration: 1500.ms,
                   curve: Curves.easeInOut,
                ),

                const SizedBox(height: 40),

                // Cinematic Text Reveal
                _CinematicText(color: contentColor),
              ],
            ),
          ),
          
          // 3. Footer / Slogan
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Feel the Music",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  letterSpacing: 6,
                  color: contentColor.withOpacity(0.6),
                  fontWeight: FontWeight.w300
                ),
              ).animate()
               .fadeIn(delay: 2000.ms, duration: 800.ms)
               .moveY(begin: 10, end: 0, duration: 800.ms, curve: Curves.easeOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEqualizerLogo extends StatelessWidget {
  final Color color;
  const _AnimatedEqualizerLogo({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
         // Heights: Small, Tall, Medium, Small
         final targetHeight = [25.0, 45.0, 35.0, 25.0][index];
         
         return Padding(
           padding: const EdgeInsets.symmetric(horizontal: 3),
           child: Container(
             width: 8,
             height: targetHeight,
             decoration: BoxDecoration(
               color: color,
               borderRadius: BorderRadius.circular(4),
             ),
           )
           // Intro Animation: Shoot up
           .animate(delay: (400 + (index * 100)).ms)
           .moveY(begin: 50, end: 0, duration: 600.ms, curve: Curves.elasticOut)
           .fadeIn(duration: 300.ms)
           // Loop Animation: Dance
           .then()
           .animate(onPlay: (c) => c.repeat(reverse: true))
           .scaleY(
             begin: 1.0, 
             end: [0.6, 0.7, 0.5, 0.8][index], // Random-ish variation
             duration: (800 + (index * 200)).ms,
             curve: Curves.easeInOutQuad,
             alignment: Alignment.bottomCenter
           ),
         );
      }),
    );
  }
}

class _CinematicText extends StatelessWidget {
  final Color color;
  const _CinematicText({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChar('V', 0),
        _buildChar('i', 1),
        _buildChar('b', 2),
        _buildChar('e', 3),
      ],
    );
  }

  Widget _buildChar(String char, int index) {
    return Text(
      char,
      style: GoogleFonts.outfit(
        fontSize: 56, // Slightly larger
        fontWeight: FontWeight.w800, // Thicker
        color: color,
        letterSpacing: 2,
      ),
    )
    .animate(delay: (1000 + (index * 100)).ms)
    .blur(begin: const Offset(10, 10), end: Offset.zero, duration: 800.ms, curve: Curves.easeOut)
    .scale(begin: const Offset(1.5, 1.5), end: const Offset(1, 1), duration: 800.ms, curve: Curves.easeOut)
    .fadeIn(duration: 400.ms);
  }
}
