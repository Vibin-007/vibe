import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/services/user_preferences_service.dart';

// Events
abstract class PlaylistEvent {}
class LoadPlaylists extends PlaylistEvent {}
class CreatePlaylist extends PlaylistEvent {
  final String name;
  CreatePlaylist(this.name);
}
class AddToPlaylist extends PlaylistEvent {
  final String playlistName;
  final SongModel song;
  AddToPlaylist(this.playlistName, this.song);
}
class RemoveFromPlaylist extends PlaylistEvent {
  final String playlistName;
  final int songId;
  RemoveFromPlaylist(this.playlistName, this.songId);
}
class DeletePlaylist extends PlaylistEvent {
  final String name;
  DeletePlaylist(this.name);
}

// State
class PlaylistState {
  final Map<String, List<String>> playlists; // Map name to list of IDs
  final bool isLoading;

  PlaylistState({this.playlists = const {}, this.isLoading = false});

  PlaylistState copyWith({Map<String, List<String>>? playlists, bool? isLoading}) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Bloc
class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final UserPreferencesService _prefs;

  PlaylistBloc(this._prefs) : super(PlaylistState()) {
    on<LoadPlaylists>((event, emit) {
      emit(state.copyWith(isLoading: true));
      final data = _prefs.getPlaylists();
      // Handle the fact that getPlaylists() currently returns empty map as placeholder
      // and we need to parse the real JSON from SharedPreferences
      final raw = _prefs.getPlaylistsRaw(); 
      Map<String, List<String>> parsed = {};
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        parsed = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      }

      // Inject Smart Playlists
      // parsed['Recently Played'] = _prefs.getRecentlyPlayed();
      
      final playCounts = _prefs.getPlayCounts();
      if (playCounts.isNotEmpty) {
        final sorted = playCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        parsed['Most Played'] = sorted.take(50).map((e) => e.key).toList();
      }

      emit(state.copyWith(playlists: parsed, isLoading: false));
    });

    on<CreatePlaylist>((event, emit) async {
      final updated = Map<String, List<String>>.from(state.playlists);
      if (!updated.containsKey(event.name)) {
        updated[event.name] = [];
        await _save(updated);
        emit(state.copyWith(playlists: updated));
      }
    });

    on<AddToPlaylist>((event, emit) async {
      final updated = Map<String, List<String>>.from(state.playlists);
      if (updated.containsKey(event.playlistName)) {
        final list = List<String>.from(updated[event.playlistName]!);
        if (!list.contains(event.song.id.toString())) {
          list.add(event.song.id.toString());
          updated[event.playlistName] = list;
          await _save(updated);
          emit(state.copyWith(playlists: updated));
        }
      }
    });

    on<RemoveFromPlaylist>((event, emit) async {
      final updated = Map<String, List<String>>.from(state.playlists);
      if (updated.containsKey(event.playlistName)) {
        final list = List<String>.from(updated[event.playlistName]!);
        list.remove(event.songId.toString());
        updated[event.playlistName] = list;
        await _save(updated);
        emit(state.copyWith(playlists: updated));
      }
    });

    on<DeletePlaylist>((event, emit) async {
      final updated = Map<String, List<String>>.from(state.playlists);
      updated.remove(event.name);
      await _save(updated);
      emit(state.copyWith(playlists: updated));
    });
  }

  Future<void> _save(Map<String, List<String>> playlists) async {
    await _prefs.savePlaylists(jsonEncode(playlists));
  }
}
