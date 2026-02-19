import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/playlist_bloc.dart';
import '../../songs/bloc/player_bloc.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_state.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../playlist/presentation/playlist_detail_screen.dart';

import '../../../core/services/user_preferences_service.dart';
import '../../../core/ui/smooth_page_transition.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userPrefs = context.read<UserPreferencesService>();

    return Scaffold(
      body: StreamBuilder<void>(
      stream: userPrefs.dataStream,
      builder: (context, _) {
        final viewMode = userPrefs.getPlaylistsViewMode();
        final isGrid = viewMode == 'grid'; 
        
      return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, songsState) {
        final allSongs = (songsState is SongsLoaded) ? songsState.songs : <SongModel>[];

        return BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 160, 16, 0), 
                    child: Column(
                      children: [
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreatePlaylistDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 28),
                            label: const Text('Create Playlist'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text("Your Playlists", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                             Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
                                  onPressed: () {
                                    userPrefs.setPlaylistsViewMode(isGrid ? 'list' : 'grid');
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (state.playlists.isEmpty)
                   SliverFillRemaining(
                     hasScrollBody: false,
                     child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(
                               Icons.library_music_rounded, 
                               size: 60, 
                               color: Theme.of(context).primaryColor.withOpacity(0.3)
                             ),
                             const SizedBox(height: 16),
                             Text('No playlists yet', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                     ),
                   )
                else
                  isGrid ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0, 
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Inject Favorites at index 0
                          if (index == 0) {
                            return _buildFavoritesCard(context, true);
                          }
                          final playlistIndex = index - 1;
                          
                          final name = state.playlists.keys.toList()[playlistIndex];
                          final songIds = state.playlists[name]!;
                          
                          return GestureDetector(
                            onTap: () {
                               Navigator.push(
                                 context, 
                                 SmoothPageRoute(
                                   child: PlaylistDetailScreen(
                                     playlistName: name, 
                                     songIds: songIds
                                   )
                                 )
                               );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(context).primaryColor.withOpacity(0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.queue_music_rounded, color: Theme.of(context).primaryColor, size: 32),
                                        ),
                                        const Spacer(),
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${songIds.length} songs',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.more_vert_rounded),
                                      onPressed: () => _showPlaylistOptions(context, name),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().scale(delay: (index * 50).ms, duration: 300.ms, curve: Curves.easeOutBack),
                          );
                        },
                        childCount: state.playlists.length + 1, // +1 for Favorites
                      ),
                    ),
                  ) : SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: _buildFavoritesCard(context, false),
                            );
                          }
                          final playlistIndex = index - 1;

                          final name = state.playlists.keys.toList()[playlistIndex];
                          final songIds = state.playlists[name]!;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              tileColor: Theme.of(context).cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.queue_music_rounded, color: Theme.of(context).primaryColor),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${songIds.length} songs'),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                onPressed: () => _showPlaylistOptions(context, name),
                              ),
                              onTap: () {
                                 Navigator.push(
                                 context, 
                                 SmoothPageRoute(
                                   child: PlaylistDetailScreen(
                                     playlistName: name, 
                                     songIds: songIds
                                   )
                                 )
                               );
                              },
                            ),
                          );
                        },
                        childCount: state.playlists.length + 1, // +1 for Favorites
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        );
      },
    );
      }),
    );
  }

  void _showPlaylistOptions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Playlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                 showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Playlist?'),
                    content: Text('Are you sure you want to delete "$name"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                      TextButton(
                        onPressed: () {
                           context.read<PlaylistBloc>().add(DeletePlaylist(name));
                           Navigator.pop(context);
                        }, 
                        child: const Text('DELETE', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
                );
              },
            ),
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
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesCard(BuildContext context, bool isGrid) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) => previous.favorites != current.favorites,
      builder: (context, state) {
        final favCount = state.favorites.length;
        
        if (isGrid) {
          return GestureDetector(
            onTap: () {
               Navigator.push(
                 context, 
                 SmoothPageRoute(
                   child: PlaylistDetailScreen(
                     playlistName: 'Favorites', 
                     songIds: state.favorites
                   )
                 )
               );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                children: [
                   Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.redAccent.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
                        ),
                        const Spacer(),
                        Text(
                          'Favorites',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
          ),
          title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
             Navigator.push(
             context, 
             SmoothPageRoute(
               child: PlaylistDetailScreen(
                 playlistName: 'Favorites', 
                 songIds: state.favorites
               )
             )
           );
          },
        );
      },
    );
  }
}
