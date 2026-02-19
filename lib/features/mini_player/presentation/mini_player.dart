import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../now_playing/presentation/now_playing_screen.dart';
import 'widgets/mini_player_visualizer.dart';
import '../../../core/ui/glass_box.dart';
import '../../songs/bloc/player_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../../../core/services/user_preferences_service.dart';
import 'analog_volume_overlay.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
    );
     _resetAnimation = _resetController.drive(CurveTween(curve: Curves.elasticOut));
     _resetController.addListener(() {
        setState(() {
           _dragOffset = _resetAnimation.value;
        });
     });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _runResetAnimation(double startValue) {
    _resetAnimation = _resetController.drive(
      Tween<double>(begin: startValue, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)),
    );
    _resetController.reset();
    _resetController.forward();
  }

  OverlayEntry? _volumeOverlayEntry;

  void _showVolumeOverlay() {
    if (_volumeOverlayEntry != null) return;
    
    final prefs = RepositoryProvider.of<UserPreferencesService>(context);
    if (!prefs.getAnalogVolumeTilt()) return;

    _volumeOverlayEntry = OverlayEntry(
      builder: (context) => AnalogVolumeOverlay(
        onClose: _hideVolumeOverlay,
      ),
    );
    Overlay.of(context).insert(_volumeOverlayEntry!);
  }

  void _hideVolumeOverlay() {
    _volumeOverlayEntry?.remove();
    _volumeOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final currentItem = state.currentItem;
        if (currentItem == null) return const SizedBox.shrink();

        final rawId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
        final songId = int.tryParse(rawId) ?? int.tryParse(rawId.split('_').first) ?? 0;

        return GestureDetector(
          onLongPressStart: (_) => _showVolumeOverlay(),
          onLongPressEnd: (_) => _hideVolumeOverlay(),
          onVerticalDragUpdate: (details) {
            setState(() {
              if (details.delta.dy < 0) { // Dragging Up
                _dragOffset += details.delta.dy * 0.7;
              } else { // Dragging Down
                _dragOffset += details.delta.dy * 0.3;
              }
              if (_dragOffset < -150) _dragOffset = -150;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset < -80 || details.primaryVelocity! < -500) {
              _dragOffset = 0; 
              Navigator.of(context).push(NowPlayingScreen.route());
            } else {
              _runResetAnimation(_dragOffset);
            }
          },
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
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: GlassBox(
                    borderRadius: BorderRadius.circular(0),
                    sigmaX: 15,
                    sigmaY: 15,
                    height: 70,
                    opacity: 0.6,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                               Expanded(
                                 child: AnimatedSwitcher(
                                   duration: const Duration(milliseconds: 300),
                                   transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(opacity: animation, child: SlideTransition(
                                         position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(animation),
                                         child: child
                                      ));
                                   },
                                   child: Row(
                                     key: ValueKey<String>(currentItem.id),
                                     children: [
                                        _MiniPlayerArtwork(songId: songId),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                currentItem.title,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                currentItem.artist ?? "Unknown",
                                                style: Theme.of(context).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                     ]
                                   )
                                 ),
                               ),
                              MiniPlayerVisualizer(
                                isPlaying: state.isPlaying,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 32,
                                ),
                                onPressed: () {
                                  if (state.isPlaying) {
                                    context.read<PlayerBloc>().add(PausePlayer());
                                  } else {
                                    context.read<PlayerBloc>().add(ResumePlayer());
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 16,
                          right: 16,
                          child: StreamBuilder<Duration>(
                            stream: AudioService.position,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              final duration = currentItem.duration ?? Duration.zero;
                              double progress = 0.0;
                              if (duration.inMilliseconds > 0) {
                                progress = position.inMilliseconds / duration.inMilliseconds;
                              }
                              progress = progress.clamp(0.0, 1.0);
                              return LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor.withOpacity(0.8)
                                ),
                                minHeight: 2,
                              );
                            },
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerArtwork extends StatelessWidget {
  final int songId;
  const _MiniPlayerArtwork({required this.songId});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkBorder: BorderRadius.circular(50),
          keepOldArtwork: true,
          nullArtworkWidget: Icon(Icons.music_note_rounded, color: Theme.of(context).primaryColor),
        ),
      );
  }
}
