import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/vibe_sync_bloc.dart';
import '../../../core/ui/glass_box.dart';

class VibeSyncScreen extends StatefulWidget {
  const VibeSyncScreen({super.key});

  @override
  State<VibeSyncScreen> createState() => _VibeSyncScreenState();
}

class _VibeSyncScreenState extends State<VibeSyncScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isScanning
          ? null
          : AppBar(
              title: const Text("Vibe Sync"),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Colors.black,
            ],
          ),
        ),
        child: BlocBuilder<VibeSyncBloc, VibeSyncState>(
          builder: (context, state) {
            if (_isScanning) {
              return _buildScanner(context);
            }

            if (state is VibeSyncHosting) {
              return _buildHostView(context, state.ip, state.requests);
            } else if (state is VibeSyncClientConnected) {
              return _buildClientView(context);
            } else if (state is VibeSyncJoining) {
              return _buildLoadingView(context, state.message);
            } else {
              return _buildMenu(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.purpleAccent),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.read<VibeSyncBloc>().add(StopSync()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hub_rounded, size: 80, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            "Sync Playback",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Host a party or join friends locally.",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 48),
          
          // Host Button
          _buildActionButton(
            context,
            "Host Party",
            Icons.wifi_tethering,
            Colors.purpleAccent,
            () => context.read<VibeSyncBloc>().add(StartHost()),
          ),
          
          const SizedBox(height: 24),

          // Join Button
          _buildActionButton(
            context,
            "Join Party",
            Icons.qr_code_scanner,
            Colors.blueAccent,
            () => setState(() => _isScanning = true),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        width: 250,
        height: 60,
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHostView(BuildContext context, String ip, List<dynamic> requests) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          const Text("You are the Host!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
              data: ip,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 24),
          Text("Scan to join: $ip", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          
          if (requests.isNotEmpty) ...[
             const Text("Join Requests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 12),
             Container(
               height: 150,
               constraints: const BoxConstraints(maxWidth: 350),
               child: ListView.builder(
                 itemCount: requests.length,
                 itemBuilder: (context, index) {
                   final req = requests[index];
                   return Card(
                     color: Colors.grey[900],
                     child: ListTile(
                       leading: const Icon(Icons.person, color: Colors.white),
                       title: Text(req.name, style: const TextStyle(color: Colors.white)),
                       subtitle: const Text("Wants to join", style: TextStyle(color: Colors.grey)),
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.check, color: Colors.green),
                             onPressed: () => context.read<VibeSyncBloc>().add(AcceptJoinRequest(req.id)),
                           ),
                           IconButton(
                             icon: const Icon(Icons.close, color: Colors.red),
                             onPressed: () => context.read<VibeSyncBloc>().add(DeclineJoinRequest(req.id)),
                           ),
                         ],
                       ),
                     ),
                   );
                 },
               ),
             ),
          ],
          
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.read<VibeSyncBloc>().add(StopSync()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("Stop Party"),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildClientView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
          const SizedBox(height: 24),
          const Text("Connected to Host!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const SizedBox(height: 16),
          const Text("Playback is being synced.", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.read<VibeSyncBloc>().add(StopSync()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 280,
    );

    return Stack(
      children: [
        MobileScanner(
          scanWindow: scanWindow,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                // Assuming IP is raw value for now
                final ip = barcode.rawValue!;
                setState(() => _isScanning = false);
                context.read<VibeSyncBloc>().add(JoinHost(ip));
                break; // Stop after first detection
              }
            }
          },
        ),
        CustomPaint(
          painter: ScannerOverlayPainter(scanWindow),
          child: Container(),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              "Align QR Code within the frame",
              style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)));

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundPathFinal = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Draw the dark background with cutout
    canvas.drawPath(backgroundPathFinal, Paint()..color = Colors.black.withOpacity(0.6));

    // Draw the border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)), borderPaint);
    
    // Optional: Draw Corners
    _drawCorners(canvas, scanWindow);
  }
  
  void _drawCorners(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
      
    double cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLength), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLength, 0), paint);
    
    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLength), paint);
    canvas.drawLine(rect.topRight, rect.topRight - Offset(cornerLength, 0), paint);
    
    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft - Offset(0, cornerLength), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), paint);
    
    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(0, cornerLength), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(cornerLength, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
