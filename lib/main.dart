import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/services/audio_handler.dart';
import 'core/services/audio_query_service.dart';
import 'core/services/user_preferences_service.dart';
import 'core/services/bluetooth_auto_play_service.dart';
import 'features/main_navigation/presentation/main_screen.dart';
import 'features/songs/bloc/songs_bloc.dart';
import 'features/songs/bloc/songs_event.dart';
import 'features/songs/bloc/player_bloc.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'core/bloc/theme_bloc.dart';
import 'features/playlist/bloc/playlist_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final sharedPrefs = await SharedPreferences.getInstance();
  final userPrefs = UserPreferencesService(sharedPrefs);
  final audioQueryService = AudioQueryService();
  final audioHandler = await initAudioService(userPrefs);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SongsBloc(audioQueryService, userPrefs)..add(LoadSongs()),
        ),
        BlocProvider(
          create: (context) => PlayerBloc(audioHandler as MyAudioHandler, userPrefs),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(userPrefs)..add(LoadTheme()),
        ),
        BlocProvider(
          create: (context) => PlaylistBloc(userPrefs)..add(LoadPlaylists()),
        ),
        RepositoryProvider.value(value: userPrefs),
      ],

      child: const MusicWorldApp(),
    ),
  );
}

class MusicWorldApp extends StatefulWidget {
  const MusicWorldApp({super.key});

  @override
  State<MusicWorldApp> createState() => _MusicWorldAppState();
}

class _MusicWorldAppState extends State<MusicWorldApp> {
  bool _showSplash = true;
  BluetoothAutoPlayService? _btService;

  @override
  void initState() {
    super.initState();
    // Defer initialization to allow context access after build or use a post-frame callback if strict context needed,
    // but Bloc access in initState requires read, which is safe if provider is parent.
    // However, context.read in initState is unstable for provided values sometimes if they aren't ready?
    // Actually, Provider rules say read is fine in initState (listen false).
    // EXCEPT: inherited widgets aren't linked yet in initState context?
    // Let's use addPostFrameCallback to be safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userPrefs = RepositoryProvider.of<UserPreferencesService>(context);
      final playerBloc = context.read<PlayerBloc>();
      _btService = BluetoothAutoPlayService(userPrefs, playerBloc);
      _btService!.init();
    });
  }

  @override
  void dispose() {
    _btService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = RepositoryProvider.of<UserPreferencesService>(context);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Vibe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(state.accentColor),
          darkTheme: AppTheme.darkTheme(state.accentColor),
          themeMode: state.themeMode,
          home: _showSplash
              ? SplashScreen(onComplete: () => setState(() => _showSplash = false))
              : !userPrefs.isOnboardingComplete()
                  ? OnboardingScreen(onComplete: (name) async {
                      await userPrefs.setUserName(name);
                      await userPrefs.setOnboardingComplete(true);
                      setState(() {});
                    })
                  : const MainScreen(),
        );
      },
    );
  }
}
