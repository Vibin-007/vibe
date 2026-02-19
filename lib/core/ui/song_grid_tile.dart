import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongGridTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMoreTap;
  final bool isPlaying;

  const SongGridTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onLongPress,
    this.onMoreTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isPlaying ? Border.all(color: Theme.of(context).primaryColor, width: 2) : Border.all(color: Colors.transparent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: isPlaying ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                    blurRadius: isPlaying ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14), // Adjusted for border
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  format: ArtworkFormat.JPEG,
                  size: 500,
                  artworkWidth: double.infinity,
                  artworkHeight: double.infinity,
                  artworkBorder: BorderRadius.zero,
                  keepOldArtwork: true,
                  nullArtworkWidget: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                    ),
                    child: Center(
                      child: Icon(Icons.music_note_rounded, size: 32, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                    color: isPlaying ? Theme.of(context).primaryColor : null,
                  ),
                ),
                Text(
                  song.artist ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
