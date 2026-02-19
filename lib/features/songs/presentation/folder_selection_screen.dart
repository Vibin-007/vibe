import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/user_preferences_service.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_event.dart';

class FolderSelectionScreen extends StatefulWidget {
  const FolderSelectionScreen({super.key});

  @override
  State<FolderSelectionScreen> createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<String> _allFolders = [];
  List<String> _includedFolders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = context.read<UserPreferencesService>();
    _includedFolders = List.from(prefs.getIncludedFolders());

    // Scan for all folders containing music
    // We use QueryArtworkWidget or just generic query
    try {
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final folders = <String>{};
      for (var song in songs) {
        final path = song.data;
        final dir = p.dirname(path);
        folders.add(dir);
      }
      
      _allFolders = folders.toList()..sort();
    } catch (e) {
      debugPrint('Error scanning folders: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final prefs = context.read<UserPreferencesService>();
    await prefs.setIncludedFolders(_includedFolders);
    if (mounted) {
      // Refresh library
      context.read<SongsBloc>().add(LoadSongs());
      Navigator.pop(context);
    }
  }

  void _toggleFolder(String path) {
    setState(() {
      if (_includedFolders.contains(path)) {
        _includedFolders.remove(path);
      } else {
        _includedFolders.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Include Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allFolders.isEmpty
              ? const Center(child: Text('No music folders found'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select folders to include in your library. If no folders are selected, all music will be shown.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _allFolders.length,
                        itemBuilder: (context, index) {
                          final folder = _allFolders[index];
                          final isSelected = _includedFolders.contains(folder);
                          final folderName = p.basename(folder);

                          return CheckboxListTile(
                            title: Text(folderName),
                            subtitle: Text(folder, style: const TextStyle(fontSize: 12)),
                            value: isSelected,
                            activeColor: primaryColor,
                            onChanged: (_) => _toggleFolder(folder),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
