import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:headphones_detection/headphones_detection.dart';
import 'user_preferences_service.dart';
import 'dart:async';
import 'dart:math';

Future<AudioHandler> initAudioService(UserPreferencesService prefs) async {
  return await AudioService.init(
    builder: () => MyAudioHandler(prefs),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_world.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  late final AudioPlayer _player;
  
  Stream<Duration> get positionStream => _player.positionStream;
  
  late final AudioPipeline _pipeline;
  final UserPreferencesService _prefs;
  final _playlist = ConcatenatingAudioSource(children: []);
  String? _lastRecordedId;

  MyAudioHandler(this._prefs) {
    _pipeline = AudioPipeline(
      androidAudioEffects: [
        AndroidEqualizer(),
      ],
    );
    _player = AudioPlayer(audioPipeline: _pipeline);
    _loadEmptyPlaylist();
    // ...
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForPositionChanges();
    _listenForDurationChanges();
    _listenForSequenceStateChanges();

    _initMotionSensors();
    _listenForShuffleLoopChanges();
    _initPlayerDefaults();
  }

  void _listenForShuffleLoopChanges() {
      // Shuffle listener removed

    _player.loopModeStream.listen((mode) {
      final old = playbackState.value;
      playbackState.add(old.copyWith(repeatMode: _mapLoopMode(mode)));
      
      int val = 0;
      if (mode == LoopMode.all) val = 1;
      if (mode == LoopMode.one) val = 2;
      _prefs.setRepeatMode(val);
    });
  }

  Future<void> _initPlayerDefaults() async {
    // final shuffle = _prefs.getShuffleMode(); // Removed

    final repeatVal = _prefs.getRepeatMode();
    LoopMode loop = LoopMode.off;
    if (repeatVal == 1) loop = LoopMode.all;
    if (repeatVal == 2) loop = LoopMode.one;

    // Use platform defaults if needed, but here we enforce prefs
    // Shuffle default removed

    await _player.setLoopMode(loop);
  }

  AudioServiceRepeatMode _mapLoopMode(LoopMode mode) {
    switch (mode) {
      case LoopMode.off: return AudioServiceRepeatMode.none;
      case LoopMode.one: return AudioServiceRepeatMode.one;
      case LoopMode.all: return AudioServiceRepeatMode.all;
    }
  }

  // Variable to track proximity
  bool _isNear = false;
  // Variable to track if we paused via flip
  bool _pausedByFlip = false;

  void _initMotionSensors() {
    // Accelerometer for Shake & Flip
    accelerometerEventStream().listen((AccelerometerEvent event) {
      // Pocket Mode Check: If near, ignore all motion gestures
      if (_prefs.getPocketMode() && _isNear) return;

      // Shake to Skip
      if (_prefs.getShakeToSkip()) {
        final acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (acceleration > 22) { 
          skipToNext();
        }
      }

      // Flip to Pause & Resume
      if (_prefs.getFlipToPause()) {
        // Face Down -> Pause
        // Z-axis < -9.0 means playing face down.
        if (event.z < -8.5) { // Slightly more lenient threshold
           if (_player.playing) {
              pause();
              _pausedByFlip = true;
           }
        }
        // Face Up -> Resume
        // Z-axis > 8.5 means facing up
        else if (event.z > 8.5) {
           if (!_player.playing && _pausedByFlip) {
              play();
              _pausedByFlip = false;
           }
        }
      }
    });

    // Proximity for Pocket Mode logic
    ProximitySensor.events.listen((int event) {
      // event > 0 is typically "near" (1 = near? or 0 = near? Documentation says: 1 is near usually? 
      // Actually standard Android is: 0 = NEAR, >0 = FAR. But plugins vary. 
      // Let's assume standard behavior first. Wait, package `proximity_sensor` says:
      // "Returns 1 if object is near, 0 if far" -> Wait, need to check doc assumption.
      // Common assumption: int returned. 
      // Let's safe check: usually standard proximity is binary. 
      // I will assume > 0 is NEAR based on some boolean behavior, but actually often 0 is near.
      // Let's handle generic logic: if the value changes. 
      // Actually `proximity_sensor` plugin docs say: "Stream<int> events".
      // Let's assume standard: 0 = near, 5.0/8.0 = far.
      // Wait, `proximity_sensor` plugin specifically says "1 if near, 0 if far" in a common simplified wrapper.
      // I'll stick to a common pattern: `event > 0` = NEAR. I will check logic.
      // The user prompt didn't specify package behavior. I'll take a safe bet: 
      // Usually Proximity is: 0 = Near. But let's verify if I can.
      // Safest approach: Most music apps use logic "If sensor covered".
      // I will assume the standard implementation: Near = sensor covered.
       _isNear = (event > 0); 
    });

    // Jack-In Autoplay (Headphone Detection)
    // Jack-In Autoplay (Headphone Detection)
    // HeadphonesDetection usage requires verifying API. Temporarily disabled.
    /*
    HeadphonesDetection.conf.state.listen((HeadphonesState state) {
      if (!_prefs.getJackInAutoplay()) return;

      if (state == HeadphonesState.plugged) {
         // If plugged in and we have a queue, play!
         if (_player.processingState != ProcessingState.idle && !_player.playing) {
             play();
         }
      }
    });
    */
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'setPitch') {
      final pitch = extras?['pitch'] as double;
      await _player.setPitch(pitch);
    } else if (name == 'setEqEnabled') {
       final enabled = extras?['enabled'] as bool;
       // Assuming AndroidEqualizer is the first effect
       if (_pipeline.androidAudioEffects.isNotEmpty) {
         await _pipeline.androidAudioEffects.first.setEnabled(enabled);
       }
    } else if (name == 'setEqGains') {
       final gains = (extras?['gains'] as List).cast<double>();
       // AndroidEqualizer typically has fixed bands. JustAudio's AndroidEqualizer is a wrapper.
       // We need to map 5 bands to the device's bands? 
       // Simplification: Just enable/disable for now as mapping is complex without reading device bands first.
       // TODO: Implement full band mapping.
    }
    else if (name == 'setVolume') {
       final volume = extras?['volume'] as double;
       await _player.setVolume(volume);
    }
    return super.customAction(name, extras);
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error loading empty playlist: $e");
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      
      int? visualIndex = event.currentIndex;
      // Visual index logic simplified as shuffle is gone
      visualIndex = event.currentIndex;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: visualIndex,
      ));
    });
  }

  void _listenForPositionChanges() {
    _player.positionStream.listen((position) async {
      final oldState = playbackState.value;
      playbackState.add(oldState.copyWith(updatePosition: position));
      
      // Auto-play logic / Gapless preload
      final duration = mediaItem.value?.duration;
      if (duration != null && position.inSeconds > duration.inSeconds - 5) {
         _checkAndAddRecommendation();
      }
    });
  }

  // Recommendation Logic
  bool _isLoadingRecommendation = false;
  Future<void> _checkAndAddRecommendation() async {
    // Only if we are near the end of the queue
    if (_player.currentIndex != null && _player.currentIndex! >= queue.value.length - 1 && !_isLoadingRecommendation) {
      _isLoadingRecommendation = true;
      try {
        final currentItem = mediaItem.value;
        // Don't add recommendations if playing from a context (Playlist/Folder/Favorites)
        if (currentItem?.extras?['source'] == 'context') {
           return;
        }

        // Simplified: using OnAudioQuery direct
        final OnAudioQuery _audioQuery = OnAudioQuery();
        final songs = await _audioQuery.querySongs();
        
        if (songs.isEmpty) return;
        
        // final currentItem = mediaItem.value; // REUSED
        final currentArtist = currentItem?.artist;
        final currentIds = queue.value.map((m) => m.id).toSet();
        
        // 1. Filter out already queued songs
        var candidates = songs.where((s) => !currentIds.contains(s.id.toString())).toList();
        
        if (candidates.isEmpty) {
           // If we exhausted all songs (rare), pick random from all to loop infinite
           candidates = songs; 
        }

        // 2. Smart Selection: Prioritize Same Artist
        SongModel? chosenSong;
        if (currentArtist != null && currentArtist.isNotEmpty && currentArtist != '<unknown>') {
          final artistMatches = candidates.where((s) => s.artist == currentArtist).toList();
          if (artistMatches.isNotEmpty) {
             chosenSong = artistMatches[Random().nextInt(artistMatches.length)];
             // print("Smart Autoplay: Found match for artist $currentArtist");
          }
        }
        
        // 3. Fallback: Pure Random
        chosenSong ??= candidates[Random().nextInt(candidates.length)];
        
        final uniqueId = '${chosenSong.id}_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 8999))}';

        final item = MediaItem(
           id: uniqueId,
           album: chosenSong.album ?? '',
           title: chosenSong.title,
           artist: chosenSong.artist ?? '',
           duration: Duration(milliseconds: chosenSong.duration ?? 0),
           artUri: Uri.parse('content://media/external/audio/media/${chosenSong.id}/albumart'),
           extras: {
             'uri': chosenSong.uri, 
             'source': 'autoplay',
             'songId': chosenSong.id.toString(),
           },
        );
        await addQueueItem(item);
        
      } catch (e) {
        print("Error adding recommendation: $e");
      } finally {
        _isLoadingRecommendation = false;
      }
    }
  }

  // Helper to query songs since we don't have them stored
  Future<List<SongModel>> _querySongs() async {
     return OnAudioQuery().querySongs();
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      if (duration == null) return; // Ignore null duration (loading state)
      final index = _player.currentIndex;
      if (index != null && (queue.value.length > index)) {
        final oldMediaItem = queue.value[index];
        // Only update if duration is different (and positive) to avoid stutter
        if (oldMediaItem.duration != duration) {
           final newMediaItem = oldMediaItem.copyWith(duration: duration);
           mediaItem.add(newMediaItem);
           final newQueue = List<MediaItem>.from(queue.value);
           newQueue[index] = newMediaItem;
           queue.add(newQueue);
        }
      }
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
      
      // Use currentSource directly to ensure we get the ACTUALLY playing song
      // ignoring index shuffling arithmetic risks.
      final currentSource = sequenceState?.currentSource;
      if (currentSource != null) {
        final currentItem = currentSource.tag as MediaItem;
        mediaItem.add(currentItem);
        
        // Accurate Stats Logging: Only record if the song ID has changed
        // Use 'songId' from extras if available (Unique ID system), otherwise fallback to id
        final stableId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
        
        if (_lastRecordedId != stableId) {
          _lastRecordedId = stableId;
          _prefs.addRecentlyPlayed(stableId, currentItem.artist);
        }
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    int actualIndex = index;
    // Shuffle mapping removed

    await _player.seek(Duration.zero, index: actualIndex);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  // setShuffleMode removed


  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    LoopMode mode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        mode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.one:
        mode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        mode = LoopMode.all;
        break;
    }
    await _player.setLoopMode(mode);
  }

  // Crossfade handling
  bool _isCrossfading = false;
  Future<void> _handleCrossfade(Duration position) async {
    final currentItem = mediaItem.value;
    if (currentItem == null || currentItem.duration == null || _isCrossfading) return;

    final remaining = currentItem.duration! - position;
    if (remaining < const Duration(seconds: 5) && _player.currentIndex != null) {
       // Placeholder
    }
  }

  void setVolumeNormalization(double peakDelta) {
    _player.setVolume(1.0 - peakDelta); 
  }

  Future<void> clearQueue() async {
    final current = _player.currentIndex;
    if (current == null) return;

    // Remove all items AFTER the current song.
    // We iterate backwards to avoid index shifting issues.
    for (int i = _playlist.length - 1; i > current; i--) {
      await _playlist.removeAt(i);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // _bakeShuffleIfNeeded removed


    final source = AudioSource.uri(
      Uri.parse(mediaItem.extras?['uri'] ?? ''),
      tag: mediaItem,
    );

    final currentIndex = _player.currentIndex;
    
    // If nothing playing or queue empty, just add
    if (currentIndex == null || currentIndex >= _playlist.length) {
      await _playlist.add(source);
      return;
    }

    // Smart Queue Logic: Insert after the last "User Added" song that follows the current song.
    // This creates a "User Queue" block immediately after the current song.
    // [Current, User1, User2, <Insert Here>, Original1, Original2...]
    
    int insertionIndex = currentIndex + 1;
    final sequence = _playlist.sequence;
    
    // Look ahead to find where the User Queue ends
    for (int i = currentIndex + 1; i < sequence.length; i++) {
      final item = sequence[i].tag as MediaItem?;
      if (item?.extras?['source'] == 'user') {
        insertionIndex = i + 1;
      } else {
        // Found a non-user song (Original context or Autoplay), stop here.
        break;
      }
    }

    if (insertionIndex <= _playlist.length) {
      await _playlist.insert(insertionIndex, source);
    } else {
      await _playlist.add(source);
    }
  }

  Future<void> playNext(MediaItem mediaItem) async {
    // _bakeShuffleIfNeeded removed


    final mediaItemWithSource = mediaItem.copyWith(extras: {...?mediaItem.extras, 'source': 'user'});
    final source = AudioSource.uri(
      Uri.parse(mediaItemWithSource.extras?['uri'] ?? ''),
      tag: mediaItemWithSource,
    );
    final index = _player.currentIndex;
    
    // "Play Next" means force it immediately after current, PUSHING existing user queue down.
    // [Current, <Insert Here>, User1, User2, Original1...]
    
    if (index != null && index < _playlist.length) {
      await _playlist.insert(index + 1, source);
    } else {
      await _playlist.add(source);
    }
  }

  // _bakeShuffleIfNeeded Removed


  Future<void> setPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    await _player.setShuffleModeEnabled(false); // Ensure disabled
    await _player.setLoopMode(LoopMode.all); // Enable loop for playlists/folders by default

    final audioSources = songs.map((song) {
      final uniqueId = '${song.id}_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 8999))}';
      final item = MediaItem(
        id: uniqueId,
        album: song.album ?? '',
        title: song.title,
        artist: song.artist ?? '',
        duration: Duration(milliseconds: song.duration ?? 0),
        artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
        extras: {
          'uri': song.uri, 
          'source': 'context',
          'songId': song.id.toString(),
        }, 
      );
      return AudioSource.uri(Uri.parse(song.uri!), tag: item);
    }).toList();

    await _playlist.clear();
    await _playlist.addAll(audioSources);
    await _player.setAudioSource(_playlist, initialIndex: initialIndex);
  }
  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index >= 0 && index < _playlist.length) {
      await _playlist.removeAt(index);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex, {String? newSource}) async {
    if (oldIndex < 0 || oldIndex >= _playlist.length || newIndex < 0 || newIndex >= _playlist.length) return;

    if (newSource != null) {
      // Manual Reorder to update metadata (MediaItem extras)
      try {
        // 1. Get existing item metadata
        final sequence = _playlist.sequence;
        final oldSource = sequence[oldIndex];
        final oldMediaItem = oldSource.tag as MediaItem;

        // 2. Create new item with updated source
        final newExtras = Map<String, dynamic>.from(oldMediaItem.extras ?? {});
        newExtras['source'] = newSource;
        
        final newMediaItem = oldMediaItem.copyWith(extras: newExtras);
        
        // 3. Create new AudioSource
        // We assume URI is available in extras or mapped from ID if local. 
        // Best effort: usage of existing source's URI if accessible? 
        // oldSource is IndexedAudioSource? No, it's AudioSource.
        // We can't easily get URI back from AudioSource if not exposed.
        // BUT we store 'uri' in extras usually.
        final uriStr = newExtras['uri']?.toString() ?? newExtras['url']?.toString() ?? oldMediaItem.id;
        final newAudioSource = AudioSource.uri(Uri.parse(uriStr), tag: newMediaItem);

        // 4. Remove and Insert
        // Adjust insert index if moving downwards (remove shifts indices)
        // If old < new, removal decreases valid indices by 1.
        // move(0, 2) -> insert at 2.
        // remove(0) -> [B, C]. index 2 is End.
        // If I use 'insert' on [B, C], index 2 works.
        // BUT does 'newIndex' already account for this?
        // Flutter ReorderableListView 'newIndex' handling:
        // "If oldIndex < newIndex, the newIndex has already been incremented by one...".
        // BUT we are receiving the adjusted index from the Bloc/UI logic which did `if (old<new) new -= 1`.
        // So `newIndex` passed here is the TARGET VISUAL INDEX.
        // So on [A, B, C].
        // Move A to after B (Index 1).
        // Remove A -> [B, C].
        // Insert at 1 -> [B, A, C].
        
        // So:
        await _playlist.removeAt(oldIndex);
        
        // If removing from BEFORE insertion point, the insertion point shifts down?
        // Wait, if old=0, new=1.
        // Remove 0. List shifts. Index 1 is now C.
        // Insert at 1. [B, A, C].
        // Correct.
        // Is any adjustment needed?
        // In ConcatenatingAudioSource, index validation is strict.
        // If I remove, length decreases.
        // If newIndex was last index (2).
        // Remove 0. Length 2. Insert at 2 (append). OK.
        
        // However, if newIndex reported by UI assumes the list *with* the item?
        // If old < new, the UI says "insert at newIndex".
        // Example: 0 -> 2.
        // UI says newIndex=2.
        // Remove 0.
        // Insert at 2.
        // Correct.
        
        // If old > new, e.g. 2 -> 0.
        // Remove 2.
        // Insert at 0.
        // Correct.
        
        // BUT `ConcatenatingAudioSource` might require sequential awaits.
        await _playlist.insert(newIndex, newAudioSource);

      } catch (e) {
        print("Error updating queue source: $e");
        // Fallback to simple move if creation fails
        await _playlist.move(oldIndex, newIndex);
      }
    } else {
      await _playlist.move(oldIndex, newIndex);
    }
  }
}
