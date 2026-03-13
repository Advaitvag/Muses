part of 'player_bloc.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

class PlayerPlay extends PlayerEvent {
  const PlayerPlay(this.song, {this.queue});

  final Song song;
  final List<Song>? queue;

  @override
  List<Object> get props => [song, queue ?? []];
}

class PlayerPause extends PlayerEvent {}

class PlayerResume extends PlayerEvent {}

class PlayerSeek extends PlayerEvent {
  const PlayerSeek(this.position);

  final Duration position;

  @override
  List<Object> get props => [position];
}

class PlayerNext extends PlayerEvent {}

class PlayerPrevious extends PlayerEvent {}

class PlayerSetQueue extends PlayerEvent {
  const PlayerSetQueue(this.queue, {this.initialIndex = 0});

  final List<Song> queue;
  final int initialIndex;

  @override
  List<Object> get props => [queue, initialIndex];
}

class PlayerAddNext extends PlayerEvent {
  const PlayerAddNext(this.song);
  final Song song;
  @override
  List<Object> get props => [song];
}

class PlayerAddToEnd extends PlayerEvent {
  const PlayerAddToEnd(this.song);
  final Song song;
  @override
  List<Object> get props => [song];
}

class _PlayerStatusChanged extends PlayerEvent {
  const _PlayerStatusChanged(this.state);

  final ja.PlayerState state;

  @override
  List<Object> get props => [state];
}

class _PlayerPositionChanged extends PlayerEvent {
  const _PlayerPositionChanged(this.position);

  final Duration position;

  @override
  List<Object> get props => [position];
}

class _PlayerDurationChanged extends PlayerEvent {
  const _PlayerDurationChanged(this.duration);

  final Duration? duration;

  @override
  List<Object> get props => [duration ?? Duration.zero];
}

class _PlayerIndexChanged extends PlayerEvent {
  const _PlayerIndexChanged(this.index);
  final int? index;

  @override
  List<Object> get props => [index ?? -1];
}

class PlayerToggleShuffle extends PlayerEvent {}

class PlayerToggleRepeat extends PlayerEvent {}

class PlayerSongFinished extends PlayerEvent {}

class PlayerQueueEntered extends PlayerEvent {}

class PlayerMoveQueueItem extends PlayerEvent {
  const PlayerMoveQueueItem({required this.oldIndex, required this.newIndex});

  final int oldIndex;
  final int newIndex;

  @override
  List<Object> get props => [oldIndex, newIndex];
}

class PlayerRemoveFromQueue extends PlayerEvent {
  const PlayerRemoveFromQueue(this.index);
  final int index;
  @override
  List<Object> get props => [index];
}

class PlayerDuplicateInQueue extends PlayerEvent {
  const PlayerDuplicateInQueue(this.index);
  final int index;
  @override
  List<Object> get props => [index];
}

class PlayerPlayNext extends PlayerEvent {
  const PlayerPlayNext(this.index);
  final int index;
  @override
  List<Object> get props => [index];
}

class _PlayerRestoreQueue extends PlayerEvent {}

class _PlayerSyncWithLibrary extends PlayerEvent {
  const _PlayerSyncWithLibrary(this.librarySongs);
  final List<Song> librarySongs;

  @override
  List<Object> get props => [librarySongs];
}
