import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/songs_state.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/ui/glass_box.dart'; // Assuming we have generic GlassBox or I can inline it

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = RepositoryProvider.of<UserPreferencesService>(context);
    return StreamBuilder<void>(
      stream: prefs.dataStream,
      builder: (context, _) {
          final playCounts = prefs.getPlayCounts();
          final artistCounts = prefs.getArtistCounts();

          return Scaffold(
            backgroundColor: Colors.black, // Force dark background for "Vibe"
            body: BlocBuilder<SongsBloc, SongsState>(
              builder: (context, state) {
                if (state is! SongsLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allSongs = state.songs;
                
                // Sort Play Counts
                final sortedSongs = playCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                
                SongModel? topSong;
                if (sortedSongs.isNotEmpty) {
                    final id = sortedSongs.first.key;
                    topSong = allSongs.firstWhere((s) => s.id.toString() == id, 
                      orElse: () => SongModel({'_id': int.tryParse(id) ?? 0, 'title': 'Unknown', 'artist': 'Unknown'}));
                }

                final top5Songs = sortedSongs.take(5).map((entry) {
                   return allSongs.firstWhere((s) => s.id.toString() == entry.key, 
                      orElse: () => SongModel({'_id': int.tryParse(entry.key) ?? 0, 'title': 'Unknown', 'artist': 'Unknown'}));
                }).toList();

                // Sort Artists
                final sortedArtists = artistCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topArtists = sortedArtists.take(10).toList(); // Top 10 artists
                
                // History
                final recentIds = prefs.getRecentlyPlayed();
                final historySongs = recentIds.map((id) {
                    return allSongs.firstWhere((s) => s.id.toString() == id, 
                      orElse: () => SongModel({'_id': int.tryParse(id) ?? 0, 'title': 'Unknown', 'artist': 'Unknown'}));
                }).toList();

                final totalPlays = playCounts.values.fold(0, (a, b) => a + b);

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 100,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.black,
                      iconTheme: const IconThemeData(color: Colors.white),
                      actions: [
                        if (playCounts.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
                            onPressed: () => _showClearStatsDialog(context, prefs),
                          ),
                      ],
                      flexibleSpace: const FlexibleSpaceBar(
                        title: Text(
                          'Your DNA', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                        ),
                        centerTitle: false,
                        titlePadding: EdgeInsets.only(left: 60, bottom: 16),
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // 1. HERO CARD (Top Song)
                            if (topSong != null)
                              _buildHeroCard(context, topSong, playCounts[topSong.id.toString()] ?? 0)
                            else 
                              _buildEmptyState(context),
                              
                            const SizedBox(height: 24),
                            
                            // 2. STATS ROW
                            Row(
                              children: [
                                Expanded(child: _buildStatChip(context, "Total Plays", "$totalPlays", Colors.blueAccent)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatChip(context, "Unique Songs", "${playCounts.length}", Colors.purpleAccent)),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                          ]
                        )
                      )
                    ),
                    
                    // 3. TOP ARTISTS (Horizontal)
                    if (topArtists.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader("Top Artists")),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: topArtists.length,
                            itemBuilder: (context, index) {
                              final artistName = topArtists[index].key;
                              final count = topArtists[index].value;
                               // Find a song by this artist to get artwork? 
                               // QueryArtworkWidget supports ARTIST type but needs ID. 
                               // We only have names here. 
                               // Actually we can try to find a song by this artist in 'allSongs' and use its ID with ArtworkType.AUDIO and hope?
                               // Or just use first letter.
                              return _buildArtistCircle(context, artistName, count);
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    // 4. ON REPEAT LIST
                    if (top5Songs.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader("On Repeat")),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = top5Songs[index];
                            final plays = playCounts[song.id.toString()];
                            return _buildSongTile(context, index + 1, song, plays ?? 0);
                          },
                          childCount: top5Songs.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                    
                    // 5. HISTORY
                    if (historySongs.isNotEmpty) ...[
                        SliverToBoxAdapter(child: _buildSectionHeader("Flashback")),
                         SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = historySongs[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.history_rounded, size: 20, color: Colors.white54),
                              ),
                              title: Text(song.title, maxLines: 1, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(song.artist ?? 'Unknown', maxLines: 1, style: const TextStyle(color: Colors.white54)),
                            );
                          },
                          childCount: historySongs.length,
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  ],
                );
              },
            ),
          );
      }
    );
  }

  Widget _buildHeroCard(BuildContext context, SongModel song, int plays) {
      return Container(
        height: 200, // Reduced height for Bento feel
        width: double.infinity,
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(24),
           gradient: LinearGradient(
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
             colors: [
                Colors.purpleAccent.withOpacity(0.2),
                Colors.deepPurple.withOpacity(0.1),
             ]
           ),
           border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
             // Background Art (if we could blur it, but QueryArtworkWidget is rigid)
             Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Opacity(
                    opacity: 0.1,
                    child: QueryArtworkWidget(
                      id: song.id, type: ArtworkType.AUDIO, size: 1000, 
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: const SizedBox()
                    ),
                  ),
                )
             ),
             
             Padding(
               padding: const EdgeInsets.all(20),
               child: Row(
                 children: [
                    // Big Art
                   Container(
                     width: 140, height: 140,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
                     ),
                     child: QueryArtworkWidget(
                        id: song.id, type: ArtworkType.AUDIO, 
                        artworkBorder: BorderRadius.circular(20),
                        nullArtworkWidget: Container(
                          color: Colors.grey[900], 
                          child: const Icon(Icons.music_note, color: Colors.white24, size: 50)
                        ),
                     ),
                   ),
                   const SizedBox(width: 20),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.amber.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(20),
                               border: Border.all(color: Colors.amber.withOpacity(0.5))
                             ),
                             child: const Text("MOST PLAYED", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$plays", 
                            style: const TextStyle(fontSize: 42, height: 1, fontWeight: FontWeight.w900, color: Colors.white)
                          ),
                          const Text("Plays", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(song.artist ?? "Unknown", maxLines: 1, overflow: TextOverflow.ellipsis,
                             style: const TextStyle(color: Colors.white54, fontSize: 14)),
                       ],
                     ),
                   )
                 ],
               ),
             )
          ],
        ),
      );
  }

  Widget _buildStatChip(BuildContext context, String title, String value, Color color) {
     return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.05),
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Icon(Icons.insights_rounded, color: color, size: 24),
             const SizedBox(height: 12),
             Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
             Text(title, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ],
        ),
     );
  }

  Widget _buildArtistCircle(BuildContext context, String artist, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
           Container(
             width: 60, height: 60,
             decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
             ),
             child: const Center(child: Icon(Icons.person, color: Colors.white, size: 30)),
             // Ideally we'd map artist name to an ID to fetch art, but difficult without data
           ),
           const SizedBox(height: 8),
           SizedBox(
             width: 70,
             child: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))
           ),
            Text("$count plays", style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, int rank, SongModel song, int plays) {
     return Container(
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
       decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.02),
         borderRadius: BorderRadius.circular(16),
       ),
       child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
          leading: Container(
             width: 40, height: 40,
             alignment: Alignment.center,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: Colors.white.withOpacity(0.1),
             ),
             child: Text("#$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(song.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(song.artist ?? "Unknown", maxLines: 1, style: const TextStyle(color: Colors.white54)),
          trailing: Text("$plays", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
       ),
     );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
       height: 150,
       width: double.infinity,
       decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(24),
         border: Border.all(color: Colors.white10),
       ),
       child: const Center(
         child: Text("Play some music to see stats!", style: TextStyle(color: Colors.white54)),
       ),
    );
  }

  void _showClearStatsDialog(BuildContext context, UserPreferencesService prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Clear DNA?", style: TextStyle(color: Colors.white)),
        content: const Text("This will reset your Top Songs and Artist data.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await prefs.clearPlayCounts();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stats cleared")));
            }, 
            child: const Text("Clear", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}
