import 'dart:io';
import 'dart:developer' as developer;

import 'package:anni_mpris_service/anni_mpris_service.dart';
import 'package:muses/core/utils/artwork_manager.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;

class MusesMprisService extends MPRISService {
  MusesMprisService(this._playerBloc)
      : super(
          "muses",
          identity: "Muses",
          desktopEntry: "com.advaitv.muses",
          canPause: true,
          canGoPrevious: true,
          canGoNext: true,
          canSeek: true,
          canControl: true,
          supportLoopStatus: true,
          supportShuffle: true,
        ) {
    if (Platform.isLinux) {
      _playerBloc.stream.listen(_onPlayerStateChanged);
      _onPlayerStateChanged(_playerBloc.state);
    }
  }

  final PlayerBloc _playerBloc;
  Song? _lastSong;
  String? _currentArtPath;

  void _onPlayerStateChanged(PlayerState state) {
    playbackStatus = _mapStatus(state.status);
    updatePosition(state.position);
    
    final song = state.currentSong;
    if (song != null) {
      if (song != _lastSong) {
        final bool pathChanged = song.path != _lastSong?.path;
        _lastSong = song;
        
        if (pathChanged) {
          _currentArtPath = null;
        }
        
        if (song.hasArtwork == true) {
          _updateArt(song);
        }
      }

      metadata = Metadata(
        trackId: '/org/mpris/MediaPlayer2/Muses/track/${song.path.hashCode}',
        trackTitle: song.title ?? 'Unknown',
        trackArtist: song.artistList,
        albumName: song.album ?? 'Unknown',
        trackLength: state.duration,
        artUrl: _currentArtPath,
      );
    } else {
      metadata = Metadata(
        trackId: '/org/mpris/MediaPlayer2/Muses/track/none',
        trackTitle: 'No music playing',
      );
      _lastSong = null;
      _currentArtPath = null;
    }

    // super calls because we want to update the internal state without triggering 
    // the overridden setters logic (which would send events back to PlayerBloc)
    super.loopStatus = _mapLoopMode(state.repeatMode);
    super.shuffle = state.shuffleMode;
  }

  Future<void> _updateArt(Song song) async {
    try {
      final file = await ArtworkManager().getArtworkFile(song.path);
      if (file != null) {
        _currentArtPath = 'file://${file.path}';
        // Trigger a metadata update now that we have the art path
        _onPlayerStateChanged(_playerBloc.state);
      }
    } catch (e) {
      developer.log('Error updating MPRIS art', error: e, name: 'MusesMprisService');
    }
  }

  PlaybackStatus _mapStatus(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.playing:
        return PlaybackStatus.playing;
      case PlayerStatus.paused:
        return PlaybackStatus.paused;
      default:
        return PlaybackStatus.stopped;
    }
  }

  LoopStatus _mapLoopMode(ja.LoopMode loopMode) {
    switch (loopMode) {
      case ja.LoopMode.one:
        return LoopStatus.track;
      case ja.LoopMode.all:
        return LoopStatus.playlist;
      case ja.LoopMode.off:
        return LoopStatus.none;
    }
  }

  @override
  Future<void> onPlay() async => _playerBloc.add(PlayerResume());

  @override
  Future<void> onPause() async => _playerBloc.add(PlayerPause());

  @override
  Future<void> onPlayPause() async {
    if (_playerBloc.state.status == PlayerStatus.playing) {
      _playerBloc.add(PlayerPause());
    } else {
      _playerBloc.add(PlayerResume());
    }
  }

  @override
  Future<void> onStop() async => _playerBloc.add(PlayerPause());

  @override
  Future<void> onNext() async => _playerBloc.add(PlayerNext());

  @override
  Future<void> onPrevious() async => _playerBloc.add(PlayerPrevious());

  @override
  Future<void> onSeek(int offset) async {
    // anni_mpris_service uses microseconds (int) for onSeek
    final newPosition = _playerBloc.state.position + Duration(microseconds: offset);
    _playerBloc.add(PlayerSeek(newPosition));
  }

  @override
  Future<void> onSetPosition(String trackId, int position) async {
    // anni_mpris_service uses microseconds (int) for onSetPosition
    _playerBloc.add(PlayerSeek(Duration(microseconds: position)));
  }

  @override
  Future<void> onLoopStatus(LoopStatus loopStatus) async {
    final currentMode = _playerBloc.state.repeatMode;
    if (loopStatus == LoopStatus.track && currentMode != ja.LoopMode.one) {
      _playerBloc.add(PlayerToggleRepeat());
    } else if (loopStatus == LoopStatus.playlist && currentMode != ja.LoopMode.all) {
      _playerBloc.add(PlayerToggleRepeat());
    } else if (loopStatus == LoopStatus.none && currentMode != ja.LoopMode.off) {
      _playerBloc.add(PlayerToggleRepeat());
    }
  }

  @override
  Future<void> onShuffle(bool shuffle) async {
    if (shuffle != _playerBloc.state.shuffleMode) {
      _playerBloc.add(PlayerToggleShuffle());
    }
  }
}