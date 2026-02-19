import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../features/songs/bloc/player_bloc.dart';
import '../../features/songs/bloc/songs_bloc.dart';
import '../theme/app_colors.dart';
import '../../features/playlist/bloc/playlist_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final bool showArtwork;
  final Key? dismissKey;

  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.showArtwork = true,
    this.dismissKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced from 6
      decoration: BoxDecoration(
         color: isPlaying 
            ? Theme.of(context).primaryColor.withOpacity(0.15) 
            : Theme.of(context).cardColor.withOpacity(0.6),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
            color: isPlaying 
              ? Theme.of(context).primaryColor.withOpacity(0.8) 
              : Colors.white.withOpacity(0.05),
            width: isPlaying ? 2 : 1,
         ),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 10,
             offset: const Offset(0, 4),
           )
         ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Reduced from 8
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: 'song_icon_${song.id}',
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  image: showArtwork ? null : null, // Todo: Real artwork image logic if available in model
                ),
                child: showArtwork 
                    ? QueryArtworkWidget(
                      id: song.id, 
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(50),
                      keepOldArtwork: true,
                      nullArtworkWidget: Icon(Icons.music_note_rounded, color: Theme.of(context).primaryColor),
                    )
                  : Icon(Icons.music_note_rounded, color: Theme.of(context).primaryColor),
              ),
            ),
             if (isPlaying)
               Container(
                 width: 50,
                 height: 50,
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.3),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.bar_chart_rounded, color: Theme.of(context).primaryColor),
               ),
          ],
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isPlaying ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Text(
          song.artist ?? "Unknown Artist",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // if (isPlaying) 
            //   Lottie.asset('assets/animations/music_wave.json', height: 24), // Future enhancement
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              onPressed: onMoreTap,
            ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
