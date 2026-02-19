import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../songs/bloc/player_bloc.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_state.dart';
import '../../mini_player/presentation/mini_player.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/ui/swipe_queue_tile.dart';
import '../../../core/ui/glass_box.dart';
import '../../../core/ui/song_grid_tile.dart';
import '../../playlist/bloc/playlist_bloc.dart';

import 'dart:async';

class FolderDetailScreen extends StatefulWidget {
  final String folderPath;
  final String folderName;
  final List<SongModel> songs;

  const FolderDetailScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
    required this.songs,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late ScrollController _scrollController;
  double _scrollOpacity = 0.0;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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

  void _onScroll() {
    final offset = _scrollController.offset;
    final newOpacity = (offset / 150).clamp(0.0, 1.0);
    if (newOpacity != _scrollOpacity) {
      setState(() {
        _scrollOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _searchQuery.isEmpty
        ? widget.songs
        : widget.songs.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final firstSongId = widget.songs.isNotEmpty ? widget.songs.first.id : null;

    return StreamBuilder<void>(
      stream: context.read<UserPreferencesService>().dataStream,
      builder: (context, _) {
        final userPrefs = context.read<UserPreferencesService>();
        final isGrid = userPrefs.getSongsViewMode() == 'grid';

        return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: const SizedBox.shrink(), // Moved to overlay for better visibility/glass effect
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Representative Artwork (First song in folder)
                      if (firstSongId != null)
                        QueryArtworkWidget(
                          id: firstSongId,
                          type: ArtworkType.AUDIO,
                          format: ArtworkType.AUDIO == ArtworkType.AUDIO ? ArtworkFormat.JPEG : ArtworkFormat.PNG,
                          size: 800, // Higher resolution
                          artworkWidth: double.infinity,
                          artworkHeight: double.infinity,
                          artworkBorder: BorderRadius.zero,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            color: Theme.of(context).cardColor,
                            child: Icon(Icons.folder_open_rounded, size: 100, color: Colors.orange.withOpacity(0.5)),
                          ),
                        )
                      else
                        Container(
                          color: Theme.of(context).cardColor,
                          child: Icon(Icons.folder_open_rounded, size: 100, color: Colors.orange.withOpacity(0.5)),
                        ),
                      
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black45,
                              Colors.transparent,
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      
                      // Text Info
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              widget.folderName,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.songs.length} Songs • ${widget.folderPath}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                title: null, // Moved to overlay
                centerTitle: true,
              ),

              // Search Bar in list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search in ${widget.folderName}",
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),

              if (filteredSongs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No songs found in this folder', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else if (isGrid)
                BlocBuilder<PlayerBloc, PlayerState>(
                  buildWhen: (previous, current) => previous.currentItem?.id != current.currentItem?.id || previous.isPlaying != current.isPlaying,
                  builder: (context, playerState) {
                    final currentId = playerState.currentItem?.id;
                    return SliverPadding(
                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                       sliver: SliverGrid(
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                         ),
                         delegate: SliverChildBuilderDelegate(
                           (context, index) {
                             final song = filteredSongs[index];
                             final currentItem = playerState.currentItem;
                             final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                             final isPlaying = song.id.toString() == playingId;
                              return SongGridTile(
                                song: song,
                                isPlaying: isPlaying,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<PlayerBloc>().add(PlaySong(filteredSongs, index));
                                },
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  _showSongOptions(context, song);
                                },
                                onMoreTap: () => _showSongOptions(context, song),
                              );
                           },
                           childCount: filteredSongs.length,
                         ),
                       ),
                    );
                  }
                )
              else
                BlocBuilder<PlayerBloc, PlayerState>(
                  buildWhen: (previous, current) => previous.currentItem?.id != current.currentItem?.id || previous.isPlaying != current.isPlaying,
                  builder: (context, playerState) {
                    final currentId = playerState.currentItem?.id;
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                              final song = filteredSongs[index];
                              final currentItem = playerState.currentItem;
                              final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                              final isPlaying = song.id.toString() == playingId;
                              return SwipeQueueTile(
                                song: song,
                                isPlaying: isPlaying,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.read<PlayerBloc>().add(PlaySong(filteredSongs, index));
                              },
                              onMoreTap: () => _showSongOptions(context, song),
                            );
                          },
                          childCount: filteredSongs.length,
                        ),
                      ),
                    );
                  }
                ),
            ],
          ),

          // Refined Glass Header (Always on top, content stays sharp)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
                child: Stack(
                  children: [
                    // Glass Background (Fades in on scroll)
                    Opacity(
                      opacity: _scrollOpacity,
                      child: const GlassBox(
                        borderRadius: BorderRadius.zero,
                        sigmaX: 10,
                        sigmaY: 10,
                        child: SizedBox.expand(),
                      ),
                    ),
                    
                    // Content (Always Sharp)
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            // Back Button with adaptive background
                            Opacity(
                              opacity: 1.0, // Always visible
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.3 * (1 - _scrollOpacity)),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _scrollOpacity > 0.8 ? 1.0 : 0.0,
                                child: Text(
                                  widget.folderName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer for balance
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),



          // Restored MiniPlayer
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),

        ],
      ),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, SongModel song) {
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
                        _showPlaylistDialog(context, song);
                      },
                    ),
                  if (canRemove)
                    ListTile(
                      leading: const Icon(Icons.playlist_remove_rounded, color: Colors.redAccent),
                      title: const Text('Remove from Playlist', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(context);
                        _showRemovePlaylistDialog(context, song, playlistsContainingSong);
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

  void _showPlaylistDialog(BuildContext context, SongModel song) {
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

  void _showRemovePlaylistDialog(BuildContext context, SongModel song, List<String> playlists) {
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
}
