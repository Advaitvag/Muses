part of 'player_bloc.dart';

enum PlayerStatus { initial, loading, playing, paused, completed, error }

class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.initial,
    this.queue = const [],
    this.shuffledIndices = const [],
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffleMode = false,
    this.repeatMode = ja.LoopMode.off,
    this.queueScrollId = 0,
  });

  final PlayerStatus status;
  final List<Song> queue;
  final List<int> shuffledIndices;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool shuffleMode;
  final ja.LoopMode repeatMode;
  final int queueScrollId;

  List<Song> get effectiveQueue {
    if (shuffleMode && shuffledIndices.isNotEmpty) {
      return shuffledIndices
          .map((i) => i < queue.length ? queue[i] : null)
          .whereType<Song>()
          .toList();
    }
    return queue;
  }

  Song? get currentSong =>
      effectiveQueue.isNotEmpty && currentIndex < effectiveQueue.length
          ? effectiveQueue[currentIndex]
          : null;

  bool get hasPrevious => currentIndex > 0 || repeatMode == ja.LoopMode.all;
  bool get hasNext =>
      currentIndex < effectiveQueue.length - 1 ||
      repeatMode == ja.LoopMode.all;

  PlayerState copyWith({
    PlayerStatus? status,
    List<Song>? queue,
    List<int>? shuffledIndices,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? shuffleMode,
    ja.LoopMode? repeatMode,
    int? queueScrollId,
  }) {
    return PlayerState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      queueScrollId: queueScrollId ?? this.queueScrollId,
    );
  }

  @override
  List<Object> get props => [
        status,
        queue,
        shuffledIndices,
        currentIndex,
        position,
        duration,
        shuffleMode,
        repeatMode,
        queueScrollId,
      ];
}
