import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'folder_detail_screen.dart';
import '../../../core/ui/smooth_page_transition.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/ui/glass_box.dart';
import '../bloc/songs_bloc.dart';
import '../bloc/songs_state.dart';
import '../bloc/songs_event.dart';
import '../bloc/player_bloc.dart';
import '../../../core/theme/app_colors.dart';

import 'package:music_world/features/playlist/bloc/playlist_bloc.dart';
import '../../../core/ui/song_list_tile.dart';
import '../../../core/ui/swipe_queue_tile.dart';
import '../../../core/ui/song_grid_tile.dart'; // Restored
import '../../../core/ui/folder_grid_tile.dart'; // Restored
import 'dart:async';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // Tab State: 0 = Songs, 1 = Folders
  int _currentTab = 1; 

  // ... caches ...
  List<SongModel>? _lastAllSongs;
  String? _lastSearchQuery;
  List<SongModel> _filteredSongsCache = [];
  Map<String, List<SongModel>> _foldersCache = {};
  List<String> _sortedFoldersCache = [];

  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesService>();
    _currentTab = prefs.isFoldersDefault() ? 1 : 0;
  }

  void _updateCaches(List<SongModel> allSongs) {
     if (_lastAllSongs == allSongs && _lastSearchQuery == _searchQuery) return; 

    _lastAllSongs = allSongs;
    _lastSearchQuery = _searchQuery;

    final query = _searchQuery.toLowerCase();
    _filteredSongsCache = allSongs.where((song) {
      return song.title.toLowerCase().contains(query) || 
             (song.artist?.toLowerCase().contains(query) ?? false);
    }).toList();
    
    // Update Folders
    _foldersCache = {};
    for (var song in allSongs) {
      final path = _getParentPath(song.data);
      if (!_foldersCache.containsKey(path)) {
        _foldersCache[path] = [];
      }
      _foldersCache[path]!.add(song);
    }
    
    _sortedFoldersCache = _foldersCache.keys.toList()..sort();
  }

  void _showFeedback(BuildContext context, String message) {
     final overlay = Overlay.of(context);
     final overlayEntry = OverlayEntry(
       builder: (context) => Positioned(
         top: MediaQuery.of(context).padding.top + 10,
         left: 20,
         right: 20,
         child: Material(
           color: Colors.transparent,
           child: TweenAnimationBuilder<double>(
             tween: Tween(begin: 0.0, end: 1.0),
             duration: const Duration(milliseconds: 500),
             curve: Curves.elasticOut,
             builder: (context, value, child) {
               return Transform.scale(
                 scale: value,
                 child: Transform.translate(
                   offset: Offset(0, (1 - value) * -50),
                   child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                 ),
               );
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               decoration: BoxDecoration(
                 color: Theme.of(context).cardColor,
                 borderRadius: BorderRadius.circular(30),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.2),
                     blurRadius: 10,
                     offset: const Offset(0, 5),
                   )
                 ],
                 border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 1.5),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor, size: 24),
                   const SizedBox(width: 12),
                   Flexible(
                     child: Text(
                       message, 
                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     );

     overlay.insert(overlayEntry);
     Future.delayed(const Duration(seconds: 2), () {
       overlayEntry.remove();
     });
  }

  void _showSongOptions(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          final playlistsContainingSong = state.playlists.entries
              .where((e) => e.value.contains(song.id.toString()) && e.key != 'Recently Played' && e.key != 'Most Played')
              .map((e) => e.key)
              .toList();
          
          final userPlaylists = state.playlists.keys
              .where((name) => name != 'Recently Played' && name != 'Most Played')
              .toList();

          final canAdd = userPlaylists.length > playlistsContainingSong.length;
          final canRemove = playlistsContainingSong.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  ListTile(
                    leading: Icon(Icons.playlist_play_rounded, color: Theme.of(context).iconTheme.color),
                    title: const Text('Play Next'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PlayerBloc>().add(PlayNextEvent(song));
                      _showFeedback(context, "Playing next: ${song.title}");
                    },
                  ),
                  if (canAdd)
                    ListTile(
                      leading: Icon(Icons.playlist_add_rounded, color: Theme.of(context).iconTheme.color),
                      title: const Text('Add to Playlist'),
                      onTap: () {
                        Navigator.pop(context);
                        _showPlaylistDialog(song);
                      },
                    ),
                  if (canRemove)
                    ListTile(
                      leading: const Icon(Icons.playlist_remove_rounded, color: Colors.redAccent),
                      title: const Text('Remove from Playlist', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(context);
                        _showRemovePlaylistDialog(song, playlistsContainingSong);
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.queue_music_rounded, color: Theme.of(context).iconTheme.color),
                    title: const Text('Add to Queue'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PlayerBloc>().add(AddToQueue(song));
                      _showFeedback(context, "Added to queue: ${song.title}");
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlaylistDialog(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            final playlists = state.playlists.keys
                .where((name) => 
                  name != 'Recently Played' && 
                  name != 'Most Played' && 
                  !state.playlists[name]!.contains(song.id.toString())
                )
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Already in all playlists or no playlists created.'),
                  ),
                ...playlists.map((name) => ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: Text(name),
                  onTap: () {
                    context.read<PlaylistBloc>().add(AddToPlaylist(name, song));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to $name')),
                    );
                  },
                )),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRemovePlaylistDialog(SongModel song, List<String> playlists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Remove from Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ),
            ...playlists.map((name) => ListTile(
              leading: const Icon(Icons.playlist_remove_rounded, color: Colors.redAccent),
              title: Text(name),
              onTap: () {
                context.read<PlaylistBloc>().add(RemoveFromPlaylist(name, song.id));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed from $name')),
                );
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // ... existing methods ...

  // Helper to get folder name from path
  String _getFolderName(String path) {
    if (path.isEmpty) return "Unknown";
    final parts = path.split('/');
    // Use last part if it's the folder name, or second to last if path ends with /
    if (parts.last.isEmpty && parts.length > 1) return parts[parts.length - 2];
    return parts.last;
  }
  
  // Helper to get parent folder path
  String _getParentPath(String path) {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1) return path;
    return path.substring(0, lastSlash);
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = context.read<UserPreferencesService>(); 
    
    return StreamBuilder<void>(
      stream: userPrefs.dataStream,
      builder: (context, _) {
        final viewMode = userPrefs.getSongsViewMode();
        final isGrid = viewMode == 'grid';

    return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, state) {
        if (state is SongsLoading) {
          return Center(child: CircularProgressIndicator(color: AppColors.darkAccent));
        }

        if (state is PermissionDenied) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storage_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("Storage permission needed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(" Grant permission to load your local music", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<SongsBloc>().add(RequestPermission()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Grant Permission"),
                ),
              ],
            ),
          );
        }

        if (state is SongsLoaded) {
          final allSongs = state.songs;
          _updateCaches(allSongs);
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 80), 
                sliver: SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  toolbarHeight: 0, 
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(140), 
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded), 
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = "");
                                      })
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              _buildTabButton("Songs", _currentTab == 0, () {
                                setState(() {
                                  _currentTab = 0;
                                  _searchQuery = "";
                                   _searchController.clear();
                                });
                              }),
                              const SizedBox(width: 8),
                              _buildTabButton("Folders", _currentTab == 1, () {
                                setState(() {
                                  _currentTab = 1;
                                  _searchQuery = "";
                                  _searchController.clear();
                                });
                              }),
                              const SizedBox(width: 8),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
                                  onPressed: () {
                                    userPrefs.setSongsViewMode(isGrid ? 'list' : 'grid');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                         const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              
              if (_currentTab == 1)
                _buildFoldersView(allSongs, isGrid)
              else
                _buildSongsView(allSongs, isGrid),

              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        }

        return const SizedBox();
      },
    );
      });
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Set '${label}' as Default?"),
              content: Text("This view will open automatically when you start the app."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final isFolders = label == "Folders";
                    context.read<UserPreferencesService>().setFoldersDefault(isFolders);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$label set as default view")),
                    );
                  }, 
                  child: const Text("Set Default")
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongsView(List<SongModel> allSongs, bool isGrid) {
    if (_filteredSongsCache.isEmpty) {
       return const SliverFillRemaining(
         child: Center(child: Text("No songs found", style: TextStyle(color: Colors.grey))),
       );
    }
    
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) => previous.currentItem?.id != current.currentItem?.id || previous.isPlaying != current.isPlaying,
      builder: (context, playerState) {
        final currentId = playerState.currentItem?.id;

        if (isGrid) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.70, // Reverted to 3 items
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _filteredSongsCache[index];
                  final currentItem = context.read<PlayerBloc>().state.currentItem;
                  final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                  final isPlaying = song.id.toString() == playingId;
                  
                  return SongGridTile(
                    song: song,
                    isPlaying: isPlaying,
                    onTap: () {
                       HapticFeedback.lightImpact();
                       context.read<PlayerBloc>().add(PlaySong(_filteredSongsCache, index));
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showSongOptions(song);
                    },
                    onMoreTap: () => _showSongOptions(song),
                  );
                },
                childCount: _filteredSongsCache.length,
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = _filteredSongsCache[index];
              final currentItem = playerState.currentItem;
              final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
              final isPlaying = song.id.toString() == playingId;

              return SwipeQueueTile(
                song: song,
                isPlaying: isPlaying,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<PlayerBloc>().add(PlaySong(_filteredSongsCache, index));
                },
                onMoreTap: () => _showSongOptions(song),
              );
            },
            childCount: _filteredSongsCache.length,
          ),
        );
      },
    );
  }

  Widget _buildFoldersView(List<SongModel> allSongs, bool isGrid) {
    if (_sortedFoldersCache.isEmpty) {
       return const SliverFillRemaining(
         child: Center(child: Text("No folders found", style: TextStyle(color: Colors.grey))),
       );
    }

    if (isGrid) {
       return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final path = _sortedFoldersCache[index];
              final name = _getFolderName(path);
              final count = _foldersCache[path]?.length ?? 0;
              final folderSongs = _foldersCache[path] ?? [];
              
              return FolderGridTile(
                name: name,
                songCount: count,
                songs: folderSongs,
                onTap: () {
                   Navigator.push(
                     context,
                     SmoothPageRoute(
                       child: FolderDetailScreen(
                         folderPath: path,
                         folderName: name,
                         songs: folderSongs,
                       ),
                     ),
                   );
                },
              );
            },
            childCount: _sortedFoldersCache.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final path = _sortedFoldersCache[index];
          final name = _getFolderName(path);
          final count = _foldersCache[path]?.length ?? 0;
          final folderSongs = _foldersCache[path] ?? [];
          
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.orange),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("$count songs"),
            trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onTap: () {
               Navigator.push(
                 context,
                 SmoothPageRoute(
                   child: FolderDetailScreen(
                     folderPath: path,
                     folderName: name,
                     songs: folderSongs,
                   ),
                 ),
               );
            },
          );
        },
        childCount: _sortedFoldersCache.length,
      ),
    );
  }
}
