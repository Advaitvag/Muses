import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:metadata_god/metadata_god.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/player/services/music_player.dart';
import 'package:muses/features/settings/bloc/audio_settings_bloc.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends HydratedBloc<PlayerEvent, PlayerState> {
  PlayerBloc({
    required MusicPlayer musicPlayer,
    required LibraryBloc libraryBloc,
    required AudioSettingsBloc audioSettingsBloc,
  })  : _musicPlayer = musicPlayer,
        _libraryBloc = libraryBloc,
        _audioSettingsBloc = audioSettingsBloc,
        super(const PlayerState()) {
    on<PlayerPlay>(_onPlay);
    on<PlayerPause>(_onPause);
    on<PlayerResume>(_onResume);
    on<PlayerSeek>(_onSeek);
    on<PlayerNext>(_onNext);
    on<PlayerPrevious>(_onPrevious);
    on<PlayerSetQueue>(_onSetQueue);
    on<PlayerAddNext>(_onAddNext);
    on<PlayerAddToEnd>(_onAddToEnd);
    on<_PlayerStatusChanged>(_onStatusChanged);
    on<_PlayerPositionChanged>(_onPositionChanged);
    on<_PlayerDurationChanged>(_onDurationChanged);
    on<_PlayerIndexChanged>(_onIndexChanged);
    on<PlayerToggleShuffle>(_onToggleShuffle);
    on<PlayerToggleRepeat>(_onToggleRepeat);
    on<PlayerSongFinished>(_onSongFinished);
    on<PlayerQueueEntered>(_onQueueEntered);
    on<PlayerMoveQueueItem>(_onMoveQueueItem);
    on<PlayerRemoveFromQueue>(_onRemoveFromQueue);
    on<PlayerDuplicateInQueue>(_onDuplicateInQueue);
    on<PlayerPlayNext>(_onPlayNext);
    on<_PlayerRestoreQueue>(_onRestoreQueue);
    on<_PlayerSyncWithLibrary>(_onSyncWithLibrary);

    _playerStateSubscription = _musicPlayer.playerStateStream.listen((state) {
      add(_PlayerStatusChanged(state));
    });
    _positionSubscription = _musicPlayer.positionStream.listen((position) {
      add(_PlayerPositionChanged(position));
    });
    _durationSubscription = _musicPlayer.durationStream.listen((duration) {
      add(_PlayerDurationChanged(duration));
    });
    _indexSubscription = _musicPlayer.currentIndexStream.listen((index) {
      add(_PlayerIndexChanged(index));
    });

    _librarySubscription = _libraryBloc.stream.listen((libraryState) {
      if (libraryState is LibraryLoaded) {
        add(_PlayerSyncWithLibrary(libraryState.songs));
      }
    });

    stream.listen((state) {
      _musicPlayer.updateMetadata(state.currentSong, state.duration);
    });

    if (state.queue.isNotEmpty) {
      add(_PlayerRestoreQueue());
    }
  }

  final MusicPlayer _musicPlayer;
  final LibraryBloc _libraryBloc;
  final AudioSettingsBloc _audioSettingsBloc;
  late final StreamSubscription _playerStateSubscription;
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _durationSubscription;
  late final StreamSubscription _indexSubscription;
  late final StreamSubscription _librarySubscription;

  Future<void> _onRestoreQueue(
    _PlayerRestoreQueue event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.queue.isEmpty) return;

    final List<Song> restoredQueue = [];
    final libraryState = _libraryBloc.state;
    final librarySongs =
        libraryState is LibraryLoaded ? libraryState.songs : <Song>[];
    final libraryMap = {for (var s in librarySongs) s.path: s};

    // Use a local copy of the queue to avoid issues if it changes while we are restoring
    final queueToRestore = List<Song>.from(state.queue);

    for (final song in queueToRestore) {
      final librarySong = libraryMap[song.path];
      if (librarySong != null && librarySong.hasArtwork != null) {
        restoredQueue.add(librarySong);
      } else {
        try {
          final metadata = await MetadataGod.readMetadata(file: song.path);
          restoredQueue.add(
            Song(
              path: song.path,
              title: metadata.title ?? librarySong?.title ?? song.title,
              artist: metadata.artist ?? librarySong?.artist ?? song.artist,
              album: metadata.album ?? librarySong?.album ?? song.album,
              artwork: null,
              hasArtwork: metadata.picture != null,
              trackNumber: metadata.trackNumber,
              discNumber: metadata.discNumber,
            ),
          );
        } catch (_) {
          restoredQueue.add(librarySong ?? song);
        }
      }
    }

    // Check if the queue has changed while we were restoring metadata
    if (state.queue.length == queueToRestore.length) {
      emit(state.copyWith(queue: restoredQueue));
    } else {
      final currentQueue = List<Song>.from(state.queue);
      final Map<String, Song> restoredMap = {
        for (var s in restoredQueue) s.path: s
      };

      final updatedQueue = currentQueue.map((song) {
        return restoredMap[song.path] ?? song;
      }).toList();

      emit(state.copyWith(queue: updatedQueue));
    }

    final currentSong = state.currentSong;
    if (currentSong != null) {
      try {
        final effectiveQueue = state.effectiveQueue;
        final index = effectiveQueue.indexOf(currentSong);
        await _musicPlayer.setQueue(
          effectiveQueue, 
          initialIndex: index != -1 ? index : 0,
          gapless: _audioSettingsBloc.state.gaplessPlayback,
        );
        
        if (state.position != Duration.zero) {
          await _musicPlayer.seek(state.position);
        }
        await _musicPlayer.setLoopMode(state.repeatMode);
        await _musicPlayer.setShuffleMode(state.shuffleMode);
      } catch (e) {
        developer.log('Error restoring player state', error: e, name: 'PlayerBloc');
      }
    }
  }

  void _onSyncWithLibrary(
    _PlayerSyncWithLibrary event,
    Emitter<PlayerState> emit,
  ) {
    if (state.queue.isEmpty) return;

    final libraryMap = {for (var s in event.librarySongs) s.path: s};
    bool changed = false;

    final updatedQueue = state.queue.map((song) {
      final librarySong = libraryMap[song.path];
      if (librarySong != null && librarySong != song) {
        changed = true;
        return librarySong;
      }
      return song;
    }).toList();

    if (changed) {
      emit(state.copyWith(queue: updatedQueue));
    }
  }

  Future<void> _onPlay(PlayerPlay event, Emitter<PlayerState> emit) async {
    final bool isExistingQueue = event.queue == null;
    List<Song> queue = event.queue ?? state.queue;

    if (isExistingQueue && !queue.contains(event.song)) {
      queue = [event.song];
    }

    if (state.shuffleMode) {
      if (isExistingQueue && state.shuffledIndices.isNotEmpty) {
        final effectiveQueue = state.effectiveQueue;
        final index = effectiveQueue.indexOf(event.song);
        if (index != -1) {
          emit(state.copyWith(
            currentIndex: index,
            status: PlayerStatus.loading,
          ));
          await _musicPlayer.playIndex(index);
          return;
        }
      }

      int originalIndex = queue.indexOf(event.song);
      if (originalIndex == -1) originalIndex = 0;

      final shuffledIndices = List.generate(queue.length, (i) => i)
        ..shuffle(Random());
      shuffledIndices.remove(originalIndex);
      shuffledIndices.insert(0, originalIndex);

      final newState = state.copyWith(
        queue: queue,
        shuffledIndices: shuffledIndices,
        currentIndex: 0,
        status: PlayerStatus.loading,
      );
      emit(newState);

      await _musicPlayer.setQueue(
        newState.effectiveQueue, 
        initialIndex: 0,
        gapless: _audioSettingsBloc.state.gaplessPlayback,
      );
      await _musicPlayer.resume();
    } else {
      int index = queue.indexOf(event.song);
      if (index == -1) index = 0;

      final newState = state.copyWith(
        queue: queue,
        shuffledIndices: [],
        currentIndex: index,
        status: PlayerStatus.loading,
      );
      emit(newState);

      await _musicPlayer.setQueue(
        newState.effectiveQueue, 
        initialIndex: index,
        gapless: _audioSettingsBloc.state.gaplessPlayback,
      );
      await _musicPlayer.resume();
    }
  }

  Future<void> _onPause(PlayerPause event, Emitter<PlayerState> emit) async {
    await _musicPlayer.pause();
  }

  Future<void> _onResume(PlayerResume event, Emitter<PlayerState> emit) async {
    await _musicPlayer.resume();
  }

  Future<void> _onSeek(PlayerSeek event, Emitter<PlayerState> emit) async {
    await _musicPlayer.seek(event.position);
  }

  Future<void> _onNext(PlayerNext event, Emitter<PlayerState> emit) async {
    if (state.effectiveQueue.isEmpty) return;

    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.effectiveQueue.length) {
      if (state.repeatMode == ja.LoopMode.all) {
        nextIndex = 0;
      } else {
        return; // End of queue
      }
    }

    emit(state.copyWith(currentIndex: nextIndex, status: PlayerStatus.loading));
    await _musicPlayer.playIndex(nextIndex);
  }

  Future<void> _onPrevious(
      PlayerPrevious event, Emitter<PlayerState> emit) async {
    if (state.effectiveQueue.isEmpty) return;

    if (state.position.inSeconds > 3) {
      await _musicPlayer.seek(Duration.zero);
      return;
    }

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == ja.LoopMode.all) {
        prevIndex = state.effectiveQueue.length - 1;
      } else {
        prevIndex = 0;
        await _musicPlayer.seek(Duration.zero);
        return;
      }
    }

    emit(state.copyWith(currentIndex: prevIndex, status: PlayerStatus.loading));
    await _musicPlayer.playIndex(prevIndex);
  }

  void _onSetQueue(PlayerSetQueue event, Emitter<PlayerState> emit) {
    List<int> shuffledIndices = [];
    int currentIndex = event.initialIndex;

    if (state.shuffleMode) {
      shuffledIndices = List.generate(event.queue.length, (i) => i)
        ..shuffle(Random());
      shuffledIndices.remove(event.initialIndex);
      shuffledIndices.insert(0, event.initialIndex);
      currentIndex = 0;
    }

    final newState = state.copyWith(
      queue: event.queue,
      shuffledIndices: shuffledIndices,
      currentIndex: currentIndex,
    );
    emit(newState);
    _musicPlayer.setQueue(
      newState.effectiveQueue, 
      initialIndex: currentIndex,
      gapless: _audioSettingsBloc.state.gaplessPlayback,
    );
  }

  void _onAddNext(PlayerAddNext event, Emitter<PlayerState> emit) {
    final newQueue = List<Song>.from(state.queue);
    
    if (newQueue.isEmpty) {
      _playSong(event.song, [event.song], emit);
      return;
    }

    newQueue.add(event.song);
    final int newSongOriginalIndex = newQueue.length - 1;

    PlayerState newState;
    if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
      final newShuffledIndices = List<int>.from(state.shuffledIndices);
      newShuffledIndices.insert(state.currentIndex + 1, newSongOriginalIndex);
      newState = state.copyWith(
        queue: newQueue,
        shuffledIndices: newShuffledIndices,
      );
    } else {
      final nextIndex = state.currentIndex + 1;
      newQueue.removeAt(newSongOriginalIndex);
      newQueue.insert(nextIndex, event.song);
      newState = state.copyWith(queue: newQueue);
    }
    emit(newState);
    _musicPlayer.addNext(event.song);
  }

  void _onAddToEnd(PlayerAddToEnd event, Emitter<PlayerState> emit) {
    final newQueue = List<Song>.from(state.queue);
    
    if (newQueue.isEmpty) {
      _playSong(event.song, [event.song], emit);
      return;
    }

    newQueue.add(event.song);

    PlayerState newState;
    if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
      final newShuffledIndices = List<int>.from(state.shuffledIndices);
      newShuffledIndices.add(newQueue.length - 1);
      newState = state.copyWith(
        queue: newQueue,
        shuffledIndices: newShuffledIndices,
      );
    } else {
      newState = state.copyWith(queue: newQueue);
    }
    emit(newState);
    _musicPlayer.addToEnd(event.song);
  }

  Future<void> _playSong(Song song, List<Song> queue, Emitter<PlayerState> emit) async {
    PlayerState newState;
    if (state.shuffleMode) {
      final shuffledIndices = List.generate(queue.length, (i) => i)
        ..shuffle(Random());
      
      final originalIndex = queue.indexOf(song);
      if (originalIndex != -1) {
        shuffledIndices.remove(originalIndex);
        shuffledIndices.insert(0, originalIndex);
      }

      newState = state.copyWith(
        queue: queue,
        shuffledIndices: shuffledIndices,
        currentIndex: 0,
        status: PlayerStatus.loading,
      );
    } else {
      final index = queue.indexOf(song);
      newState = state.copyWith(
        queue: queue,
        shuffledIndices: [],
        currentIndex: index != -1 ? index : 0,
        status: PlayerStatus.loading,
      );
    }
    emit(newState);
    await _musicPlayer.setQueue(
      newState.effectiveQueue, 
      initialIndex: newState.currentIndex,
      gapless: _audioSettingsBloc.state.gaplessPlayback,
    );
    await _musicPlayer.resume();
  }

  void _onStatusChanged(_PlayerStatusChanged event, Emitter<PlayerState> emit) {
    PlayerStatus status = PlayerStatus.initial;
    switch (event.state.processingState) {
      case ja.ProcessingState.idle:
        status = PlayerStatus.initial;
        break;
      case ja.ProcessingState.loading:
      case ja.ProcessingState.buffering:
        status = PlayerStatus.loading;
        break;
      case ja.ProcessingState.ready:
        status = event.state.playing ? PlayerStatus.playing : PlayerStatus.paused;
        break;
      case ja.ProcessingState.completed:
        status = PlayerStatus.completed;
        break;
    }
    emit(state.copyWith(status: status));
  }

  void _onPositionChanged(_PlayerPositionChanged event, Emitter<PlayerState> emit) {
    emit(state.copyWith(position: event.position));
  }

  void _onDurationChanged(_PlayerDurationChanged event, Emitter<PlayerState> emit) {
    emit(state.copyWith(duration: event.duration));
  }

  void _onIndexChanged(_PlayerIndexChanged event, Emitter<PlayerState> emit) {
    if (event.index != null && event.index != state.currentIndex) {
      emit(state.copyWith(currentIndex: event.index));
    }
  }

  Future<void> _onToggleShuffle(PlayerToggleShuffle event, Emitter<PlayerState> emit) async {
    final newShuffleMode = !state.shuffleMode;
    // Note: We currently keep our custom shuffle logic for state persistence,
    // but toggling it WILL restart playback because we call setQueue.
    // TODO: Improve this to use just_audio's native shuffle without restart.
    await _musicPlayer.setShuffleMode(newShuffleMode);
    
    PlayerState newState;
    if (newShuffleMode) {
      if (state.queue.isEmpty) {
         emit(state.copyWith(shuffleMode: true));
         return;
      }
      
      final currentSong = state.currentSong;
      final indices = List.generate(state.queue.length, (i) => i)..shuffle(Random());
      
      if (currentSong != null) {
        final originalIndex = state.queue.indexOf(currentSong);
        if (originalIndex != -1) {
          indices.remove(originalIndex);
          indices.insert(0, originalIndex);
        }
      }
      
      newState = state.copyWith(
        shuffleMode: true,
        shuffledIndices: indices,
        currentIndex: 0,
      );
    } else {
      int newIndex = state.currentIndex;
      if (state.shuffledIndices.isNotEmpty && state.currentIndex < state.shuffledIndices.length) {
        newIndex = state.shuffledIndices[state.currentIndex];
      }
      newState = state.copyWith(
        shuffleMode: false,
        shuffledIndices: [],
        currentIndex: newIndex,
      );
    }
    final currentPosition = state.position;
    emit(newState);
    await _musicPlayer.setQueue(
      newState.effectiveQueue, 
      initialIndex: newState.currentIndex,
      initialPosition: currentPosition,
      gapless: _audioSettingsBloc.state.gaplessPlayback,
    );
  }

  Future<void> _onToggleRepeat(PlayerToggleRepeat event, Emitter<PlayerState> emit) async {
    final modes = [ja.LoopMode.off, ja.LoopMode.all, ja.LoopMode.one];
    final nextIndex = (modes.indexOf(state.repeatMode) + 1) % modes.length;
    final newMode = modes[nextIndex];
    await _musicPlayer.setLoopMode(newMode);
    emit(state.copyWith(repeatMode: newMode));
  }

  Future<void> _onSongFinished(PlayerSongFinished event, Emitter<PlayerState> emit) async {
  }

  void _onQueueEntered(PlayerQueueEntered event, Emitter<PlayerState> emit) {
    emit(state.copyWith(queueScrollId: state.queueScrollId + 1));
  }

  void _onMoveQueueItem(PlayerMoveQueueItem event, Emitter<PlayerState> emit) {
    if (event.oldIndex == event.newIndex) return;
    if (event.oldIndex < 0 || event.oldIndex >= state.effectiveQueue.length) return;
    if (event.newIndex < 0 || event.newIndex >= state.effectiveQueue.length) return;

    final currentSong = state.currentSong;

    PlayerState newState;
    if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
      final newShuffledIndices = List<int>.from(state.shuffledIndices);
      final item = newShuffledIndices.removeAt(event.oldIndex);
      newShuffledIndices.insert(event.newIndex, item);
      
      int newCurrentIndex = state.currentIndex;
      if (currentSong != null) {
        final newEffectiveQueue = newShuffledIndices.map((i) => state.queue[i]).toList();
        newCurrentIndex = newEffectiveQueue.indexOf(currentSong);
      }

      newState = state.copyWith(
        shuffledIndices: newShuffledIndices,
        currentIndex: newCurrentIndex,
      );
    } else {
      final newQueue = List<Song>.from(state.queue);
      final item = newQueue.removeAt(event.oldIndex);
      newQueue.insert(event.newIndex, item);

      int newCurrentIndex = state.currentIndex;
      if (currentSong != null) {
        newCurrentIndex = newQueue.indexOf(currentSong);
      }

      newState = state.copyWith(
        queue: newQueue,
        currentIndex: newCurrentIndex,
      );
    }
    emit(newState);
    _musicPlayer.moveItem(event.oldIndex, event.newIndex);
  }

  void _onRemoveFromQueue(PlayerRemoveFromQueue event, Emitter<PlayerState> emit) {
    if (event.index < 0 || event.index >= state.effectiveQueue.length) return;

    PlayerState newState;
    if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
      final newShuffledIndices = List<int>.from(state.shuffledIndices);
      final removedOriginalIndex = newShuffledIndices.removeAt(event.index);
      
      final newQueue = List<Song>.from(state.queue);
      newQueue.removeAt(removedOriginalIndex);
      
      final updatedShuffledIndices = newShuffledIndices.map((idx) => idx > removedOriginalIndex ? idx - 1 : idx).toList();

      int newCurrentIndex = state.currentIndex;
      if (event.index < state.currentIndex) {
        newCurrentIndex--;
      } else if (event.index == state.currentIndex) {
        if (newCurrentIndex >= updatedShuffledIndices.length) {
          newCurrentIndex = max(0, updatedShuffledIndices.length - 1);
        }
      }

      newState = state.copyWith(
        queue: newQueue,
        shuffledIndices: updatedShuffledIndices,
        currentIndex: newCurrentIndex,
      );
    } else {
      final newQueue = List<Song>.from(state.queue);
      newQueue.removeAt(event.index);

      int newCurrentIndex = state.currentIndex;
      if (event.index < state.currentIndex) {
        newCurrentIndex--;
      } else if (event.index == state.currentIndex) {
        if (newCurrentIndex >= newQueue.length) {
          newCurrentIndex = max(0, newQueue.length - 1);
        }
      }

      newState = state.copyWith(
        queue: newQueue,
        currentIndex: newCurrentIndex,
      );
    }
    emit(newState);
    _musicPlayer.removeItem(event.index);
  }

  void _onDuplicateInQueue(PlayerDuplicateInQueue event, Emitter<PlayerState> emit) {
    if (event.index < 0 || event.index >= state.effectiveQueue.length) return;

    final songToDuplicate = state.effectiveQueue[event.index];
    final targetIndex = event.index + 1;
    
    PlayerState newState;
    if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
      final newQueue = List<Song>.from(state.queue);
      newQueue.add(songToDuplicate);
      final newOriginalIndex = newQueue.length - 1;

      final newShuffledIndices = List<int>.from(state.shuffledIndices);
      newShuffledIndices.insert(targetIndex, newOriginalIndex);

      int newCurrentIndex = state.currentIndex;
      if (event.index < state.currentIndex) {
        newCurrentIndex++;
      }

      newState = state.copyWith(
        queue: newQueue,
        shuffledIndices: newShuffledIndices,
        currentIndex: newCurrentIndex,
      );
    } else {
      final newQueue = List<Song>.from(state.queue);
      newQueue.insert(targetIndex, songToDuplicate);

      int newCurrentIndex = state.currentIndex;
      if (event.index < state.currentIndex) {
        newCurrentIndex++;
      }

      newState = state.copyWith(
        queue: newQueue,
        currentIndex: newCurrentIndex,
      );
    }
    emit(newState);
    _musicPlayer.insertItem(targetIndex, songToDuplicate);
  }

  void _onPlayNext(PlayerPlayNext event, Emitter<PlayerState> emit) {
    if (event.index < 0 || event.index >= state.effectiveQueue.length) return;
    if (event.index == state.currentIndex + 1) return; // Already next

    final targetIndex = state.currentIndex + 1;
    if (targetIndex >= state.effectiveQueue.length) {
      // If current is last, just move the item to the end
      add(PlayerMoveQueueItem(oldIndex: event.index, newIndex: state.effectiveQueue.length - 1));
    } else {
      add(PlayerMoveQueueItem(oldIndex: event.index, newIndex: targetIndex));
    }
  }

  @override
  Future<void> close() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _indexSubscription.cancel();
    _librarySubscription.cancel();
    _musicPlayer.dispose();
    return super.close();
  }

  @override
  PlayerState? fromJson(Map<String, dynamic> json) {
    try {
      final queuePaths = (json['queue'] as List?)?.cast<String>() ?? [];
      final queue = queuePaths.map((path) => Song(path: path)).toList();
      final shuffledIndices =
          (json['shuffledIndices'] as List?)?.cast<int>() ?? [];

      return PlayerState(
        queue: queue,
        shuffledIndices: shuffledIndices,
        currentIndex: json['currentIndex'] as int? ?? 0,
        shuffleMode: json['shuffleMode'] as bool? ?? false,
        repeatMode: ja.LoopMode.values[json['repeatMode'] as int? ?? 0],
        position: Duration(
            milliseconds: (json['position'] as num? ?? 0).toInt()),
        duration: Duration(
            milliseconds: (json['duration'] as num? ?? 0).toInt()),
      );
    } catch (e) {
      developer.log('Error restoring PlayerBloc state', error: e, name: 'PlayerBloc');
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PlayerState state) {
    return {
      'queue': state.queue.map((s) => s.path).toList(),
      'shuffledIndices': state.shuffledIndices,
      'currentIndex': state.currentIndex,
      'shuffleMode': state.shuffleMode,
      'repeatMode': state.repeatMode.index,
      'position': state.position.inMilliseconds,
      'duration': state.duration.inMilliseconds,
    };
  }
}