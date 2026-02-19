import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/user_preferences_service.dart';

class BluetoothSettingsScreen extends StatefulWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  State<BluetoothSettingsScreen> createState() => _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends State<BluetoothSettingsScreen> {
  List<AudioDevice> _connectedDevices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scanForDevices();
  }

  Future<void> _scanForDevices() async {
    setState(() => _scanning = true);
    try {
      final session = await AudioSession.instance;
      // Ensure configured to see devices (though service does this too)
      await session.configure(const AudioSessionConfiguration.music());
      final devices = await session.getDevices();
      final uniqueDevices = <String, AudioDevice>{};
      
      for (var d in devices) {
        if (d.type == AudioDeviceType.bluetoothA2dp || d.type == AudioDeviceType.bluetoothSco) {
           // Use name as key to ensure uniqueness as requested by user ("shows 3")
           // If multiple profiles exist (A2DP vs Headset), just keep one for the UI.
           uniqueDevices[d.name] = d;
        }
      }

      setState(() {
        _connectedDevices = uniqueDevices.values.toList();
      });
    } catch (e) {
      debugPrint("Error scanning devices: $e");
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<UserPreferencesService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Auto-Play'),
      ),
      body: StreamBuilder<void>(
        stream: prefs.dataStream,
        builder: (context, _) {
          final whitelist = prefs.getBluetoothWhitelist();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Theme.of(context).primaryColor.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.bluetooth_audio_rounded, color: Theme.of(context).primaryColor, size: 32),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Text(
                         'Music will automatically resume when these devices connect.',
                         style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 24),
               Text(
                 'Trusted Devices', 
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
               ),
               const SizedBox(height: 8),
               if (whitelist.isEmpty)
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 16),
                   child: Text('No devices added yet.', style: TextStyle(color: Colors.grey)),
                 )
               else
                 ...whitelist.map((name) => Card(
                   margin: const EdgeInsets.only(bottom: 8),
                   child: ListTile(
                     leading: const Icon(Icons.headset_rounded),
                     title: Text(name),
                     trailing: IconButton(
                       icon: const Icon(Icons.delete_outline, color: Colors.red),
                       onPressed: () => prefs.removeBluetoothDevice(name),
                     ),
                   ),
                 )),

               const SizedBox(height: 32),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     'Connected Devices', 
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                   ),
                   if (_scanning)
                     const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                   else
                     IconButton(
                       icon: const Icon(Icons.refresh),
                       onPressed: _scanForDevices,
                       tooltip: 'Scan for devices',
                     )
                 ],
               ),
               const SizedBox(height: 8),
               if (_connectedDevices.isEmpty)
                  Padding(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   child: Text(
                     _scanning ? 'Scanning...' : 'No Bluetooth audio devices found matching A2DP/SCO profile.', 
                     style: const TextStyle(color: Colors.grey)
                   ),
                 )
               else
                 ..._connectedDevices.map((device) {
                   final isAdded = whitelist.contains(device.name);
                   return Card(
                     margin: const EdgeInsets.only(bottom: 8),
                     color: isAdded ? Theme.of(context).disabledColor.withOpacity(0.1) : null,
                     child: ListTile(
                       leading: const Icon(Icons.bluetooth_connected),
                       title: Text(device.name),
                       subtitle: Text(device.type.toString().split('.').last),
                       trailing: isAdded 
                         ? const Icon(Icons.check_circle, color: Colors.green)
                         : ElevatedButton(
                             onPressed: () => prefs.addBluetoothDevice(device.name),
                             child: const Text('Trust'),
                           ),
                     ),
                   );
                 }),
            ],
          );
        },
      ),
    );
  }
}
