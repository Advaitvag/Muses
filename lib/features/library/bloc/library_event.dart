part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class UpdateFolders extends LibraryEvent {
  const UpdateFolders(this.folders);

  final List<String> folders;

  @override
  List<Object> get props => [folders];
}

class ChangeSort extends LibraryEvent {
  const ChangeSort(this.sortType, this.ascending);
  final SortType sortType;
  final bool ascending;

  @override
  List<Object> get props => [sortType, ascending];
}

class UpdateSong extends LibraryEvent {
  const UpdateSong(this.song);
  final Song song;

  @override
  List<Object> get props => [song];
}

class SetArtistArtwork extends LibraryEvent {
  const SetArtistArtwork(this.artist, this.path);
  final Artist artist;
  final String path;

  @override
  List<Object> get props => [artist, path];
}

class SetAlbumArtwork extends LibraryEvent {
  const SetAlbumArtwork(this.album, this.path);
  final Album album;
  final String path;

  @override
  List<Object> get props => [album, path];
}
