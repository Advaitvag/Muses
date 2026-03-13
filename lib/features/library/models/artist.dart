import 'package:equatable/equatable.dart';
import 'package:muses/features/library/models/song.dart';

class Artist extends Equatable {
  const Artist({
    required this.name,
    required this.songs,
    this.artworkPath,
  });

  final String name;
  final List<Song> songs;
  final String? artworkPath;

  @override
  List<Object?> get props => [name, songs, artworkPath];

  Artist copyWith({
    String? name,
    List<Song>? songs,
    String? artworkPath,
  }) {
    return Artist(
      name: name ?? this.name,
      songs: songs ?? this.songs,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }
  
  Artist copyWithSongs(List<Song> newSongs) {
    return Artist(
      name: name,
      songs: newSongs,
      artworkPath: artworkPath,
    );
  }
}
