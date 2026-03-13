import 'package:equatable/equatable.dart';
import 'package:muses/features/library/models/song.dart';

class Album extends Equatable {
  const Album({
    required this.name,
    required this.artist,
    required this.songs,
    this.artworkPath,
  });

  final String name;
  final String artist;
  final List<Song> songs;
  final String? artworkPath;

  @override
  List<Object?> get props => [name, artist, songs, artworkPath];

  Album copyWith({
    String? name,
    String? artist,
    List<Song>? songs,
    String? artworkPath,
  }) {
    return Album(
      name: name ?? this.name,
      artist: artist ?? this.artist,
      songs: songs ?? this.songs,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }

  Album copyWithSongs(List<Song> newSongs) {
    return Album(
      name: name,
      artist: artist,
      songs: newSongs,
      artworkPath: artworkPath,
    );
  }
}
