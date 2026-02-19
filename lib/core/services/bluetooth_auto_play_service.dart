import 'dart:async';
import 'package:audio_session/audio_session.dart';
import '../../features/songs/bloc/player_bloc.dart';
import 'user_preferences_service.dart';

class BluetoothAutoPlayService {
  final UserPreferencesService _prefs;
  final PlayerBloc _playerBloc;
  StreamSubscription? _subscription;
  Set<String> _connectedDevices = {};

  BluetoothAutoPlayService(this._prefs, this._playerBloc);

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Initial check
    _updateConnectedDevices(await session.getDevices());

    // Listen for changes
    _subscription = session.devicesStream.listen((devices) {
      _checkNewConnections(devices);
    });
  }

  void _updateConnectedDevices(Set<AudioDevice> devices) {
    _connectedDevices = devices
        .where((d) => d.type == AudioDeviceType.bluetoothA2dp || d.type == AudioDeviceType.bluetoothSco)
        .map((d) => d.name)
        .toSet();
  }

  void _checkNewConnections(Set<AudioDevice> devices) {
    final currentBtDevices = devices
        .where((d) => d.type == AudioDeviceType.bluetoothA2dp || d.type == AudioDeviceType.bluetoothSco)
        .map((d) => d.name)
        .toSet();

    final whitelist = _prefs.getBluetoothWhitelist();

    // Find new devices that weren't connected before
    final newDevices = currentBtDevices.difference(_connectedDevices);

    for (final deviceName in newDevices) {
      if (whitelist.contains(deviceName)) {
        // Trigger Auto-Play
        _playerBloc.add(ResumePlayer());
        break; // Only trigger once
      }
    }

    _connectedDevices = currentBtDevices;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
