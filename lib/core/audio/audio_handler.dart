import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muses/features/library/models/song.dart';

class MusesAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  MusesAudioHandler(this._player) {
    _player.playbackEventStream.listen(_broadcastState);
    _player.positionStream.listen((_) => _broadcastState(_player.playbackEvent));
    _player.durationStream.listen((_) => _broadcastState(_player.playbackEvent));
    _player.processingStateStream.listen((_) => _broadcastState(_player.playbackEvent));
    _player.playingStream.listen((_) => _broadcastState(_player.playbackEvent));
  }

  void updateMetadata(Song? song, Duration? duration, [Uri? artUri]) {
    if (song == null) {
      mediaItem.add(null);
      return;
    }

    mediaItem.add(MediaItem(
      id: song.path,
      album: song.album ?? 'Unknown Album',
      title: song.title ?? 'Unknown Title',
      artist: song.artist ?? 'Unknown Artist',
      duration: duration,
      artUri: artUri,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();
  
  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }
}