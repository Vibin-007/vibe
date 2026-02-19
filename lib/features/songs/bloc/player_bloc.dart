import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/services/audio_handler.dart';
import '../../../core/services/user_preferences_service.dart';
import 'player_event.dart';
export 'player_event.dart';



// State
class PlayerState extends Equatable {
  final MediaItem? currentItem;
  final bool isPlaying;
  final PlaybackState? playbackState;
  final List<MediaItem> queue;
  final List<String> favorites;

  const PlayerState({
    this.currentItem,
    this.isPlaying = false,
    this.playbackState,
    this.queue = const [],
    this.favorites = const [],
    this.sleepTimerEndTime,
  });

  final DateTime? sleepTimerEndTime;

  PlayerState copyWith({
    MediaItem? currentItem,
    bool? isPlaying,
    PlaybackState? playbackState,
    List<MediaItem>? queue,
    List<String>? favorites,
    DateTime? sleepTimerEndTime,
    bool clearSleepTimer = false,
  }) {
    return PlayerState(
      currentItem: currentItem ?? this.currentItem,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackState: playbackState ?? this.playbackState,
      queue: queue ?? this.queue,
      favorites: favorites ?? this.favorites,
      sleepTimerEndTime: clearSleepTimer ? null : (sleepTimerEndTime ?? this.sleepTimerEndTime),
    );
  }

  @override
  List<Object?> get props => [currentItem, isPlaying, playbackState, queue, favorites, sleepTimerEndTime];

  int? get currentIndex {
    if (currentItem == null || queue.isEmpty) return null;
    
    // With unique IDs, we can strictly trust the ID match.
    // If playbackState has a queueIndex, we verify it matches the currentItem's unique ID.
    if (playbackState?.queueIndex != null && 
        playbackState!.queueIndex! < queue.length &&
        queue[playbackState!.queueIndex!].id == currentItem!.id) {
      return playbackState!.queueIndex;
    }
    
    // Fallback: Find by Unique ID
    final index = queue.indexWhere((item) => item.id == currentItem!.id);
    return index != -1 ? index : null;
  }
}

// Bloc
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final MyAudioHandler _audioHandler;
  final UserPreferencesService _prefs;
  Timer? _sleepTimer;

  
  // Expose position stream for smooth UI updates
  Stream<Duration> get positionStream => _audioHandler.positionStream;

  PlayerBloc(this._audioHandler, this._prefs) : super(PlayerState(favorites: _prefs.getFavorites())) {
    
    _audioHandler.mediaItem.listen((item) {

      add(UpdateMediaItem(item));
    });

    _audioHandler.playbackState.listen((state) {
      add(UpdatePlaybackState(state));
    });

    // Debounce empty queue updates to prevent UI blinking
    Timer? queueDebounce;
    
    _audioHandler.queue.listen((queue) {
      queueDebounce?.cancel();
      
      if (queue.isEmpty) {
        // Wait briefly before emitting empty state
        queueDebounce = Timer(const Duration(milliseconds: 100), () {
           add(UpdateQueue(queue));
        });
      } else {
        // Emit immediately if valid
        add(UpdateQueue(queue));
      }
    });

    on<UpdateMediaItem>((event, emit) async {
      emit(state.copyWith(currentItem: event.item));
    });
    on<UpdatePlaybackState>((event, emit) {
      emit(state.copyWith(
        isPlaying: event.state.playing,
        playbackState: event.state,
      ));
    });
    on<UpdateQueue>((event, emit) => emit(state.copyWith(queue: event.queue)));

    on<PlaySong>((event, emit) async {
      final queue = state.queue;
      final songs = event.playlist;
      final index = event.index;

      bool isSameQueue = false;
      if (queue.length == songs.length && queue.isNotEmpty) {
        // Heuristic: Check First, Last, and Target items
        final firstMatch = queue.first.extras?['songId'] == songs.first.id.toString();
        final lastMatch = queue.last.extras?['songId'] == songs.last.id.toString();
        
        // Also check the specific song being clicked to ensure it matches
        final targetMatch = (index >= 0 && index < queue.length) && 
                            queue[index].extras?['songId'] == songs[index].id.toString();

        if (firstMatch && lastMatch && targetMatch) {
          isSameQueue = true;
        }
      }

      if (isSameQueue) {
         // Optimization: Queue matches, just jump to index
         // This preserves the unique IDs and prevents UI blinking
         await _audioHandler.skipToQueueItem(index);
         await _audioHandler.play();
      } else {
        // New context, load full playlist
        await _audioHandler.setPlaylist(songs, initialIndex: index);
        await _audioHandler.play();
      }
    });

    on<PausePlayer>((event, emit) => _audioHandler.pause());
    on<ResumePlayer>((event, emit) => _audioHandler.play());
    on<NextSong>((event, emit) => _audioHandler.skipToNext());
    on<PreviousSong>((event, emit) => _audioHandler.skipToPrevious());
    on<SeekPosition>((event, emit) => _audioHandler.seek(event.position));
    on<SkipToQueueItem>((event, emit) => _audioHandler.skipToQueueItem(event.index));
    on<ClearQueue>((event, emit) => _audioHandler.clearQueue());

    on<ToggleFavorite>((event, emit) async {
      await _prefs.toggleFavorite(event.songId);
      emit(state.copyWith(favorites: _prefs.getFavorites()));
    });

    on<AddToQueue>((event, emit) async {
      final mediaItem = _createMediaItem(event.song, source: 'user');
      await _audioHandler.addQueueItem(mediaItem);
    });

    on<RemoveFromQueue>((event, emit) async {
      await _audioHandler.removeQueueItemAt(event.index);
    });

    on<ReorderQueueItem>((event, emit) async {
      await _audioHandler.moveQueueItem(event.oldIndex, event.newIndex);
    });

    on<PlayNextEvent>((event, emit) async {
      final mediaItem = _createMediaItem(event.song, source: 'user');
      await _audioHandler.playNext(mediaItem);
    });

    on<SetSleepTimer>((event, emit) {
      _sleepTimer?.cancel();
      if (event.duration != null) {
        final endTime = DateTime.now().add(event.duration!);
        emit(state.copyWith(sleepTimerEndTime: endTime));
        
        _sleepTimer = Timer(event.duration!, () {
          add(PausePlayer());
          _sleepTimer = null;
          // We can't easily emit from here without adding another event or making _sleepTimer part of state logic better.
          // But since we pause, the UI might just need to know if it's running. 
          // Ideally we should clear the endTime when it fires.
          add(ClearSleepTimer());
        });
      } else {
        emit(state.copyWith(clearSleepTimer: true)); // Explicitly clear it
      }
    });


    on<SetLoopMode>((event, emit) => _audioHandler.setRepeatMode(event.mode));
    
    on<SetSpeed>((event, emit) => _audioHandler.setSpeed(event.speed));
    on<SetPitch>((event, emit) => _audioHandler.customAction('setPitch', {'pitch': event.pitch}));
    on<SetVolume>((event, emit) => _audioHandler.customAction('setVolume', {'volume': event.volume}));

    on<ClearSleepTimer>((event, emit) => emit(state.copyWith(clearSleepTimer: true)));
  }

  MediaItem _createMediaItem(SongModel song, {String source = 'user'}) {
    // Generate a unique ID for this instance of the song in the queue
    // Format: "songId_timestamp_random"
    final uniqueId = '${song.id}_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 8999))}';
    
    return MediaItem(
      id: uniqueId, 
      album: song.album ?? '',
      title: song.title,
      artist: song.artist ?? '',
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
      extras: {
        'uri': song.uri, 
        'source': source,
        'songId': song.id.toString(), // Store original ID for artwork/logic
        'size': song.size,
        'data': song.data,
        'displayName': song.displayName,
      },
    );
  }
}


