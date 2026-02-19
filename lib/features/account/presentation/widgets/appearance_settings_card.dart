import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../../core/bloc/theme_bloc.dart';
import 'dart:ui'; // For standard BackdropFilter

class AppearanceSettingsCard extends StatefulWidget {
  const AppearanceSettingsCard({super.key});

  @override
  State<AppearanceSettingsCard> createState() => _AppearanceSettingsCardState();
}

class _AppearanceSettingsCardState extends State<AppearanceSettingsCard> {
  // Local state for drag interaction
  double _dragAlignment = 0.0;
  bool _isDragging = false;
  
  // Track if we are currently "holding" a theme visually separate from the bloc state
  ThemeMode? _optimisticTheme;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final currentMode = _optimisticTheme ?? state.themeMode;
        final isLight = currentMode == ThemeMode.light;
        
        // Alignment: -1.0 (Left/Light) to 1.0 (Right/Dark)
        final targetAlignment = isLight ? -1.0 : 1.0;
        
        // If getting updates from outside (or initial), sync drag alignment
        if (!_isDragging && _optimisticTheme == null) {
          _dragAlignment = targetAlignment;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLight 
                              ? Colors.orangeAccent.withOpacity(0.1) 
                              : Colors.indigoAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLight ? Icons.wb_sunny_rounded : Icons.nightlight_round, 
                          color: isLight ? Colors.orange : Colors.indigoAccent, 
                          size: 24
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Appearance",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          Text(
                            isLight ? "Day Mode" : "Night Mode",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // --- THE HORIZON TOGGLE ---
              GestureDetector(
                onTap: () {
                   final newMode = isLight ? ThemeMode.dark : ThemeMode.light;
                   context.read<ThemeBloc>().add(ChangeTheme(newMode));
                },
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    // Initialize alignment based on current state if starting fresh drag
                    _dragAlignment = isLight ? -1.0 : 1.0;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    // Update alignment based on drag delta
                    double sensitivity = 150.0;
                    _dragAlignment += details.delta.dx / (sensitivity / 2); // 2.0 range (-1 to 1)
                    _dragAlignment = _dragAlignment.clamp(-1.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (details) {
                  setState(() {
                     _isDragging = false;
                     // Velocity boost
                     _dragAlignment += details.primaryVelocity! / 500.0;
                     
                     // Snap logic
                     final isFlingRight = details.primaryVelocity! > 200;
                     final isFlingLeft = details.primaryVelocity! < -200;
                     
                     ThemeMode targetTheme;
                     if (isFlingRight) {
                        targetTheme = ThemeMode.dark;
                     } else if (isFlingLeft) {
                        targetTheme = ThemeMode.light;
                     } else {
                        // Snap to nearest half
                        targetTheme = _dragAlignment > 0 ? ThemeMode.dark : ThemeMode.light;
                     }
                     
                     _optimisticTheme = targetTheme;
                     context.read<ThemeBloc>().add(ChangeTheme(targetTheme));
                     
                     // Reset optimistic state after animation would complete to allow bloc to take over
                     Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) setState(() => _optimisticTheme = null);
                     });
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isLight 
                          ? [const Color(0xFFFF9E80), const Color(0xFF80D8FF)] // Sunrise: Orange -> Sky
                          : [const Color(0xFF1A237E), const Color(0xFF4A148C)], // Midnight: Navy -> Deep Violet
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight ? Colors.orangeAccent.withOpacity(0.3) : Colors.indigoAccent.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  child: Stack(
                    children: [
                      // STARS (Micro-interaction for Dark Mode)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: isLight ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: const _StarField(),
                        ),
                      ),
                      
                      // CLOUDS (Micro-interaction for Light Mode)
                      Positioned.fill(
                        child: AnimatedOpacity(
                           opacity: isLight ? 0.6 : 0.0,
                           duration: const Duration(milliseconds: 500),
                           child: const _CloudField(),
                        ),
                      ),
                      
                      // THE ORB (Sun / Moon)
                      Align(
                        alignment: Alignment(_isDragging ? _dragAlignment : (isLight ? -1.0 : 1.0), 0.0),
                        child: AnimatedContainer(
                          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 750),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 750),
                              curve: Curves.easeOutCubic,
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.25),
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: Offset(isLight ? 2 : -2, 4) // Dynamic shadow shift
                                  )
                                ]
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Smoother frost
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       gradient: LinearGradient(
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                         colors: isLight 
                                            ? [const Color(0xFFFFE082), const Color(0xFFFFB74D)] 
                                            : [const Color(0xFFCFD8DC), const Color(0xFFB0BEC5)], 
                                       )
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      transitionBuilder: (child, anim) {
                                        return RotationTransition(
                                          turns: isLight 
                                             ? Tween(begin: 0.5, end: 1.0).animate(anim) 
                                             : Tween(begin: 0.5, end: 1.0).animate(anim), 
                                          child: ScaleTransition(scale: anim, child: child)
                                        );
                                      },
                                      child: Icon(
                                        isLight ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                                        key: ValueKey(isLight),
                                        color: isLight ? Colors.white : Colors.blueGrey[900],
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Micro-Animations ---

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42); // Fixed seed for stable stars
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
    
    for (int i = 0; i < 15; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), 
        rnd.nextDouble() * 2, 
        paint
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloudField extends StatelessWidget {
  const _CloudField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CloudPainter());
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.4), 25, paint);
    
    // Another cloud
     canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 15, paint);
     canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.6), 20, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
