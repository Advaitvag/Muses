import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muses/features/library/models/playlist.dart';
import 'package:muses/features/library/services/playlist_service.dart';

part 'playlists_event.dart';
part 'playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  PlaylistsBloc({required PlaylistService playlistService}) 
      : _playlistService = playlistService,
        super(const PlaylistsState()) {
    on<LoadPlaylists>(_onLoadPlaylists);
    on<CreatePlaylist>(_onCreatePlaylist);
    on<DeletePlaylist>(_onDeletePlaylist);
    on<AddSongsToPlaylist>(_onAddSongsToPlaylist);
    on<RemoveSongFromPlaylist>(_onRemoveSongFromPlaylist);
    on<RenamePlaylist>(_onRenamePlaylist);
    on<ReorderPlaylistSongs>(_onReorderPlaylistSongs);
    on<SetPlaylistArtwork>(_onSetPlaylistArtwork);

    add(LoadPlaylists());
  }

  final PlaylistService _playlistService;

  Future<void> _onReorderPlaylistSongs(ReorderPlaylistSongs event, Emitter<PlaylistsState> emit) async {
    final playlistIndex = state.playlists.indexWhere((p) => p.id == event.playlistId);
    if (playlistIndex != -1) {
      final playlist = state.playlists[playlistIndex];
      final newPaths = List<String>.from(playlist.songPaths);
      
      int correctedNewIndex = event.newIndex;
      if (event.oldIndex < event.newIndex) {
        correctedNewIndex -= 1;
      }
      
      final item = newPaths.removeAt(event.oldIndex);
      newPaths.insert(correctedNewIndex, item);
      
      final updatedPlaylist = playlist.copyWith(songPaths: newPaths);
      
      // Update local state immediately to avoid flickering
      final newPlaylists = List<Playlist>.from(state.playlists);
      newPlaylists[playlistIndex] = updatedPlaylist;
      emit(state.copyWith(playlists: newPlaylists));

      // Persist changes
      await _playlistService.saveUserPlaylist(updatedPlaylist);
    }
  }

  Future<void> _onSetPlaylistArtwork(SetPlaylistArtwork event, Emitter<PlaylistsState> emit) async {
    final playlistIndex = state.playlists.indexWhere((p) => p.id == event.id);
    if (playlistIndex != -1) {
      final playlist = state.playlists[playlistIndex];
      final updatedPlaylist = playlist.copyWith(artworkPath: event.path);
      await _playlistService.saveUserPlaylist(updatedPlaylist);
      add(LoadPlaylists());
    }
  }

  Future<void> _onLoadPlaylists(LoadPlaylists event, Emitter<PlaylistsState> emit) async {
    final playlists = await _playlistService.loadUserPlaylists();
    // Ensure Favourites exists
    if (!playlists.any((p) => p.name == 'Favourites')) {
      final favourites = Playlist(
        id: 'Favourites',
        name: 'Favourites',
        songPaths: [],
        createdAt: DateTime.now(),
      );
      await _playlistService.saveUserPlaylist(favourites);
      playlists.add(favourites);
      playlists.sort((a, b) => a.name.compareTo(b.name));
    }
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onCreatePlaylist(CreatePlaylist event, Emitter<PlaylistsState> emit) async {
    final playlist = Playlist(
      id: event.name, // Use name as ID for file-based playlists
      name: event.name,
      songPaths: event.initialSongPaths ?? [],
      createdAt: DateTime.now(),
    );
    
    await _playlistService.saveUserPlaylist(playlist);
    add(LoadPlaylists());
  }

  Future<void> _onDeletePlaylist(DeletePlaylist event, Emitter<PlaylistsState> emit) async {
    final playlist = state.playlists.firstWhere((p) => p.id == event.id, orElse: () => 
      Playlist(id: '', name: '', songPaths: [], createdAt: DateTime.now()));
    
    if (playlist.id.isNotEmpty) {
      await _playlistService.deleteUserPlaylist(playlist);
      add(LoadPlaylists());
    }
  }

  Future<void> _onAddSongsToPlaylist(AddSongsToPlaylist event, Emitter<PlaylistsState> emit) async {
    final playlistIndex = state.playlists.indexWhere((p) => p.id == event.playlistId);
    if (playlistIndex != -1) {
      final playlist = state.playlists[playlistIndex];
      final newPaths = List<String>.from(playlist.songPaths);
      for (final path in event.songPaths) {
        if (!newPaths.contains(path)) {
          newPaths.add(path);
        }
      }
      final updatedPlaylist = playlist.copyWith(songPaths: newPaths);
      await _playlistService.saveUserPlaylist(updatedPlaylist);
      add(LoadPlaylists());
    }
  }

  Future<void> _onRemoveSongFromPlaylist(RemoveSongFromPlaylist event, Emitter<PlaylistsState> emit) async {
    final playlistIndex = state.playlists.indexWhere((p) => p.id == event.playlistId);
    if (playlistIndex != -1) {
      final playlist = state.playlists[playlistIndex];
      final updatedPlaylist = playlist.copyWith(
        songPaths: playlist.songPaths.where((path) => path != event.songPath).toList(),
      );
      await _playlistService.saveUserPlaylist(updatedPlaylist);
      add(LoadPlaylists());
    }
  }

  Future<void> _onRenamePlaylist(RenamePlaylist event, Emitter<PlaylistsState> emit) async {
    final playlist = state.playlists.firstWhere((p) => p.id == event.id, orElse: () => 
      Playlist(id: '', name: '', songPaths: [], createdAt: DateTime.now()));
      
    if (playlist.id.isNotEmpty) {
      await _playlistService.renameUserPlaylist(playlist.name, event.newName);
      // Since ID is based on name, we effectively created a new one (file rename)
      // but logic handles it.
      add(LoadPlaylists());
    }
  }
}