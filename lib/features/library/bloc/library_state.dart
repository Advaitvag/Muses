part of 'library_bloc.dart';

enum SortType { name, dateReleased, dateModified, duration, trackNumber }

abstract class LibraryState extends Equatable {
  const LibraryState({
    this.sortType = SortType.name,
    this.ascending = true,
    this.lastUpdated,
  });

  final SortType sortType;
  final bool ascending;
  final DateTime? lastUpdated;

  @override
  List<Object?> get props => [sortType, ascending, lastUpdated];
}

class LibraryLoading extends LibraryState {
  const LibraryLoading({super.sortType, super.ascending, super.lastUpdated});
}

class LibraryLoaded extends LibraryState {
  const LibraryLoaded(
    this.songs, {
    this.artistArtworks = const {},
    this.albumArtworks = const {},
    super.sortType,
    super.ascending,
    super.lastUpdated,
  }) : super();

  final List<Song> songs;
  final Map<String, String> artistArtworks;
  final Map<String, String> albumArtworks;

  List<Song> get sortedSongs {
    final sorted = List<Song>.from(songs);
    sorted.sort((a, b) {
      int cmp;
      switch (sortType) {
        case SortType.name:
          cmp = (a.title ?? '').compareTo(b.title ?? '');
          break;
        case SortType.dateReleased:
          cmp = (a.year ?? 0).compareTo(b.year ?? 0);
          break;
        case SortType.dateModified:
          cmp = (a.dateModified ?? DateTime(0)).compareTo(b.dateModified ?? DateTime(0));
          break;
        case SortType.duration:
          cmp = (a.duration ?? Duration.zero).compareTo(b.duration ?? Duration.zero);
          break;
        case SortType.trackNumber:
          int discCmp = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
          if (discCmp != 0) {
            cmp = discCmp;
          } else {
            cmp = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
          }
          break;
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }
  
  List<Album> get albums {
    final Map<String, List<Song>> albumMap = {};
    for (final song in songs) {
      final albumName = song.album ?? 'Unknown Album';
      final primaryArtist = song.artistList.first;
      // Group by album name and primary artist to avoid splitting featured tracks into separate albums
      final key = '${albumName}_$primaryArtist';
      albumMap.putIfAbsent(key, () => []).add(song);
    }

    final albumsList = albumMap.entries.map((entry) {
      final firstSong = entry.value.first;
      final albumName = firstSong.album ?? 'Unknown Album';
      // Use the full artist name from the first song in the group
      final artistName = firstSong.artist ?? 'Unknown Artist';

      // Look for custom artwork
      final key = '$artistName - $albumName';
      String? artPath = albumArtworks[key];

      if (artPath == null) {
        final artworkSong = entry.value.cast<Song?>().firstWhere(
              (s) => s?.hasArtwork == true,
              orElse: () => null,
            );
        artPath = artworkSong?.path;
      }

      return Album(
        name: albumName,
        artist: artistName,
        songs: entry.value,
        artworkPath: artPath,
      );
    }).toList();

    albumsList.sort((a, b) {
      int cmp;
      switch (sortType) {
        case SortType.name:
          cmp = a.name.compareTo(b.name);
          break;
        case SortType.dateReleased:
          // Use year of first song
          cmp = (a.songs.first.year ?? 0).compareTo(b.songs.first.year ?? 0);
          break;
        case SortType.dateModified:
          // Latest modified song in album
          final aMod = a.songs
              .map((s) => s.dateModified ?? DateTime(0))
              .reduce((curr, next) => curr.isAfter(next) ? curr : next);
          final bMod = b.songs
              .map((s) => s.dateModified ?? DateTime(0))
              .reduce((curr, next) => curr.isAfter(next) ? curr : next);
          cmp = aMod.compareTo(bMod);
          break;
        case SortType.duration:
          final aDur = a.songs
              .fold(Duration.zero, (prev, s) => prev + (s.duration ?? Duration.zero));
          final bDur = b.songs
              .fold(Duration.zero, (prev, s) => prev + (s.duration ?? Duration.zero));
          cmp = aDur.compareTo(bDur);
          break;
        case SortType.trackNumber:
          cmp = a.name.compareTo(b.name);
          break;
      }
      return ascending ? cmp : -cmp;
    });
    return albumsList;
  }

  List<Artist> get artists {
    final Map<String, List<Song>> artistMap = {};
    for (final song in songs) {
      final artistNames = song.artistList;

      for (final artistName in artistNames) {
        artistMap.putIfAbsent(artistName, () => []).add(song);
      }
    }

    final artistsList = artistMap.entries.map((entry) {
      return Artist(
        name: entry.key,
        songs: entry.value,
        artworkPath: artistArtworks[entry.key],
      );
    }).toList();

    artistsList.sort((a, b) {
      int cmp;
      switch (sortType) {
        case SortType.name:
          cmp = a.name.compareTo(b.name);
          break;
        case SortType.dateModified:
          final aMod = a.songs.map((s) => s.dateModified ?? DateTime(0)).reduce((curr, next) => curr.isAfter(next) ? curr : next);
          final bMod = b.songs.map((s) => s.dateModified ?? DateTime(0)).reduce((curr, next) => curr.isAfter(next) ? curr : next);
          cmp = aMod.compareTo(bMod);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return ascending ? cmp : -cmp;
    });
    return artistsList;
  }

  @override
  List<Object?> get props => [songs, sortType, ascending, artistArtworks, albumArtworks, lastUpdated];
}

class LibraryError extends LibraryState {
  const LibraryError(this.message, {super.sortType, super.ascending, super.lastUpdated});

  final String message;

  @override
  List<Object?> get props => [message, sortType, ascending, lastUpdated];
}
