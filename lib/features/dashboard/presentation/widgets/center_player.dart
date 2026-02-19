import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:music_world/features/songs/bloc/player_bloc.dart';
import 'package:music_world/core/ui/wave_visualizer.dart';
import 'package:music_world/core/ui/glass_box.dart';
import 'package:music_world/features/now_playing/presentation/now_playing_screen.dart';
import 'dart:math';

class CenterPlayer extends StatefulWidget {
  const CenterPlayer({super.key});

  @override
  State<CenterPlayer> createState() => _CenterPlayerState();
}

class _CenterPlayerState extends State<CenterPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) => previous.currentItem?.id != current.currentItem?.id || previous.isPlaying != current.isPlaying,
      listener: (context, state) {
        if (state.isPlaying) {
          _spinController.repeat();
        } else {
          _spinController.stop();
        }
      },
      builder: (context, state) {
        final currentItem = state.currentItem;
        if (currentItem == null) {
          return const SizedBox.shrink();
        }

        // Parse Song ID from extras (Unique ID support)
        final rawId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
        final songId = int.tryParse(rawId) ?? int.tryParse(rawId.split('_').first) ?? 0;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              context.read<PlayerBloc>().add(NextSong());
            } else if (details.primaryVelocity! > 0) {
              context.read<PlayerBloc>().add(PreviousSong());
            }
          },
          onTap: () {
            Navigator.of(context).push(NowPlayingScreen.route());
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 160,
            child: Stack(
              children: [
                // 1. Aura Glow Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.15),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                    duration: 3.seconds,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                ),

                // 2. Glassmorphic Surface
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: GlassBox(
                      opacity: 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Integrated Visualizer (Background)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Opacity(
                    opacity: 0.3,
                    child: WaveVisualizer(
                      isPlaying: state.isPlaying,
                      color: Theme.of(context).primaryColor,
                      width: double.infinity,
                      height: 40,
                    ),
                  ),
                ),

                // 4. Content Content Content content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Spinning Circular Artwork
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                          ),
                          RotationTransition(
                            turns: _spinController,
                            child: Hero(
                              tag: 'center_artwork_$songId',
                              child: Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 2),
                                ),
                                child: QueryArtworkWidget(
                                  id: songId,
                                  type: ArtworkType.AUDIO,
                                  artworkBorder: BorderRadius.circular(50),
                                  keepOldArtwork: true,
                                  nullArtworkWidget: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.music_note_rounded, color: Theme.of(context).primaryColor, size: 40),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Vinyl Center Hole
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Text & Controls
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
                            ),
                            Text(
                              currentItem.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            // Minimalist Premium Controls
                            Row(
                              children: [
                                _controlButton(Icons.skip_previous_rounded, () {
                                  context.read<PlayerBloc>().add(PreviousSong());
                                }),
                                const SizedBox(width: 16),
                                _playPauseButton(context, state.isPlaying),
                                const SizedBox(width: 16),
                                _controlButton(Icons.skip_next_rounded, () {
                                  context.read<PlayerBloc>().add(NextSong());
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Glowing Progress Bar at Bottom
                Positioned(
                  bottom: 0,
                  left: 28,
                  right: 28,
                  child: StreamBuilder<Duration>(
                    stream: context.read<PlayerBloc>().positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = currentItem.duration ?? Duration.zero;
                      final progress = total.inMilliseconds > 0 
                          ? position.inMilliseconds / total.inMilliseconds 
                          : 0.0;
                      
                      return Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white, 
          size: 24
        ),
      ),
    );
  }

  Widget _playPauseButton(BuildContext context, bool isPlaying) {
    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          context.read<PlayerBloc>().add(PausePlayer());
        } else {
          context.read<PlayerBloc>().add(ResumePlayer());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
}
