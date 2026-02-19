import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class UpdateMediaItem extends PlayerEvent {
  final MediaItem? item;
  const UpdateMediaItem(this.item);
  @override
  List<Object?> get props => [item];
}

class UpdatePlaybackState extends PlayerEvent {
  final PlaybackState state;
  const UpdatePlaybackState(this.state);
  @override
  List<Object?> get props => [state];
}

class UpdateQueue extends PlayerEvent {
  final List<MediaItem> queue;
  const UpdateQueue(this.queue);
  @override
  List<Object?> get props => [queue];
}

class PlaySong extends PlayerEvent {
  final List<SongModel> playlist;
  final int index;
  const PlaySong(this.playlist, this.index);
  @override
  List<Object?> get props => [playlist, index];
}

class PausePlayer extends PlayerEvent {}
class ResumePlayer extends PlayerEvent {}
class NextSong extends PlayerEvent {}
class PreviousSong extends PlayerEvent {}

class SeekPosition extends PlayerEvent {
  final Duration position;
  const SeekPosition(this.position);
  @override
  List<Object?> get props => [position];
}

class SkipToQueueItem extends PlayerEvent {
  final int index;
  const SkipToQueueItem(this.index);
  @override
  List<Object?> get props => [index];
}

class ClearQueue extends PlayerEvent {}

class ToggleFavorite extends PlayerEvent {
  final String songId;
  const ToggleFavorite(this.songId);
  @override
  List<Object?> get props => [songId];
}

class AddToQueue extends PlayerEvent {
  final SongModel song;
  const AddToQueue(this.song);
  @override
  List<Object?> get props => [song];
}

class RemoveFromQueue extends PlayerEvent {
  final int index;
  const RemoveFromQueue(this.index);
  @override
  List<Object?> get props => [index];
}

class PlayNextEvent extends PlayerEvent {
  final SongModel song;
  const PlayNextEvent(this.song);
  @override
  List<Object?> get props => [song];
}

class SetSleepTimer extends PlayerEvent {
  final Duration? duration;
  const SetSleepTimer(this.duration);
  @override
  List<Object?> get props => [duration];
}

class ClearSleepTimer extends PlayerEvent {}



class SetLoopMode extends PlayerEvent {
  final AudioServiceRepeatMode mode;
  const SetLoopMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

class SetSpeed extends PlayerEvent {
  final double speed;
  const SetSpeed(this.speed);
  @override
  List<Object?> get props => [speed];
}

class SetPitch extends PlayerEvent {
  final double pitch;
  const SetPitch(this.pitch);
  @override
  List<Object?> get props => [pitch];
}

class SetVolume extends PlayerEvent {
  final double volume;
  const SetVolume(this.volume);
  @override
  List<Object?> get props => [volume];
}

class ReorderQueueItem extends PlayerEvent {
  final int oldIndex;
  final int newIndex;
  final String? newSource;

  const ReorderQueueItem(this.oldIndex, this.newIndex, {this.newSource});

  @override
  List<Object> get props => [oldIndex, newIndex, newSource ?? ''];
}
