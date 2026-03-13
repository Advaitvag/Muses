import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:muses/core/database/database_service.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/library/models/album.dart';
import 'package:muses/features/library/models/artist.dart';
import 'package:muses/features/library/services/playlist_service.dart';
import 'package:muses/features/settings/bloc/folders_bloc.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends HydratedBloc<LibraryEvent, LibraryState> {
  LibraryBloc({
    required FoldersBloc foldersBloc,
    required PlaylistService playlistService,
  })  : _playlistService = playlistService,
        super(const LibraryLoading()) {
    _currentFolders = foldersBloc.state.folders;
    _foldersSubscription = foldersBloc.stream.listen((state) {
      add(UpdateFolders(state.folders));
    });

    on<LoadLibrary>(_onLoadLibrary);
    on<UpdateFolders>(_onUpdateFolders);
    on<ChangeSort>(_onChangeSort);
    on<UpdateSong>(_onUpdateSong);
    on<SetArtistArtwork>(_onSetArtistArtwork);
    on<SetAlbumArtwork>(_onSetAlbumArtwork);
  }

  final PlaylistService _playlistService;
  late final StreamSubscription _foldersSubscription;
  List<String> _currentFolders = [];

  Future<void> _onUpdateSong(UpdateSong event, Emitter<LibraryState> emit) async {
    developer.log('Updating song: ${event.song.title}', name: 'LibraryBloc');
    if (state is LibraryLoaded) {
      await DatabaseService().updateSong(event.song);
      
      final loadedState = state as LibraryLoaded;
      final updatedSongs = List<Song>.from(loadedState.songs);
      final index = updatedSongs.indexWhere((s) => s.path == event.song.path);
      
      if (index != -1) {
        updatedSongs[index] = event.song;
      } else {
        updatedSongs.add(event.song);
      }

      final newState = LibraryLoaded(
        updatedSongs,
        sortType: loadedState.sortType,
        ascending: loadedState.ascending,
        artistArtworks: loadedState.artistArtworks,
        albumArtworks: loadedState.albumArtworks,
        lastUpdated: DateTime.now(),
      );
      
      emit(newState);
      
      // Sync playlists to reflect changes in artists/albums immediately
      _playlistService.syncArtistPlaylists(newState.artists);
      _playlistService.syncAlbumPlaylists(newState.albums);
    }
  }

  Future<void> _onSetArtistArtwork(SetArtistArtwork event, Emitter<LibraryState> emit) async {
    if (state is LibraryLoaded) {
      final loadedState = state as LibraryLoaded;
      final key = event.artist.name;
      
      await DatabaseService().setArtistArtwork(key, event.path);

      final newArtworks = Map<String, String>.from(loadedState.artistArtworks);
      newArtworks[key] = event.path;
      
      final newState = LibraryLoaded(
        loadedState.songs,
        sortType: state.sortType,
        ascending: state.ascending,
        artistArtworks: newArtworks,
        albumArtworks: loadedState.albumArtworks,
        lastUpdated: DateTime.now(),
      );
      
      emit(newState);
    }
  }

  Future<void> _onSetAlbumArtwork(SetAlbumArtwork event, Emitter<LibraryState> emit) async {
    if (state is LibraryLoaded) {
      final loadedState = state as LibraryLoaded;
      final key = '${event.album.artist} - ${event.album.name}';
      
      await DatabaseService().setAlbumArtwork(key, event.path);
      
      final newArtworks = Map<String, String>.from(loadedState.albumArtworks);
      newArtworks[key] = event.path;
      
      final newState = LibraryLoaded(
        loadedState.songs,
        sortType: state.sortType,
        ascending: state.ascending,
        artistArtworks: loadedState.artistArtworks,
        albumArtworks: newArtworks,
        lastUpdated: DateTime.now(),
      );
      
      emit(newState);
    }
  }

  void _onUpdateFolders(UpdateFolders event, Emitter<LibraryState> emit) {
    _currentFolders = event.folders;
    add(LoadLibrary());
  }

  void _onChangeSort(ChangeSort event, Emitter<LibraryState> emit) {
    if (state is LibraryLoaded) {
      final loaded = state as LibraryLoaded;
      emit(LibraryLoaded(
        loaded.songs,
        sortType: event.sortType,
        ascending: event.ascending,
        artistArtworks: loaded.artistArtworks,
        albumArtworks: loaded.albumArtworks,
        lastUpdated: state.lastUpdated,
      ));
    } else if (state is LibraryLoading) {
      emit(LibraryLoading(
        sortType: event.sortType,
        ascending: event.ascending,
        lastUpdated: state.lastUpdated,
      ));
    }
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    developer.log('Loading library...', name: 'LibraryBloc');
    try {
      final db = DatabaseService();
      
      // 1. Load from DB immediately
      final dbSongs = await db.getSongs();
      developer.log('Loaded ${dbSongs.length} songs from DB', name: 'LibraryBloc');
      final artistArtworks = await db.getArtistArtworks();
      final albumArtworks = await db.getAlbumArtworks();

      if (dbSongs.isNotEmpty) {
        final loadedState = LibraryLoaded(
          dbSongs,
          sortType: state.sortType,
          ascending: state.ascending,
          artistArtworks: artistArtworks,
          albumArtworks: albumArtworks,
          lastUpdated: DateTime.now(),
        );
        emit(loadedState);
        _playlistService.syncArtistPlaylists(loadedState.artists);
        _playlistService.syncAlbumPlaylists(loadedState.albums);
      }

      // 2. Sync with file system
      await _syncLibrary(emit, dbSongs, artistArtworks, albumArtworks);

    } catch (e) {
      developer.log('Error loading library', error: e, name: 'LibraryBloc');
      emit(LibraryError(e.toString(), sortType: state.sortType, ascending: state.ascending, lastUpdated: state.lastUpdated));
    }
  }

  Future<void> _syncLibrary(
    Emitter<LibraryState> emit,
    List<Song> currentDbSongs,
    Map<String, String> artistArtworks,
    Map<String, String> albumArtworks,
  ) async {
    if (_currentFolders.isEmpty) {
      if (Platform.isAndroid) {
        _currentFolders = ['/storage/emulated/0/Music'];
      } else {
        String? home;
        if (Platform.isWindows) {
          home = Platform.environment['USERPROFILE'];
        } else {
          home = Platform.environment['HOME'];
        }

        if (home != null) {
          _currentFolders = [Directory('$home/Music').path];
        }
      }
    }

    final db = DatabaseService();
    final Set<String> fsSongPaths = {};
    
    // Scan folders
    for (final folderPath in _currentFolders) {
      final musicDir = Directory(folderPath);
      if (musicDir.existsSync()) {
        try {
           await for (final file in musicDir.list(recursive: true)) {
             final path = file.path;
             if (_isAudioFile(path)) {
               fsSongPaths.add(path);
             }
           }
        } catch (e) {
           developer.log('Error scanning folder $folderPath', error: e, name: 'LibraryBloc');
        }
      }
    }

    final Map<String, Song> dbSongsMap = {
      for (final song in currentDbSongs) song.path: song
    };

    final List<Song> songsToAdd = [];
    final List<Song> songsToUpdate = [];
    final List<String> pathsToRemove = [];

    // Identify removals
    for (final dbSong in currentDbSongs) {
      if (!fsSongPaths.contains(dbSong.path)) {
        pathsToRemove.add(dbSong.path);
      }
    }

    // Identify adds and updates
    for (final path in fsSongPaths) {
      final dbSong = dbSongsMap[path];
      final file = File(path);
      
      if (dbSong == null) {
        final song = await _readMetadata(file);
        songsToAdd.add(song);
      } else {
        try {
          final lastModified = file.lastModifiedSync();
          if (dbSong.dateModified == null || 
              lastModified.difference(dbSong.dateModified!).abs().inSeconds > 1) {
             final song = await _readMetadata(file);
             songsToUpdate.add(song);
          }
        } catch (e) {
           // File might be gone
        }
      }
    }

    if (pathsToRemove.isNotEmpty) {
      await db.deleteSongs(pathsToRemove);
    }
    if (songsToAdd.isNotEmpty) {
      await db.insertSongs(songsToAdd);
    }
    if (songsToUpdate.isNotEmpty) {
      await db.insertSongs(songsToUpdate);
    }

    bool hasChanges = pathsToRemove.isNotEmpty || songsToAdd.isNotEmpty || songsToUpdate.isNotEmpty;

    if (hasChanges) {
       final finalSongs = await db.getSongs();
       final loadedState = LibraryLoaded(
         finalSongs,
         sortType: state.sortType,
         ascending: state.ascending,
         artistArtworks: artistArtworks,
         albumArtworks: albumArtworks,
         lastUpdated: DateTime.now(),
       );
       emit(loadedState);
       _playlistService.syncArtistPlaylists(loadedState.artists);
       _playlistService.syncAlbumPlaylists(loadedState.albums);
    } else if (currentDbSongs.isEmpty && songsToAdd.isEmpty) {
       emit(LibraryLoaded(
         const [],
         sortType: state.sortType,
         ascending: state.ascending,
         artistArtworks: artistArtworks,
         albumArtworks: albumArtworks,
         lastUpdated: DateTime.now(),
       ));
    }
  }

  bool _isAudioFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp3') ||
           ext.endsWith('.flac') ||
           ext.endsWith('.wav') ||
           ext.endsWith('.m4a') ||
           ext.endsWith('.opus') ||
           ext.endsWith('.ogg');
  }

  Future<Song> _readMetadata(File file) async {
    final path = file.path;
    final dateMod = file.lastModifiedSync();
    try {
      final metadata = await MetadataGod.readMetadata(file: path);
      return Song(
        path: path,
        title: metadata.title ?? path.split('/').last,
        artist: metadata.artist,
        album: metadata.album,
        duration: metadata.duration,
        year: metadata.year,
        trackNumber: metadata.trackNumber ?? 0,
        discNumber: metadata.discNumber ?? 1,
        hasArtwork: metadata.picture != null,
        dateModified: dateMod,
      );
    } catch (e) {
      developer.log('Error reading metadata for $path', error: e, name: 'LibraryBloc');
      return Song(
        path: path,
        title: path.split('/').last,
        dateModified: dateMod,
        hasArtwork: false,
        trackNumber: 0,
        discNumber: 1,
      );
    }
  }


  @override
  Future<void> close() {
    _foldersSubscription.cancel();
    return super.close();
  }

  @override
  LibraryState? fromJson(Map<String, dynamic> json) {
    try {
      final sortType = SortType.values[json['sortType'] as int? ?? 0];
      final ascending = json['ascending'] as bool? ?? true;
      final lastUpdated = json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null;

      if (json['songs'] != null) {
        final songs = (json['songs'] as List)
            .map((e) => Song.fromJson(e as Map<String, dynamic>))
            .toList();
        // Artworks are not persisted in json, reloaded from files on init
        return LibraryLoaded(
          songs,
          sortType: sortType,
          ascending: ascending,
          lastUpdated: lastUpdated,
        );
      }
      return LibraryLoading(
        sortType: sortType,
        ascending: ascending,
        lastUpdated: lastUpdated,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(LibraryState state) {
    final data = {
      'sortType': state.sortType.index,
      'ascending': state.ascending,
      'lastUpdated': state.lastUpdated?.toIso8601String(),
    };
    if (state is LibraryLoaded) {
      data['songs'] = state.songs.map((e) => e.toJson()).toList();
    }
    return data;
  }
}
