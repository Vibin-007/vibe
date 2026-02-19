import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_event.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  late List<String> _excludedFolders;
  late int _minDuration;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesService>();
    _excludedFolders = List.from(prefs.getExcludedFolders());
    _minDuration = prefs.getBlacklistMinDuration();
  }

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (!_excludedFolders.contains(selectedDirectory)) {
        setState(() {
          _excludedFolders.add(selectedDirectory);
        });
        await context.read<UserPreferencesService>().setExcludedFolders(_excludedFolders);
        // Reload songs to apply filter
        if (mounted) context.read<SongsBloc>().add(LoadSongs());
      }
    }
  }

  Future<void> _removeFolder(String path) async {
    setState(() {
      _excludedFolders.remove(path);
    });
    await context.read<UserPreferencesService>().setExcludedFolders(_excludedFolders);
    if (mounted) context.read<SongsBloc>().add(LoadSongs());
  }

  Future<void> _updateDuration(int seconds) async {
    setState(() => _minDuration = seconds);
    await context.read<UserPreferencesService>().setBlacklistMinDuration(seconds);
    if (mounted) context.read<SongsBloc>().add(LoadSongs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Blacklist Manager'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDurationSection(),
          const SizedBox(height: 24),
          _buildFolderSection(),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_off_outlined, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ignore Short Audio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                '${_minDuration}s',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hide files shorter than this duration (e.g., WhatsApp voice notes).',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Slider(
            value: _minDuration.toDouble(),
            min: 0,
            max: 300,
            divisions: 60,
            activeColor: Colors.orangeAccent,
            label: '${_minDuration}s',
            onChanged: (val) {
              setState(() => _minDuration = val.toInt());
            },
            onChangeEnd: (val) => _updateDuration(val.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Excluded Folders',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              onPressed: _pickFolder,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_excludedFolders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No folders excluded.\nAll music folders are visible.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._excludedFolders.map((path) {
            final name = path.split('/').last;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.folder_off_outlined, color: Colors.redAccent),
                title: Text(name.isEmpty ? path : name),
                subtitle: Text(path, style: const TextStyle(fontSize: 10)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _removeFolder(path),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
