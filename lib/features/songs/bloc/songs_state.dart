import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract class SongsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SongsInitial extends SongsState {}

class SongsLoading extends SongsState {}

class SongsLoaded extends SongsState {
  final List<SongModel> songs;
  final List<AlbumModel> albums;

  SongsLoaded(this.songs, {this.albums = const []});

  @override
  List<Object?> get props => [songs, albums];
}

class SongsError extends SongsState {
  final String message;
  SongsError(this.message);

  @override
  List<Object?> get props => [message];
}

class PermissionDenied extends SongsState {}
