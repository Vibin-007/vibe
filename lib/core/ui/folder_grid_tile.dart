import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_box.dart';

class FolderGridTile extends StatelessWidget {
  final String name;
  final int songCount;
  final List<SongModel> songs;
  final VoidCallback onTap;

  const FolderGridTile({
    super.key,
    required this.name,
    required this.songCount,
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get up to 3 songs for the stacked artwork effect
    final displaySongs = songs.take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Folder Tab (The little bump on top)
            Positioned(
              top: -6,
              left: 14,
              child: Container(
                width: 45,
                height: 15,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 0.5,
                  ),
                ),
              ),
            ),
            
            // Main Folder Body
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Stacked Artworks with "Physical" Depth
                    if (displaySongs.isNotEmpty)
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: List.generate(displaySongs.length, (index) {
                            final song = displaySongs[displaySongs.length - 1 - index];
                            // Reverse order so the first song is on top
                            final reverseIndex = displaySongs.length - 1 - index;
                            
                            return Transform.translate(
                              offset: Offset(reverseIndex * 8.0 - 4, reverseIndex * -4.0),
                              child: Transform.rotate(
                                angle: (reverseIndex - 1) * 0.08,
                                child: Container(
                                  width: 85,
                                  height: 85,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: QueryArtworkWidget(
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      size: 300,
                                      keepOldArtwork: true,
                                      nullArtworkWidget: Container(
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 30),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    
                    // Folder Icon Overlay (Subtle)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        Icons.folder_rounded,
                        size: 20,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),

                    // Bottom Glass Info Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GlassBox(
                        opacity: 0.4,
                        sigmaX: 8,
                        sigmaY: 8,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.2,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$songCount Songs",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
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
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }
}
