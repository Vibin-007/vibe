import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../mini_player/presentation/mini_player.dart';
import '../../songs/presentation/songs_screen.dart';
import '../../playlist/presentation/playlist_screen.dart';
import '../../account/presentation/account_screen.dart';
import '../../../core/services/user_preferences_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../../core/ui/custom_app_bar.dart';
import '../../playlist/bloc/playlist_bloc.dart';
import 'dart:async';
import 'package:proximity_sensor/proximity_sensor.dart';
import '../../songs/bloc/songs_state.dart'; 
import '../../songs/bloc/songs_bloc.dart';
import '../../songs/bloc/player_bloc.dart'; // Ensure PlayerBloc is imported
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart'; // For SongModel map logic


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  List<String> _currentLayout = [];
  
  // Mapping of IDs to pages and icons
  final Map<String, Widget> _pageMap = {
    'home': const DashboardScreen(),
    'songs': const SongsScreen(),
    'playlists': const PlaylistScreen(),
    'account': const AccountScreen(),
  };

  final Map<String, IconData> _iconMap = {
    'home': Icons.home_rounded,
    'songs': Icons.music_note_rounded,
    'playlists': Icons.playlist_play_rounded,
    'account': Icons.person_rounded,
  };
  
  final Map<String, IconData> _outlineIconMap = {
    'home': Icons.home_outlined,
    'songs': Icons.music_note_outlined,
    'playlists': Icons.playlist_play_outlined,
    'account': Icons.person_outline_rounded,
  };
  
  final Map<String, String> _titleMap = {
    'home': 'Home',
    'songs': 'Songs',
    'playlists': 'Playlists',
    'account': 'Account',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadLayout();
    
    // Defer sync listeners to ensure providers are ready? 
    // Actually context.read is safe here.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _initSyncListeners();
    // });

    // Listen for preference changes to reload layout
    RepositoryProvider.of<UserPreferencesService>(context).dataStream.listen((_) {
      if (mounted) {
        _loadLayout();
        context.read<PlaylistBloc>().add(LoadPlaylists());
      }
    });
  }
  

  
  // Cache last announced state to avoid loop/spam
  String? _lastAnnouncedSongId;
  bool? _lastAnnouncedPlaying;

  void _loadLayout() {
    final prefs = RepositoryProvider.of<UserPreferencesService>(context);
    List<String> layout = prefs.getNavigationLayout();
    
    // Check if layout changed meaningfully to avoid unnecessary rebuilds if possible,
    // but for now simple setState is fine.
    if (_currentLayout.toString() != layout.toString()) {
       setState(() {
         _currentLayout = layout;
         // Reset index if out of bounds or try to keep same page?
         // Simplest: clamp index
         if (_currentIndex >= _currentLayout.length) {
            _currentIndex = 0;
            _pageController.jumpToPage(0);
         }
       });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  


  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build pages based on layout
    final pages = _currentLayout.map((id) => _pageMap[id] ?? const SizedBox()).toList();
    
    // Current Page Title
    final currentId = _currentLayout.isNotEmpty ? _currentLayout[_currentIndex] : 'home';
    final currentTitle = _titleMap[currentId] ?? 'Vibe';

    return Scaffold(
      extendBody: true, 
      body: BlocListener<PlayerBloc, PlayerState>(
        listenWhen: (previous, current) => previous.currentItem?.id != current.currentItem?.id,
        listener: (context, state) {
          if (state.currentItem != null) {
             // _checkAndShowMemory(state.currentItem!);

          }
        },
        child: Stack(
          children: [
            // Content PageView
            PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: pages,
          ),
          
          // Floating Glass App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top, 
            left: 0,
            right: 0,
            child: FloatingGlassAppBar(
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation),
                    child: child
                  ),
                ),
                child: Text(
                  currentTitle,
                  key: ValueKey<String>(currentTitle),
                ),
              ),
              actions: [
                for (int i = 0; i < _currentLayout.length; i++)
                   _buildNavIcon(i, _currentLayout[i]),
              ],
            ),
          ),

          // MiniPlayer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: currentId == 'home' ? -100 : 0, // Hide based on ID not index
            child: const MiniPlayer(),
          ),

          // Pocket Mode Overlay
          const PocketModeOverlay(),
        ],
      ),
    ),
  );
}

  Widget _buildNavIcon(int index, String id) {
    final isSelected = _currentIndex == index;
    
    // Special case for 'account' profile image
    if (id == 'account') {
       return StreamBuilder<void>(
          stream: RepositoryProvider.of<UserPreferencesService>(context).dataStream,
          builder: (context, _) {
            final userPrefs = RepositoryProvider.of<UserPreferencesService>(context);
            final imagePath = userPrefs.getProfileImagePath();
            
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: imagePath != null 
                  ? Container(
                      key: ValueKey(imagePath),
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundImage: FileImage(File(imagePath)),
                        radius: 14,
                      ),
                    )
                  : Icon(
                      isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
              ),
              onPressed: () => _onNavTap(index),
            );
          }
        );
    }

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isSelected ? (_iconMap[id] ?? Icons.circle) : (_outlineIconMap[id] ?? Icons.circle_outlined),
          key: ValueKey<bool>(isSelected),
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      onPressed: () => _onNavTap(index),
    );
  }
}

class PocketModeOverlay extends StatefulWidget {
  const PocketModeOverlay({super.key});

  @override
  State<PocketModeOverlay> createState() => _PocketModeOverlayState();
}

class _PocketModeOverlayState extends State<PocketModeOverlay> {
  bool _isActive = false;
  StreamSubscription? _subscription;
  StreamSubscription? _prefSubscription;

  @override
  void initState() {
    super.initState();
    _initListener();
    // Listen to pref changes to enable/disable listener
    _prefSubscription = RepositoryProvider.of<UserPreferencesService>(context).dataStream.listen((_) {
      _initListener();
    });
  }

  void _initListener() {
    final prefs = RepositoryProvider.of<UserPreferencesService>(context);
    if (prefs.getPocketMode()) {
       if (_subscription == null) {
          _subscription = ProximitySensor.events.listen((int event) {
             final isNear = (event > 0); 
             if (_isActive != isNear) {
                if (mounted) {
                   setState(() {
                     _isActive = isNear;
                   });
                }
             }
          });
       }
    } else {
       _subscription?.cancel();
       _subscription = null;
       if (_isActive && mounted) setState(() => _isActive = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _prefSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.95),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Pocket Mode Active",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Touch controls are locked.\nUncover the sensor to unlock.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class PlaylistRefreshListener extends StatelessWidget {
  final Widget child;
  const PlaylistRefreshListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: RepositoryProvider.of<UserPreferencesService>(context).dataStream,
      builder: (context, snapshot) {
        // Debounce or just trigger? The stream emits on every save.
        // It might be too frequent, but let's try.
        // Actually, StreamBuilder rebuilds. We need to dispatch an event.
        // Better use BlocListener or just a custom Listener widget wrapper that calls context.read on data.
        return child;
      }
    );
  }
}
// Actually, I'll just put the listener in MainScreen's init or build.

