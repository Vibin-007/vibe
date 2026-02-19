import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../features/songs/bloc/player_bloc.dart';
import 'song_list_tile.dart';

class SwipeQueueTile extends StatelessWidget {
  final SongModel song;
  final Widget? child; // Optional, defaults to SongListTile if null
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  final bool isPlaying;

  const SwipeQueueTile({
    super.key,
    required this.song,
    this.child,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('queue_swipe_${song.id}_${DateTime.now().millisecondsSinceEpoch}'), // Unique key to avoid collisions in different lists
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.75},
      confirmDismiss: (direction) async {
        context.read<PlayerBloc>().add(AddToQueue(song));
        ScaffoldMessenger.of(context).clearSnackBars(); // Clear previous quick snacks
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: const Text('Added to Queue'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
        return false; // Don't remove the item from the list
      },
      background: Container(
        color: Theme.of(context).primaryColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4), // Match list tile margin if any
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Queue', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: child ?? SongListTile(
        song: song,
        onTap: onTap,
        onMoreTap: onMoreTap,
        isPlaying: isPlaying,
      ),
    );
  }
}
