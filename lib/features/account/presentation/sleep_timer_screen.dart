import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/songs/bloc/player_bloc.dart';
import '../../now_playing/presentation/widgets/mesh_gradient_background.dart';
import '../../../core/ui/vibe_app_bar.dart';

class SleepTimerScreen extends StatefulWidget {
  const SleepTimerScreen({super.key});

  @override
  State<SleepTimerScreen> createState() => _SleepTimerScreenState();
}

class _SleepTimerScreenState extends State<SleepTimerScreen> {
  // Max duration 120 minutes
  double _currentMinutes = 0;
  bool _isDragging = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncWithBloc();
    // Start periodic ticker to update UI every second if timer is active
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDragging && mounted) {
        _syncWithBloc();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncWithBloc() {
    final state = context.read<PlayerBloc>().state;
    if (state.sleepTimerEndTime != null) {
      final remaining = state.sleepTimerEndTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        setState(() => _currentMinutes = 0);
      } else {
        setState(() {
          // Calculate total minutes including seconds as fraction for smooth dial
          _currentMinutes = remaining.inSeconds / 60.0; 
        });
      }
    } else if (!_isDragging && _currentMinutes > 0 && _currentMinutes < 0.1) {
       // Reset to 0 if we were counting down and finished
       setState(() => _currentMinutes = 0);
    }
  }

  void _updateFromAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    
    // -pi to pi, starting from 3 o'clock
    var angle = math.atan2(dy, dx);
    
    // Normalize to 0-1 (starting from -pi/2 which is 12 o'clock)
    angle += math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    // Map 0 -> 2pi to 0 -> 120 minutes
    var minutes = (angle / (2 * math.pi)) * 120;
    
    // Snap to nearest 5 minutes for cleaner UX, but keep precise when dragging
    minutes = (minutes / 5).round() * 5.0;

    setState(() {
      _currentMinutes = minutes.clamp(0, 120);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final state = context.watch<PlayerBloc>().state;
    final isTimerActive = state.sleepTimerEndTime != null && state.sleepTimerEndTime!.isAfter(DateTime.now());
    
    // display minutes as integer for main text, unless it's < 1 minute then show "0" or seconds?
    // User asked for "Realtime time", so maybe show MM:SS if < 1 minute?
    // Let's stick to minutes for the big number but maybe update the subtitle.
    
    final displayMinutes = _currentMinutes.ceil();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const VibeAppBar(title: 'Sleep Timer'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Space Background
          Container(
            color: const Color(0xFF0F172A), // Deep Blue/Black
          ),
          MeshGradientBackground(
             dominantColor: Colors.deepPurple,
             accentColor: Colors.indigo,
          ).animate().fadeIn(),
          
          // Stars
          const _StarryBackground(),

          // 2. Main Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Moon Dial
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() => _isDragging = true);
                        _updateFromAngle(details.localPosition, const Size(300, 300));
                      },
                      onPanUpdate: (details) {
                        _updateFromAngle(details.localPosition, const Size(300, 300));
                      },
                      onPanEnd: (_) {
                         setState(() => _isDragging = false);
                         // Optional: Auto-start on release? No, wait for button.
                      },
                      child: CustomPaint(
                        painter: _MoonDialPainter(
                          minutes: _currentMinutes,
                          primaryColor: Colors.white,
                          accentColor: primaryColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayMinutes',
                                style: GoogleFonts.outfit(
                                  fontSize: 80, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white
                                ),
                              ),
                              Text(
                                'MINUTES',
                                style: GoogleFonts.outfit(
                                  fontSize: 16, 
                                  letterSpacing: 2,
                                  color: Colors.white70
                                ),
                              ),
                              // Live feedback text
                              if (_currentMinutes > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isTimerActive && !_isDragging ? Colors.green.withOpacity(0.2) : Colors.white10,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isTimerActive && !_isDragging ? Colors.green.withOpacity(0.3) : Colors.transparent)
                                    ),
                                    child: Text(
                                      (isTimerActive && !_isDragging)
                                        ? 'Active - Stops in ${displayMinutes}m'
                                        : 'Stops at ${_formatTime(DateTime.now().add(Duration(minutes: displayMinutes)))}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: (isTimerActive && !_isDragging) ? Colors.greenAccent : Colors.blue[100]
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Quick Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [15, 30, 60, 90].map((m) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                         setState(() {
                           _currentMinutes = m.toDouble();
                           _isDragging = false; // Stop following bloc temporarily until set
                         });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                           color: displayMinutes == m ? primaryColor : Colors.white10,
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '$m m', 
                          style: TextStyle(
                            color: displayMinutes == m ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                const Spacer(),

                // Start/Stop Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                         if (isTimerActive && !_isDragging && _currentMinutes == state.sleepTimerEndTime!.difference(DateTime.now()).inSeconds/60.0) {
                           // If active and we haven't touched the dial, button turns off
                           context.read<PlayerBloc>().add(SetSleepTimer(null));
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                             content: Text('Sleep timer turned off'),
                             behavior: SnackBarBehavior.floating,
                           ));
                         } else if (isTimerActive && (_isDragging || _currentMinutes != state.sleepTimerEndTime!.difference(DateTime.now()).inSeconds/60.0)) {
                            // If active BUT user changed dial, button UPDATES timer
                            context.read<PlayerBloc>().add(SetSleepTimer(Duration(minutes: displayMinutes)));
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                             content: Text('Timer updated to $displayMinutes minutes'),
                             backgroundColor: Colors.indigo,
                             behavior: SnackBarBehavior.floating,
                           ));
                         } else if (!isTimerActive && _currentMinutes > 0) {
                           // If NOT active, start it
                           context.read<PlayerBloc>().add(SetSleepTimer(Duration(minutes: displayMinutes)));
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                             content: Text('Dreaming in $displayMinutes minutes...'),
                             backgroundColor: Colors.indigo,
                             behavior: SnackBarBehavior.floating,
                           ));
                         } else {
                           // 0 minutes, do nothing or turn off
                           context.read<PlayerBloc>().add(SetSleepTimer(null));
                         }
                         Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isTimerActive && !_isDragging) ? Colors.redAccent.withOpacity(0.9) : Colors.white,
                        foregroundColor: (isTimerActive && !_isDragging) ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: Text(
                        (isTimerActive && !_isDragging) 
                           ? 'STOP TIMER' 
                           : (isTimerActive ? 'UPDATE TIMER' : 'START SLEEP TIMER'),
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}

class _MoonDialPainter extends CustomPainter {
  final double minutes;
  final Color primaryColor;
  final Color accentColor;

  _MoonDialPainter({required this.minutes, required this.primaryColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // 1. Tick Marks (Background)
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 60; i+=5) { // 5-minute ticks
        final isMajor = i % 15 == 0;
        final angle = (i * 6) * (math.pi / 180) - math.pi / 2; // 6 degrees per minute
        final outerR = radius + (isMajor ? 10 : 5);
        final innerR = radius - (isMajor ? 10 : 5);
        
        tickPaint.color = isMajor ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1);
        tickPaint.strokeWidth = isMajor ? 3 : 1;
        
        canvas.drawLine(
          center + Offset(math.cos(angle) * innerR, math.sin(angle) * innerR),
          center + Offset(math.cos(angle) * outerR, math.sin(angle) * outerR),
          tickPaint
        );
    }

    // 2. Main Track Ring
    canvas.drawCircle(
      center, 
      radius, 
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
    );

    // 3. Active Arc (Progress)
    if (minutes > 0) {
      final sweepAngle = (minutes / 120) * 2 * math.pi; // Max 120 mins = full circle
      final activePaint = Paint()
        ..shader = ui.Gradient.sweep(
          center, 
          [Colors.blue.withOpacity(0.5), Colors.purpleAccent, Colors.white],
          [0.0, 0.7, 1.0],
          TileMode.clamp,
          -math.pi / 2, 
          -math.pi / 2 + sweepAngle,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 
        -math.pi / 2, 
        sweepAngle, 
        false, 
        activePaint
      );
      
      // 4. Moon Handle (Thumb)
      final thumbAngle = -math.pi / 2 + sweepAngle;
      final thumbX = center.dx + radius * math.cos(thumbAngle);
      final thumbY = center.dy + radius * math.sin(thumbAngle);
      
      // Glow
      final glowPaint = Paint()
        ..color = Colors.purpleAccent.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(thumbX, thumbY), 15, glowPaint);

      // Core
      final thumbPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoonDialPainter oldDelegate) => oldDelegate.minutes != minutes;
}

class _StarryBackground extends StatelessWidget {
  const _StarryBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand( // CORRECTED: Ensures full screen coverage
      child: CustomPaint(
        painter: _StarPainter(),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  // Use a fixed list of stable stars
  static final List<Offset> _stars = List.generate(100, (index) {
    final r = math.Random(index);
    return Offset(r.nextDouble(), r.nextDouble());
  });
  
  static final List<double> _sizes = List.generate(100, (index) => math.Random(index).nextDouble() * 2 + 1);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    
    for (int i = 0; i < _stars.length; i++) {
        // Vary opacity for twinkling effect simulation if desired, keeping simple for now
        paint.color = Colors.white.withOpacity(0.3 + (_sizes[i] % 0.5));
        canvas.drawCircle(
          Offset(_stars[i].dx * size.width, _stars[i].dy * size.height), 
          _sizes[i], 
          paint
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
