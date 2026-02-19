import 'package:flutter/material.dart';
import 'dart:convert'; // [NEW]
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/theme/app_colors.dart';
import '../../songs/bloc/player_bloc.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_state.dart';
import '../../playlist/bloc/playlist_bloc.dart';
import 'package:flutter/services.dart';
import '../../mini_player/presentation/mini_player.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/ui/song_list_tile.dart';
import '../../../core/ui/swipe_queue_tile.dart';
import '../../../core/ui/glass_box.dart';
import '../../../core/ui/song_grid_tile.dart';
import 'dart:async';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  final List<String> songIds;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.songIds,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late ScrollController _scrollController;
  double _scrollOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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
    final userPrefs = RepositoryProvider.of<UserPreferencesService>(context);

    return Scaffold(
      body: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          if (state is SongsLoaded) {
            return StreamBuilder<void>(
              stream: userPrefs.dataStream,
              builder: (context, snapshot) {
                final isSmartPlaylist = widget.playlistName == 'Favorites' || widget.playlistName == 'Recently Played';
                final isGrid = !isSmartPlaylist && userPrefs.getSongsViewMode() == 'grid';

                // Dynamic Fetching for Realtime Updates
                List<String> currentIds = widget.songIds; 
                
                if (widget.playlistName == 'Favorites') {
                  currentIds = userPrefs.getFavorites();
                } else if (widget.playlistName == 'Recently Played') {
                  currentIds = userPrefs.getRecentlyPlayed();
                } else if (widget.playlistName != 'Most Played') {
                   // Custom Playlist: Fetch latest state from prefs
                   final raw = userPrefs.getPlaylistsRaw();
                   if (raw != null) {
                      try {
                        final decoded = jsonDecode(raw) as Map<String, dynamic>;
                        if (decoded.containsKey(widget.playlistName)) {
                           currentIds = List<String>.from(decoded[widget.playlistName]);
                        } else {
                           currentIds = []; // Playlist removed?
                        }
                      } catch (e) {
                         // Fallback to widget.songIds if parsing fails
                      }
                   }
                }

                final playlistSongs = currentIds
                    .map((id) => state.songs.firstWhere(
                          (s) => s.id.toString() == id || id.startsWith('${s.id}_'),
                          orElse: () => SongModel({'_id': -1, '_data': ''}),
                        ))
                    .where((s) => s.id != -1)
                    .toSet().toList(); // content toSet to remove duplicates if any ID mixup occurs

                final firstSongId = playlistSongs.isNotEmpty ? playlistSongs.first.id : null;

                return Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          leading: const SizedBox.shrink(),
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Representative Artwork
                                if (firstSongId != null)
                                  QueryArtworkWidget(
                                    id: firstSongId,
                                    type: ArtworkType.AUDIO,
                                    format: ArtworkFormat.JPEG,
                                    size: 800,
                                    artworkWidth: double.infinity,
                                    artworkHeight: double.infinity,
                                    artworkBorder: BorderRadius.zero,
                                    keepOldArtwork: true,
                                    nullArtworkWidget: Container(
                                      color: Theme.of(context).cardColor,
                                      child: Icon(Icons.playlist_play_rounded, size: 100, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                                    ),
                                  )
                                else
                                  Container(
                                    color: Theme.of(context).cardColor,
                                    child: Icon(Icons.playlist_play_rounded, size: 100, color: Theme.of(context).primaryColor.withOpacity(0.5)),
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
                                
                                // Title & Description
                                Positioned(
                                  bottom: 24,
                                  left: 20,
                                  right: 20,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.playlistName,
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${playlistSongs.length} Songs',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Grid/List Toggle (Hidden for Favorites/Recently Played)
                                      if (!isSmartPlaylist)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: IconButton(
                                            icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white),
                                            onPressed: () {
                                              userPrefs.setSongsViewMode(isGrid ? 'list' : 'grid');
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          centerTitle: true,
                        ),

                        if (playlistSongs.isEmpty)
                          const SliverFillRemaining(
                            child: Center(
                              child: Text('Empty Playlist', style: TextStyle(color: Colors.grey)),
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
                                      final song = playlistSongs[index];
                                      final currentItem = playerState.currentItem;
                                      final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                                      final isPlaying = song.id.toString() == playingId;
                                      return SongGridTile(
                                        song: song,
                                        isPlaying: isPlaying,
                                        onTap: () {
                                           context.read<UserPreferencesService>().addRecentPlaylist(widget.playlistName);
                                           context.read<PlayerBloc>().add(PlaySong(playlistSongs, index));
                                        },
                                        onLongPress: () {
                                          HapticFeedback.mediumImpact();
                                          _showSongOptions(context, song);
                                        },
                                        onMoreTap: () => _showSongOptions(context, song),
                                      );
                                    },
                                    childCount: playlistSongs.length,
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
                                      final song = playlistSongs[index];
                                      final currentItem = playerState.currentItem;
                                      final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                                      final isPlaying = song.id.toString() == playingId;
                                      return SwipeQueueTile(
                                        song: song,
                                        isPlaying: isPlaying,
                                        onTap: () {
                                          context.read<UserPreferencesService>().addRecentPlaylist(widget.playlistName);
                                          context.read<PlayerBloc>().add(PlaySong(playlistSongs, index));
                                        },
                                        onMoreTap: () => _showSongOptions(context, song),
                                      );
                                    },
                                    childCount: playlistSongs.length,
                                  ),
                                ),
                              );
                            }
                          ),
                      ],
                    ),

                    // Refined Glass Header
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + kToolbarHeight,
                          child: Stack(
                            children: [
                              Opacity(
                                opacity: _scrollOpacity,
                                child: const GlassBox(
                                  borderRadius: BorderRadius.zero,
                                  sigmaX: 10,
                                  sigmaY: 10,
                                  child: SizedBox.expand(),
                                ),
                              ),
                              SafeArea(
                                bottom: false,
                                child: SizedBox(
                                  height: kToolbarHeight,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.black.withOpacity(0.3 * (1 - _scrollOpacity)),
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 200),
                                          opacity: _scrollOpacity > 0.8 ? 1.0 : 0.0,
                                          child: Text(
                                            widget.playlistName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
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
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
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
          final canRemove = playlistsContainingSong.isEmpty == false; // logic fix if needed, but keeping existing

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
                      _showFeedback(context, 'Playing Next: ${song.title}');
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
                  ListTile(
                    leading: Icon(Icons.queue_music_rounded, color: Theme.of(context).iconTheme.color),
                    title: const Text('Add to Queue'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PlayerBloc>().add(AddToQueue(song));
                      _showFeedback(context, 'Added to Queue: ${song.title}');
                    },
                  ),
                  if (widget.playlistName != 'Recently Played' && widget.playlistName != 'Most Played')
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      title: Text(widget.playlistName == 'Favorites' ? 'Remove from Favorites' : 'Remove from Playlist', style: const TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.playlistName == 'Favorites') {
                          context.read<PlayerBloc>().add(ToggleFavorite(song.id.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from Favorites')));
                        } else {
                          context.read<PlaylistBloc>().add(RemoveFromPlaylist(widget.playlistName, song.id));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from Playlist')));
                        }
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
}
