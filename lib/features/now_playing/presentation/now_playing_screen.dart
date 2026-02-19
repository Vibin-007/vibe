import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'widgets/squiggly_slider.dart';
import '../../songs/bloc/player_bloc.dart';
import '../../playlist/bloc/playlist_bloc.dart';
import 'package:audio_service/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/glass_box.dart';
import '../../../core/services/user_preferences_service.dart';
 
import '../../../core/ui/action_feedback.dart'; // [NEW]
import 'widgets/mesh_gradient_background.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:blur/blur.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'dart:io';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  static Route route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  static final Map<String, PaletteGenerator> _paletteCache = {};
  PaletteGenerator? _palette;
  String? _lastSongId;
  late AnimationController _rotationController;
  late PageController _pageController;

  // Audio Output
  AudioDevice? _currentOutput;
  StreamSubscription<Set<AudioDevice>>? _deviceSubscription;
  List<AudioDevice> _allDevices = [];

  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
       duration: const Duration(seconds: 10),
       vsync: this,
    );
    _pageController = PageController(viewportFraction: 1.0);
    _initAudioOutputListener();
  }

  Future<void> _initAudioOutputListener() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // Initial fetch
    _updateAudioOutput(await session.getDevices());

    // Listen
    _deviceSubscription = session.devicesStream.listen((devices) {
      _updateAudioOutput(devices);
    });
  }

  void _updateAudioOutput(Set<AudioDevice> devices) {
    if (!mounted) return;
    
    // Filter for output devices only
    final all = devices.where((d) => 
      d.type == AudioDeviceType.builtInSpeaker ||
      d.type == AudioDeviceType.wiredHeadphones ||
      d.type == AudioDeviceType.wiredHeadset ||
      d.type == AudioDeviceType.bluetoothA2dp ||
      d.type == AudioDeviceType.bluetoothSco ||
      d.type == AudioDeviceType.bluetoothLe ||
      d.type == AudioDeviceType.hdmi
    ).toList();
    
    // Simple priority logic to guess "active" output
    // 1. Bluetooth A2DP/SCO
    // 2. Wired Headset
    // 3. Speaker/Built-in
    
    AudioDevice? active;
    
    // Check for Bluetooth first
    try {
      active = all.firstWhere((d) => 
        d.type == AudioDeviceType.bluetoothA2dp || d.type == AudioDeviceType.bluetoothSco || d.type == AudioDeviceType.bluetoothLe);
    } catch (_) {
      // Check for Wired
      try {
        active = all.firstWhere((d) => 
          d.type == AudioDeviceType.wiredHeadset || d.type == AudioDeviceType.wiredHeadphones);
      } catch (_) {
        // Fallback to speaker/receiver
        try {
          active = all.firstWhere((d) => d.type == AudioDeviceType.builtInSpeaker);
        } catch (_) {
          active = all.isNotEmpty ? all.first : null;
        }
      }
    }

    setState(() {
      _allDevices = all;
      _currentOutput = active;
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pageController.dispose();
    _deviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updatePalette(int songId, String fullId) async {
    if (_paletteCache.containsKey(fullId)) {
      setState(() {
        _palette = _paletteCache[fullId];
      });
      return;
    }

    final query = OnAudioQuery();
    final bytes = await query.queryArtwork(songId, ArtworkType.AUDIO, size: 500);
    if (bytes != null && mounted) {
      final palette = await PaletteGenerator.fromImageProvider(MemoryImage(bytes));
      _paletteCache[fullId] = palette;
      setState(() {
        _palette = palette;
      });
    }
  }

  void _showMoreOptions(MediaItem currentItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, playerState) {
            final rawId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
            final songId = rawId.contains('_') ? rawId.split('_').first : rawId;
            final isFavorite = playerState.favorites.contains(songId);
            return BlocBuilder<PlaylistBloc, PlaylistState>(
              builder: (context, playlistState) {
                // Check if song is in any playlist
                final playlistsContaining = playlistState.playlists.entries
                    .where((entry) => entry.value.contains(currentItem.id))
                    .map((e) => e.key)
                    .toList();
    
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    

                
                if (playlistsContaining.isNotEmpty)
                   ...playlistsContaining
                   .where((name) => name != 'Recently Played' && name != 'Most Played')
                   .map((name) => _buildOptionTile(
                     Icons.remove_circle_outline_rounded, 
                     'Remove from "$name"', 
                     () {
                        Navigator.pop(context);
                        final rawId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
                        final songId = rawId.contains('_') ? rawId.split('_').first : rawId;
                        context.read<PlaylistBloc>().add(RemoveFromPlaylist(name, int.parse(songId)));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from $name')));
                     }
                   )),

                _buildOptionTile(Icons.playlist_add_rounded, 'Add to Playlist', () {
                  Navigator.pop(context);
                  _showPlaylistDialog(SongModel({
                    '_id': int.parse(songId),
                    'title': currentItem.title,
                    'artist': currentItem.artist,
                    'album': currentItem.album,
                    'duration': currentItem.duration?.inMilliseconds,
                    '_uri': currentItem.extras?['uri'],
                  })); 
                }),
                // Sleep Timer removed as requested

                  ],
                );
              }
            );
          }
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => BlocListener<PlayerBloc, PlayerState>(
          listenWhen: (previous, current) => previous.queue.isNotEmpty && current.queue.isEmpty,
          listener: (context, state) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Theme aware background
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Up Next', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                    TextButton(
                      onPressed: () {
                         context.read<PlayerBloc>().add(ClearQueue());
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Queue cleared')));
                      },
                      child: const Text('Clear Queue', style: TextStyle(color: Colors.redAccent)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<PlayerBloc, PlayerState>(
                  builder: (context, state) {
                    if (state.queue.isEmpty) {
                      return Center(child: Text('Queue is empty', style: TextStyle(color: Theme.of(context).disabledColor)));
                    }
                    
                    final currentIndex = state.currentIndex ?? -1;
                    
                    // Split queue into:
                    // 1. Now Playing
                    // 2. Queue (User added)
                    // 3. Up Next (Original context or Autoplay)
                    final upcoming = state.queue.asMap().entries
                        .where((entry) => entry.key > currentIndex)
                        .toList();
                        
                      // Unified List Construction
                      final userQueue = upcoming
                        .where((entry) => entry.value.extras?['source'] == 'user')
                        .toList();
                        
                      final upNext = upcoming
                        .where((entry) => entry.value.extras?['source'] != 'user')
                        .toList();

                      final mixedList = <MediaItem>[];
                      
                      // 1. User Queue
                      mixedList.addAll(userQueue.map((e) => e.value));
                      
                      // 2. Separator (Only if we have both, or just always to mark the boundary?)
                      // If we have no user queue, separator is at top?
                      // Let's add a special Separator Item
                      final separatorItem = MediaItem(id: 'queue_separator', title: 'Up Next', artist: '');
                      mixedList.add(separatorItem);
                      
                      // 3. Up Next
                      mixedList.addAll(upNext.map((e) => e.value));

                      return ListView.builder(
                        itemCount: mixedList.length + 1,
                        padding: const EdgeInsets.only(bottom: 24),
                        findChildIndexCallback: (Key key) {
                          if (key is ValueKey<String>) {
                             final id = key.value;
                             // Check Separator
                             if (id == 'queue_separator') {
                               final idx = mixedList.indexWhere((e) => e.id == 'queue_separator');
                               return idx != -1 ? idx + 1 : null;
                             }
                             // Check List Items
                             final idx = mixedList.indexWhere((e) => e.id == id);
                             return idx != -1 ? idx + 1 : null;
                          }
                          return null;
                        },
                        itemBuilder: (context, index) {
                          // ... (Keep existing Header logic)
                          if (index == 0) {
                             return state.currentItem != null ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildQueueSectionHeader(context, "Now Playing"),
                                  _buildQueueItem(context, state.currentItem!, true, currentIndex),
                                  if (userQueue.isNotEmpty)
                                    _buildQueueSectionHeader(context, "Queue"),
                                ],
                              ) : const SizedBox.shrink();
                          }
                          
                          // Adjust index for list items
                          final listIndex = index - 1;
                          final item = mixedList[listIndex];
                          
                          if (item.id == 'queue_separator') {
                            if (upNext.isEmpty && userQueue.isEmpty) return const SizedBox.shrink(key: ValueKey('queue_separator'));
                            if (upNext.isEmpty) return const SizedBox.shrink(key: ValueKey('queue_separator'));

                            return Container(
                              key: const ValueKey('queue_separator'),
                              child: _buildQueueSectionHeader(context, "Up Next"),
                            );
                          }

                          final originalEntry = upcoming.firstWhere((e) => e.value.id == item.id, orElse: () => const MapEntry(-1, MediaItem(id: 'error', title: 'error')));
                          
                          if (originalEntry.key == -1) return const SizedBox.shrink(key: ValueKey('error'));

                          return _buildQueueItem(context, item, false, originalEntry.key);
                        },
                      );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
// ...
  Widget _buildQueueSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title, 
        style: TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          letterSpacing: 1.0,
        )
      ),
    );
  }

  Widget _buildQueueItem(BuildContext context, MediaItem item, bool isPlaying, int index) {
      final rawId = item.extras?['songId']?.toString() ?? item.id;
      final songId = int.tryParse(rawId) ?? int.tryParse(rawId.split('_').first) ?? 0;

      Widget content = ListTile(
          // Add RepaintBoundary to leading
          leading: RepaintBoundary(
            child: Container(
              width: 50,
              height: 50,
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
            ),
          ),
          title: Text(
            item.title, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaying ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isPlaying ? FontWeight.bold : null
            )
          ),
          subtitle: Text(item.artist ?? 'Unknown Artist', maxLines: 1, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          trailing: isPlaying ?  Icon(Icons.graphic_eq, color: Theme.of(context).primaryColor) : null,
          onTap: () {
            context.read<PlayerBloc>().add(SkipToQueueItem(index));
            Navigator.pop(context); 
          },
        );

      if (isPlaying) {
        return KeyedSubtree(
           key: ValueKey('playing_${item.id}'),
           child: content
        );
      }

      return Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.startToEnd,
        background: Container(
          color: Colors.redAccent,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (direction) {
           context.read<PlayerBloc>().add(RemoveFromQueue(index));
           ScaffoldMessenger.of(context).clearSnackBars(); 
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Removed from Queue'), 
               duration: Duration(milliseconds: 1000),
               behavior: SnackBarBehavior.floating,
             )
           );
        },
        child: content,
      );
  }

 




  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sleep Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 45, 60].map((mins) => ListTile(
            title: Text('$mins minutes'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Timer set for $mins minutes')));
            },
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      onTap: onTap,
    );
  }




  void _showCreatePlaylistInput(BuildContext context, SongModel song) {
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
                final name = controller.text;
                context.read<PlaylistBloc>().add(CreatePlaylist(name));
                context.read<PlaylistBloc>().add(AddToPlaylist(name, song));
                
                Navigator.pop(context); // Close Dialog
                // Close Sheet locally or rely on Bloc listener? 
                // We want to close the "Add to Playlist" sheet too.
                // But we are in a dialog ON TOP of the sheet.
                // So popping once closes dialog. 
                // We can pop again to close sheet.
                // Or pass a callback.
                // For now, let's assuming the sheet is still open.
                // Actually, let's close the sheet too for better UX.
              }
            },
            child: const Text('CREATE & ADD'),
          ),
        ],
      ),
    ).then((_) {
       // After dialog closes, if we created, we might want to close sheet?
       // Hard to know result here easily without state.
       // But usually user wants to go back to music.
       // Let's rely on user manually closing sheet if they cancelled.
       // If they added, we want to close sheet.
       // Let's move the double pop inside onPressed.
    });
  }

  void _showPlaylistDialog(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            final playlists = state.playlists.keys
                .where((name) => name != 'Recently Played' && name != 'Most Played')
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (playlists.isEmpty)
                   Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('No playlists created yet.'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            _showCreatePlaylistInput(context, song);
                          },
                          child: const Text("Create & Add"),
                        )
                      ],
                    ),
                  ),
                ...playlists.map((name) => ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: Text(name),
                  onTap: () {
                    context.read<PlaylistBloc>().add(AddToPlaylist(name, song));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to $name')));
                  },
                )),
                const SizedBox(height: 20),
                if (playlists.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text("Create New Playlist"),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistInput(context, song);
                    }
                  )
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleVolumeDrag(DragUpdateDetails details) {
    // Implement volume control logic here
    // For now, it's a visual placeholder as requested
    HapticFeedback.selectionClick();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (previous, current) => previous.queue.isNotEmpty && current.queue.isEmpty,
      listener: (context, state) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (previous, current) => 
            previous.currentItem?.id != current.currentItem?.id || 
            previous.isPlaying != current.isPlaying ||
            previous.playbackState != current.playbackState ||
            previous.favorites.length != current.favorites.length,
        builder: (context, state) {
          final currentItem = state.currentItem;
          // If queue is cleared, we might pop, but until then return empty to avoid errors
          if (currentItem == null) return const SizedBox(); 

          // Logic: item.id is now UNIQUE (e.g. "123_timestamp"). 
          // We must extract the actual Song ID from extras for Artwork/Palette.
          final rawId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
          final songId = int.tryParse(rawId) ?? int.tryParse(rawId.split('_').first) ?? 0;

        if (_lastSongId != currentItem.id) {
          _lastSongId = currentItem.id;
          _updatePalette(songId, currentItem.id);
        }

        // Animation Control
        if (state.isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!state.isPlaying && _rotationController.isAnimating) {
          _rotationController.stop();
        }

        final duration = currentItem.duration ?? Duration.zero;

        // Colors
        final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
        final iconColor = Theme.of(context).iconTheme.color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(color: Theme.of(context).scaffoldBackgroundColor),
              
              // Dynamic Background (Profile or Gradient)
              StreamBuilder<void>(
                stream: context.read<UserPreferencesService>().dataStream,
                builder: (context, _) {
                  final prefs = context.read<UserPreferencesService>();
                  final profilePath = prefs.getProfileImagePath();
                  final enabled = prefs.getEnableProfileBackground();

                  if (enabled && profilePath != null && File(profilePath).existsSync()) {
                    return Stack(
                      fit: StackFit.expand, 
                      children: [
                        Image.file(File(profilePath), fit: BoxFit.cover),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: Container(color: Colors.black.withOpacity(0.6)), // Darker overlay for text legibility
                        ),
                      ],
                    );
                  }

                  return MeshGradientBackground(
                    dominantColor: Theme.of(context).primaryColor,
                    accentColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  );
                }
              ),
              
              // Blur (Visual only, but on black it might not show much, keeping for safety or removing?)
              // Request was "black background", so removing gradient and simple blur.
              // Actually, just black is requested.
              
              // Content
              
              // Content
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: iconColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'NOW PLAYING',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2.0,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Removed More Options as per request
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Artwork (Rotating)
                  // Artwork (PageView for Swipe)
                  Expanded(
                    child: BlocListener<PlayerBloc, PlayerState>(
                      listenWhen: (prev, curr) => prev.currentIndex != curr.currentIndex,
                      listener: (context, state) {
                        if (state.currentIndex != null && 
                            _pageController.hasClients && 
                            _pageController.page?.round() != state.currentIndex) {
                          _isProgrammaticScroll = true;
                          _pageController.animateToPage(
                            state.currentIndex!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ).then((_) => _isProgrammaticScroll = false);
                        }
                      },
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          if (!_isProgrammaticScroll) {
                             context.read<PlayerBloc>().add(SkipToQueueItem(index));
                          }
                        },
                        itemCount: state.queue.length,
                        itemBuilder: (context, index) {
                          final item = state.queue[index];
                          final isCurrent = index == (state.currentIndex ?? 0);
                          final rawId = item.extras?['songId']?.toString() ?? item.id;
                          final artworkId = int.tryParse(rawId) ?? int.tryParse(rawId.split('_').first) ?? 0;
                          
                          // Rotation only for current item
                          return AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                // Only rotate if this page is the current song and playing
                                final angle = (isCurrent && state.isPlaying) 
                                    ? _rotationController.value * 6 * math.pi 
                                    : 0.0;
                                return Transform.rotate(
                                  angle: angle,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                alignment: Alignment.center,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // Shadow removed
                                  ),
                                  child: Container(
                                    height: MediaQuery.of(context).size.width,
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 2)
                                    ),
                                    child: Center(
                                      child: _MusicVisualizerIcon(
                                        color: Theme.of(context).primaryColor,
                                        isPlaying: state.isPlaying,
                                        size: 120, // Scaled for the center
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                    ),
                  ),

                  const Spacer(),

                  // Info & Controls
                  // Info & Controls
                  SizedBox(
                    width: double.infinity,
                    // Removed global margin to allow full-width slider
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title & Artist
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentItem.title,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentItem.artist ?? 'Unknown Artist',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              BlocBuilder<PlayerBloc, PlayerState>(
                                builder: (context, state) {
                                  // Use the same rawId/songId logic as elsewhere
                                  final rawId = currentItem.extras?['songId']?.toString() ?? currentItem.id;
                                  final songId = rawId.contains('_') ? rawId.split('_').first : rawId;
                                  
                                  final isFavorite = state.favorites.contains(songId);
                                  return IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: isFavorite ? Theme.of(context).primaryColor : textColor,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      context.read<PlayerBloc>().add(ToggleFavorite(songId));
                                      HapticFeedback.lightImpact();
                                    },
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // Seekbar (Full Width)
                        StreamBuilder<Duration>(
                          stream: context.read<PlayerBloc>().positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final validDuration = duration.inMilliseconds > 0 ? duration : const Duration(seconds: 1);
                            final progress = position.inMilliseconds / validDuration.inMilliseconds;
                            
                            // Only update if not dragging? 
                            // Usually simple slider is fine if onChangeStart/End handle seeking.
                            // But here I'm using `onChanged` which seeks.
                            // If I want smoother dragging, I should use a local state for dragging value.
                            // But for now, basic StreamBuilder is much better than BlocBuilder.
                            
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    trackShape: const RectangularSliderTrackShape(), 
                                    trackHeight: 4,
                                    activeTrackColor: Theme.of(context).primaryColor,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Theme.of(context).primaryColor,
                                    overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  ),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width, 
                                    child: Slider(
                                      value: progress.clamp(0.0, 1.0),
                                      onChanged: (v) {
                                        final newPosition = Duration(milliseconds: (v * validDuration.inMilliseconds).toInt());
                                        context.read<PlayerBloc>().add(SeekPosition(newPosition));
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(position), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
                                      Text(_formatDuration(duration.inMilliseconds > 0 ? duration : Duration.zero), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        ),

                        const SizedBox(height: 20),

                        // Controls
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.info_outline_rounded, 
                                  color: textColor.withOpacity(0.7), 
                                  size: 24
                                ),
                                onPressed: () {
                                  _showSongInfo(context, currentItem);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.skip_previous_rounded, color: textColor, size: 40),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.read<PlayerBloc>().add(PreviousSong());
                                },
                              ),
                              Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: textColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: textColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                                  ]
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Theme.of(context).scaffoldBackgroundColor, 
                                    size: 36,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    if (state.isPlaying) {
                                      context.read<PlayerBloc>().add(PausePlayer());
                                    } else {
                                      context.read<PlayerBloc>().add(ResumePlayer());
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.skip_next_rounded, color: textColor, size: 40),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.read<PlayerBloc>().add(NextSong());
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  state.playbackState?.repeatMode == AudioServiceRepeatMode.one 
                                    ? Icons.repeat_one_rounded 
                                    : Icons.repeat_rounded, 
                                  color: (state.playbackState?.repeatMode != AudioServiceRepeatMode.none) 
                                    ? textColor 
                                    : textColor.withOpacity(0.4), 
                                  size: 24
                                ),
                                onPressed: () {
                                  AudioServiceRepeatMode nextMode;
                                  if (state.playbackState?.repeatMode == AudioServiceRepeatMode.none) {
                                    nextMode = AudioServiceRepeatMode.all;
                                  } else if (state.playbackState?.repeatMode == AudioServiceRepeatMode.all) {
                                    nextMode = AudioServiceRepeatMode.one;
                                  } else {
                                    nextMode = AudioServiceRepeatMode.none;
                                  }
                                  context.read<PlayerBloc>().add(SetLoopMode(nextMode));
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Bottom Actions (Queue & Output)
                        Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
Padding(
                               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(Icons.speaker_group_outlined, size: 20, color: textColor.withOpacity(0.7)), 
                                   const SizedBox(width: 8),
                                   Flexible(
                                     child: Text(
                                       (_currentOutput?.type == AudioDeviceType.bluetoothA2dp || 
                                        _currentOutput?.type == AudioDeviceType.bluetoothLe || 
                                        _currentOutput?.type == AudioDeviceType.bluetoothSco) 
                                          ? (_currentOutput?.name ?? "This Device")
                                          : "This Device", 
                                       style: TextStyle(color: textColor.withOpacity(0.7), overflow: TextOverflow.ellipsis), 
                                       maxLines: 1
                                     ),
                                   ),
                                 ],
                               ),
                             ),


                             
                             TextButton.icon(
                               onPressed: () => _showQueueSheet(context), 
                               icon: Icon(Icons.queue_music_rounded, size: 20, color: textColor.withOpacity(0.7)), 
                               label: Text("Queue", style: TextStyle(color: textColor.withOpacity(0.7)))
                             ),
                           ],
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ));
  }
}

// Custom Visualizer Widget for Now Playing
class _MusicVisualizerIcon extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  final double size;

  const _MusicVisualizerIcon({
    required this.color,
    required this.isPlaying,
    required this.size,
  });

  @override
  State<_MusicVisualizerIcon> createState() => _MusicVisualizerIconState();
}

class _MusicVisualizerIconState extends State<_MusicVisualizerIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // shrink wrap
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2), // spacing
                  child: _VisualizerBar(
                    color: widget.color,
                    animationValue: _controller.value,
                    index: index,
                    isPlaying: widget.isPlaying,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _VisualizerBar extends StatelessWidget {
  final Color color;
  final double animationValue;
  final int index;
  final bool isPlaying;

  const _VisualizerBar({
    required this.color,
    required this.animationValue,
    required this.index,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    // Generate pseudo-random height
    // offsets: 0.0, 0.25, 0.5, 0.75
    final offset = index * 0.25;
    final position = (animationValue + offset) % 1.0;
    
    // Sine wave 
    final wave = math.sin(position * 2 * math.pi);
    final normalized = (wave + 1) / 2;
    
    // Scale height between 20% and 100%
    final heightFactor = isPlaying ? (0.2 + 0.8 * normalized) : 0.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            height: constraints.maxHeight * heightFactor,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        );
      }
    );
  }
  }


  void _showSongInfo(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(2)
                )
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Song Info", 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color
              )
            ),
            const SizedBox(height: 24),
            _buildInfoRow(context, "Title", item.title),
            _buildInfoRow(context, "Artist", item.artist ?? "Unknown"),
            _buildInfoRow(context, "Album", item.album ?? "Unknown"),
            const Divider(height: 32),
            _buildInfoRow(context, "Format", item.extras?['displayName']?.toString().split('.').last.toUpperCase() ?? "MP3"), 
            _buildInfoRow(context, "Size", _formatBytes(item.extras?['size'])),
            _buildInfoRow(context, "Path", item.extras?['data'] ?? item.extras?['uri'] ?? "Unknown"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label, 
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              )
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w500
              )
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(dynamic size) {
    if (size == null) return "Unknown";
    int bytes = (size is int) ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes <= 0) return "Unknown";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d > 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
