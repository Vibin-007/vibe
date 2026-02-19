import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/audio_query_service.dart';
import 'songs_event.dart';
import 'songs_state.dart';

import '../../../core/services/user_preferences_service.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  final AudioQueryService _audioQueryService;
  final UserPreferencesService _prefs;

  SongsBloc(this._audioQueryService, this._prefs) : super(SongsInitial()) {
    on<LoadSongs>(_onLoadSongs);
    on<RequestPermission>(_onRequestPermission);
  }

  Future<void> _onLoadSongs(LoadSongs event, Emitter<SongsState> emit) async {
    emit(SongsLoading());
    try {
      final hasPermission = await _audioQueryService.checkAndRequestPermissions();
      if (hasPermission) {
        var songs = await _audioQueryService.getSongs();
        var albums = await _audioQueryService.getAlbums();
        
        // Apply Blacklist Filters
        final minDuration = _prefs.getBlacklistMinDuration();
        final excluded = _prefs.getExcludedFolders();

        songs = songs.where((s) {
          // Duration Filter (ms)
          // Note: duration is in ms
          if ((s.duration ?? 0) < minDuration * 1000) return false;

          // Folder Filter
          final path = s.data;
          
          if (_prefs.getIncludedFolders().isNotEmpty) {
             return _prefs.getIncludedFolders().any((folder) => path.startsWith(folder));
          }

          if (excluded.isNotEmpty) {
             if (excluded.any((folder) => path.startsWith(folder))) return false;
          }
          
          return true;
        }).toList();

        emit(SongsLoaded(songs, albums: albums));
      } else {
        emit(PermissionDenied());
      }
    } catch (e) {
      emit(SongsError(e.toString()));
    }
  }

  Future<void> _onRequestPermission(RequestPermission event, Emitter<SongsState> emit) async {
    final hasPermission = await _audioQueryService.checkAndRequestPermissions(retry: true);
    if (hasPermission) {
      add(LoadSongs());
    } else {
      emit(PermissionDenied());
    }
  }
}
