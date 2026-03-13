import 'dart:developer' as developer;
import 'package:just_audio/just_audio.dart';
import 'package:muses/core/audio/audio_handler.dart';
import 'package:muses/core/utils/artwork_manager.dart';
import 'package:muses/features/library/models/song.dart';

class MusicPlayer {
  MusicPlayer(this._handler, this._audioPlayer) {
    _init();
  }

  final MusesAudioHandler _handler;
  final AudioPlayer _audioPlayer;
  ConcatenatingAudioSource? _playlist;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  
  PlayerState get playerState => _audioPlayer.playerState;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  Future<void> _init() async {
    // Listen for errors during playback.
    _audioPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      developer.log('A stream error occurred', error: e, stackTrace: stackTrace, name: 'MusicPlayer');
    });
  }

  Future<void> updateMetadata(Song? song, Duration? duration) async {
    Uri? artUri;
    if (song != null) {
      if (song.hasArtwork == true) {
        final file = await ArtworkManager().getArtworkFile(song.path);
        if (file != null) {
          artUri = Uri.file(file.path);
        }
      }
    }
    _handler.updateMetadata(song, duration, artUri);
  }

  Future<void> setQueue(List<Song> queue, {int initialIndex = 0, Duration? initialPosition, bool gapless = true}) async {
    try {
      _playlist = ConcatenatingAudioSource(
        useLazyPreparation: gapless,
        children: queue.map((s) => AudioSource.file(s.path)).toList(),
      );
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: initialIndex, initialPosition: initialPosition);
    } catch (e) {
      developer.log('Error setting queue', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> addNext(Song song) async {
    if (_playlist == null) return;
    try {
      final index = _audioPlayer.currentIndex ?? 0;
      await _playlist!.insert(index + 1, AudioSource.file(song.path));
    } catch (e) {
      developer.log('Error adding next', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> addToEnd(Song song) async {
    if (_playlist == null) return;
    try {
      await _playlist!.add(AudioSource.file(song.path));
    } catch (e) {
      developer.log('Error adding to end', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> moveItem(int oldIndex, int newIndex) async {
    if (_playlist == null) return;
    try {
      await _playlist!.move(oldIndex, newIndex);
    } catch (e) {
      developer.log('Error moving item', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> removeItem(int index) async {
    if (_playlist == null) return;
    try {
      await _playlist!.removeAt(index);
    } catch (e) {
      developer.log('Error removing item', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> insertItem(int index, Song song) async {
    if (_playlist == null) return;
    try {
      await _playlist!.insert(index, AudioSource.file(song.path));
    } catch (e) {
      developer.log('Error inserting item', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> play(String path) async {
    try {
      if (_audioPlayer.audioSource is UriAudioSource && 
          (_audioPlayer.audioSource as UriAudioSource).uri.toFilePath() == path) {
             if (!_audioPlayer.playing) {
                await _audioPlayer.play();
             }
             return;
      }
      
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
    } catch (e) {
      developer.log('Error loading audio source', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> playIndex(int index) async {
    try {
      if (_playlist != null && index >= 0 && index < _playlist!.length) {
        await _audioPlayer.seek(Duration.zero, index: index);
        await _audioPlayer.play();
      }
    } catch (e) {
      developer.log('Error playing index $index', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> setFilePath(String path) async {
    try {
      _playlist = null;
      await _audioPlayer.setFilePath(path);
    } catch (e) {
      developer.log('Error setting file path', error: e, name: 'MusicPlayer');
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position, {int? index}) async {
    await _audioPlayer.seek(position, index: index);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  Future<void> setShuffleMode(bool enabled) async {
    // We handle shuffle in PlayerBloc by updating the ConcatenatingAudioSource 
    // order for now to keep UI consistent, but just_audio's shuffle can also be used.
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }
  
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }
  
  Future<void> setEqualizerBands(List<double> gains) async {
    // Note: just_audio's built-in Equalizer is primarily for Android.
  }

  Future<void> setNormalization(bool enabled) async {
    // Normalization logic would go here.
  }
  
  Future<void> setGaplessPlayback(bool enabled) async {
    // Note: just_audio's ConcatenatingAudioSource is inherently gapless.
    // Toggling useLazyPreparation is a way to affect how it pre-buffers.
    if (_playlist != null) {
       // Unfortunately ConcatenatingAudioSource properties are final.
       // We'd need to recreate the source to change this, or handle it in setQueue.
    }
  }
  
  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}
