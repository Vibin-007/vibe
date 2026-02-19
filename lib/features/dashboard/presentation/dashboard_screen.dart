import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/ui/glass_box.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';
import 'dart:async';

import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_state.dart';
import '../../songs/bloc/player_bloc.dart';
import '../../playlist/bloc/playlist_bloc.dart';
import '../../../core/services/mood_service.dart';
import '../../../core/ui/song_list_tile.dart';
import '../../../core/ui/song_grid_tile.dart';
import '../../playlist/presentation/playlist_detail_screen.dart';
import 'package:music_world/features/dashboard/presentation/widgets/center_player.dart';


import 'widgets/center_player.dart';
import 'dashboard_layout_editor.dart';
import '../../../core/ui/smooth_page_transition.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userPrefs = RepositoryProvider.of<UserPreferencesService>(context);
    
    return StreamBuilder<void>(
      stream: userPrefs.dataStream,
      builder: (context, _) {
        final userName = userPrefs.getUserName() ?? 'Friend';
        final layout = userPrefs.getDashboardLayout();
        final hidden = userPrefs.getDashboardHiddenSections();
        
        return BlocBuilder<SongsBloc, SongsState>(
          builder: (context, songsState) {
            return BlocBuilder<PlayerBloc, PlayerState>(
              buildWhen: (previous, current) => previous.currentItem?.id != current.currentItem?.id || previous.isPlaying != current.isPlaying,
              builder: (context, playerState) {
                return BlocBuilder<PlaylistBloc, PlaylistState>(
                  builder: (context, playlistState) {
                    
                    List<Widget> buildSection(String id) {
                      if (hidden.contains(id)) return [];
                      switch (id) {
                        case 'center_player':
                          return [
                            const SliverToBoxAdapter(child: SizedBox(height: 24)),
                            const SliverToBoxAdapter(child: CenterPlayer())
                          ];
                        case 'playlists':
                          return _buildRecentPlaylists(context, userPrefs, playlistState, songsState);
                        case 'favorites':
                          return _buildFavorites(context, playerState);
                        case 'recent':
                          return _buildRecentSongs(context, userPrefs, songsState);
                        default:
                          return [];
                      }
                    }

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildHeader(context, userPrefs, userName, playerState),
                        
                        const SliverToBoxAdapter(
                          child: SizedBox(), // Placeholder for stripped hardcoded player
                        ),

                        // Dynamic Sections
                        ...layout.expand((id) => buildSection(id)),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    );
                  }
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserPreferencesService userPrefs, String userName, PlayerState playerState) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 135, 16, 24),
        child: Row(
          children: [
            if (userPrefs.getProfileImagePath() != null) ...[
                 Container(
                   padding: const EdgeInsets.all(2),
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                   ),
                   child: CircleAvatar(
                     backgroundImage: FileImage(File(userPrefs.getProfileImagePath()!)),
                     radius: 28,
                   ),
                 ),
                 const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                        ),
                  ),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 32,
                        ),
                  ),
                ],
              ),
            ),
             if (playerState.sleepTimerEndTime != null)
                 StreamBuilder<int>(
                   stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                   builder: (context, snapshot) {
                     final remaining = playerState.sleepTimerEndTime!.difference(DateTime.now());
                     if (remaining.isNegative) return const SizedBox();
                     final min = remaining.inMinutes;
                     final sec = remaining.inSeconds % 60;
                      return GestureDetector(
                        onTap: () {
                           showDialog(
                             context: context,
                             builder: (context) => AlertDialog(
                               title: const Text('Stop Sleep Timer?'),
                               content: const Text('Do you want to stop the active sleep timer?'),
                               actions: [
                                 TextButton(
                                   onPressed: () => Navigator.pop(context), 
                                   child: const Text('Cancel')
                                 ),
                                 TextButton(
                                   onPressed: () {
                                     context.read<PlayerBloc>().add(SetSleepTimer(null));
                                     Navigator.pop(context);
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Sleep timer stopped'))
                                     );
                                   }, 
                                   child: const Text('Stop', style: TextStyle(color: Colors.red))
                                 ),
                               ],
                             )
                           );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).primaryColor), 
                              const SizedBox(width: 6),
                              Text(
                                '$min:${sec.toString().padLeft(2, '0')}', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 14)
                              ),
                            ],
                          ),
                        ),
                     );
                   }
                 )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentPlaylists(BuildContext context, UserPreferencesService userPrefs, PlaylistState playlistState, SongsState songsState) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Playlists',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Builder(
            builder: (context) {
              final playlists = playlistState.playlists.keys
                  .where((name) => name != 'Favorites') // Exclude Favorites
                  .toList();
              final recentPlaylists = userPrefs.getRecentPlaylists();

              playlists.sort((a, b) {
                final indexA = recentPlaylists.indexOf(a);
                final indexB = recentPlaylists.indexOf(b);
                if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
                if (indexA != -1) return -1; 
                if (indexB != -1) return 1; 
                return a.compareTo(b);
              });

              if (playlists.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildCreatePlaylistSmall(context),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: playlists.length, 
                itemBuilder: (context, index) {
                  return _buildPlaylistCard(context, playlists[index]);
                },
              );
            },
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFavorites(BuildContext context, PlayerState playerState) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Your Favorites',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () {
               final favIds = playerState.favorites;
               Navigator.push(
                 context, 
                 SmoothPageRoute(
                   child: PlaylistDetailScreen(
                     playlistName: 'Favorites', 
                     songIds: favIds
                   )
                 )
               );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.redAccent.withOpacity(0.2),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 32),
                   ),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Favorite Songs', 
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                       ),
                     ],
                   ),
                   const Spacer(),
                   const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRecentSongs(BuildContext context, UserPreferencesService userPrefs, SongsState songsState) {
    final viewMode = userPrefs.getRecentlyPlayedViewMode();
    final isList = viewMode == 'list';

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Played',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(
                    icon: Icon(isList ? Icons.grid_view_rounded : Icons.view_list_rounded, size: 20, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      userPrefs.setRecentlyPlayedViewMode(isList ? 'grid' : 'list');
                    },
                  ),
                  TextButton(
                    onPressed: () {
                       final recentIds = userPrefs.getRecentlyPlayed();
                       Navigator.push(
                         context, 
                         SmoothPageRoute(
                           child: PlaylistDetailScreen(
                             playlistName: 'Recently Played', 
                             songIds: recentIds
                           )
                         )
                       );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (songsState is SongsLoaded)
        Builder(
          builder: (context) {
            final recentIds = userPrefs.getRecentlyPlayed();
            final limit = isList ? 5 : 6;
            final recentSongs = recentIds.map((id) {
               try {
                 return songsState.songs.firstWhere((s) => s.id.toString() == id);
               } catch (e) {
                 return null;
               }
            }).whereType<SongModel>().take(limit).toList();

            if (recentSongs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recently played songs yet.'),
                ),
              );
            }

             if (isList) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = recentSongs[index];
                      final currentItem = context.read<PlayerBloc>().state.currentItem;
                      final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                      final isPlaying = song.id.toString() == playingId;
                      return SongListTile(
                         song: song,
                         isPlaying: isPlaying,
                         onTap: () {
                            context.read<PlayerBloc>().add(PlaySong(recentSongs, index));
                         },
                         onMoreTap: () => _showSongOptions(context, song),
                      );
                    },
                    childCount: recentSongs.length,
                  ),
                );
             }
 
             return SliverPadding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               sliver: SliverGrid(
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 3,
                   childAspectRatio: 0.8,
                   crossAxisSpacing: 12,
                   mainAxisSpacing: 12,
                 ),
                 delegate: SliverChildBuilderDelegate(
                   (context, index) {
                     final song = recentSongs[index];
                      final currentItem = context.read<PlayerBloc>().state.currentItem;
                      final playingId = currentItem?.extras?['songId']?.toString() ?? currentItem?.id;
                      final isPlaying = song.id.toString() == playingId;
                      return SongGridTile(
                        song: song,
                        isPlaying: isPlaying,
                       onTap: () {
                         context.read<PlayerBloc>().add(PlaySong(recentSongs, index));
                       },
                       onLongPress: () => _showSongOptions(context, song),
                       onMoreTap: () => _showSongOptions(context, song),
                     );
                   },
                   childCount: recentSongs.length,
                 ),
               ),
             );
          }
        ),
    ];
  }

  Widget _buildFavCard(BuildContext context, dynamic song) {
    return GestureDetector(
      onTap: () {
        context.read<PlayerBloc>().add(PlaySong([song], 0));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: GlassBox(
          borderRadius: BorderRadius.circular(8),
          opacity: 0.05,
          child: Row(
            children: [
              Hero(
                tag: 'hero_song_${song.id}',
                child: _DashboardArtwork(songId: song.id),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: const Center(
        child: Text('Add some favs!', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, String name) {
    return BlocBuilder<PlaylistBloc, PlaylistState>(
      builder: (context, playlistState) {
        return BlocBuilder<SongsBloc, SongsState>(
          builder: (context, songsState) {
            final songIds = playlistState.playlists[name] ?? [];
            final allSongs = (songsState is SongsLoaded) ? songsState.songs : <SongModel>[];
            final songs = allSongs.where((s) => songIds.contains(s.id.toString())).toList();

            return GestureDetector(
              onTap: () {
                if (songs.isNotEmpty) {
                  Navigator.push(
                    context, 
                    SmoothPageRoute(
                      child: PlaylistDetailScreen(
                        playlistName: name, 
                        songIds: songIds
                      )
                    )
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist is empty')));
                }
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${songs.length} songs',
                      style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreatePlaylistSmall(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCreatePlaylistDialog(context),
      child: Container(
        width: 100,
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Text('New', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PlaylistBloc>().add(CreatePlaylist(controller.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playlist "${controller.text}" created')),
                );
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
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

class _DashboardArtwork extends StatelessWidget {
  final int songId;
  const _DashboardArtwork({required this.songId});

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: songId,
      type: ArtworkType.AUDIO,
      artworkBorder: const BorderRadius.horizontal(left: Radius.circular(8)),
      artworkHeight: 60,
      artworkWidth: 60,
      keepOldArtwork: true,
      nullArtworkWidget: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
        ),
        child: Icon(Icons.music_note_rounded, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
