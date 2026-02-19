import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract class SongsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSongs extends SongsEvent {}

class RequestPermission extends SongsEvent {}
