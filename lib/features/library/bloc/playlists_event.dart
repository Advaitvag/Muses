part of 'playlists_bloc.dart';

abstract class PlaylistsEvent extends Equatable {
  const PlaylistsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylists extends PlaylistsEvent {}

class CreatePlaylist extends PlaylistsEvent {
  const CreatePlaylist(this.name, {this.initialSongPaths});
  final String name;
  final List<String>? initialSongPaths;

  @override
  List<Object?> get props => [name, initialSongPaths];
}

class DeletePlaylist extends PlaylistsEvent {
  const DeletePlaylist(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class AddSongsToPlaylist extends PlaylistsEvent {
  const AddSongsToPlaylist({required this.playlistId, required this.songPaths});
  final String playlistId;
  final List<String> songPaths;

  @override
  List<Object?> get props => [playlistId, songPaths];
}

class RemoveSongFromPlaylist extends PlaylistsEvent {
  const RemoveSongFromPlaylist({required this.playlistId, required this.songPath});
  final String playlistId;
  final String songPath;

  @override
  List<Object?> get props => [playlistId, songPath];
}

class RenamePlaylist extends PlaylistsEvent {
  const RenamePlaylist(this.id, this.newName);
  final String id;
  final String newName;

  @override
  List<Object?> get props => [id, newName];
}

class ReorderPlaylistSongs extends PlaylistsEvent {
  const ReorderPlaylistSongs({
    required this.playlistId,
    required this.oldIndex,
    required this.newIndex,
  });

  final String playlistId;
  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [playlistId, oldIndex, newIndex];
}

class SetPlaylistArtwork extends PlaylistsEvent {
  const SetPlaylistArtwork(this.id, this.path);
  final String id;
  final String path;

  @override
  List<Object?> get props => [id, path];
}
