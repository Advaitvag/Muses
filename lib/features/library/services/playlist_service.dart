import 'dart:io';
import 'package:muses/features/library/models/playlist.dart';
import 'package:muses/features/library/models/album.dart';
import 'package:muses/features/library/models/artist.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PlaylistService {
  Directory? _playlistsDir;
  
  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _playlistsDir = Directory(p.join(appDir.path, 'playlists'));
    if (!await _playlistsDir!.exists()) {
      await _playlistsDir!.create(recursive: true);
    }
  }

  Future<List<Playlist>> loadUserPlaylists() async {
    await init();
    final List<Playlist> playlists = [];
    
    if (await _playlistsDir!.exists()) {
      await for (final entity in _playlistsDir!.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.m3u')) {
          try {
            final playlist = await _parseM3u(entity);
            if (playlist != null) {
              playlists.add(playlist);
            }
          } catch (e) {
            // debugPrint('Error loading playlist ${entity.path}: $e');
          }
        }
      }
    }
    
    // Sort by name
    playlists.sort((a, b) => a.name.compareTo(b.name));
    return playlists;
  }

  Future<void> saveUserPlaylist(Playlist playlist) async {
    await init();
    final file = File(p.join(_playlistsDir!.path, '${_sanitizeFilename(playlist.name)}.m3u'));
    await _writeM3u(file, playlist.songPaths, playlist.artworkPath);
  }

  Future<void> deleteUserPlaylist(Playlist playlist) async {
    await init();
    final file = File(p.join(_playlistsDir!.path, '${_sanitizeFilename(playlist.name)}.m3u'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> renameUserPlaylist(String oldName, String newName) async {
    await init();
    final oldFile = File(p.join(_playlistsDir!.path, '${_sanitizeFilename(oldName)}.m3u'));
    final newFile = File(p.join(_playlistsDir!.path, '${_sanitizeFilename(newName)}.m3u'));
    
    if (await oldFile.exists()) {
      await oldFile.rename(newFile.path);
    }
  }

  Future<Map<String, String>> loadArtistArtworks() async {
    await init();
    final artistsDir = Directory(p.join(_playlistsDir!.path, 'Artists'));
    final artworks = <String, String>{};
    
    if (await artistsDir.exists()) {
      await for (final entity in artistsDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.m3u')) {
           final playlist = await _parseM3u(entity);
           if (playlist != null && playlist.artworkPath != null) {
             // The file name is sanitized artist name. 
             // Ideally we should store the exact name in metadata too, but for now we rely on filename mapping or we should handle fuzzy match?
             // Actually, `syncArtistPlaylists` writes filename as sanitized name.
             // But we need to map it back to the Artist Name key in LibraryBloc.
             // Since we don't have the original artist name easily from filename (underscores vs chars), 
             // maybe we should assume the caller can fuzzy match or we only support exact matches if names are simple.
             // BETTER: Store the artist name as a comment `#EXTNAME:Artist Name`?
             // For now, let's just return map of FilenameWithoutExtension -> ArtworkPath.
             // LibraryBloc can then check `_sanitizeFilename(artist.name)` against this map.
             final name = p.basenameWithoutExtension(entity.path);
             artworks[name] = playlist.artworkPath!;
           }
        }
      }
    }
    return artworks;
  }

  Future<Map<String, String>> loadAlbumArtworks() async {
    await init();
    final albumsDir = Directory(p.join(_playlistsDir!.path, 'Albums'));
    final artworks = <String, String>{};
    
    if (await albumsDir.exists()) {
      await for (final entity in albumsDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.m3u')) {
           final playlist = await _parseM3u(entity);
           if (playlist != null && playlist.artworkPath != null) {
             final name = p.basenameWithoutExtension(entity.path);
             artworks[name] = playlist.artworkPath!;
           }
        }
      }
    }
    return artworks;
  }

  Future<void> syncArtistPlaylists(List<Artist> artists) async {
    await init();
    final artistsDir = Directory(p.join(_playlistsDir!.path, 'Artists'));
    if (!await artistsDir.exists()) {
      await artistsDir.create();
    }

    // Write/Update all artist playlists
    for (final artist in artists) {
      final file = File(p.join(artistsDir.path, '${_sanitizeFilename(artist.name)}.m3u'));
      // We pass the artworkPath if it exists in the object. 
      // LibraryBloc is responsible for ensuring the Artist object has the correct artwork path (loaded from disk or user set)
      await _writeM3u(file, artist.songs.map((s) => s.path).toList(), artist.artworkPath);
    }
    
    // Cleanup
    final existingFiles = await artistsDir.list().where((e) => e is File && e.path.endsWith('.m3u')).toList();
    final activeFilenames = artists.map((a) => '${_sanitizeFilename(a.name)}.m3u').toSet();
    
    for (final entity in existingFiles) {
      final filename = p.basename(entity.path);
      if (!activeFilenames.contains(filename)) {
        await entity.delete();
      }
    }
  }

  Future<void> syncAlbumPlaylists(List<Album> albums) async {
    await init();
    final albumsDir = Directory(p.join(_playlistsDir!.path, 'Albums'));
    if (!await albumsDir.exists()) {
      await albumsDir.create();
    }

    for (final album in albums) {
      final name = '${album.artist} - ${album.name}';
      final file = File(p.join(albumsDir.path, '${_sanitizeFilename(name)}.m3u'));
      await _writeM3u(file, album.songs.map((s) => s.path).toList(), album.artworkPath);
    }

    final existingFiles = await albumsDir.list().where((e) => e is File && e.path.endsWith('.m3u')).toList();
    final activeFilenames = albums.map((a) => '${_sanitizeFilename("${a.artist} - ${a.name}")}.m3u').toSet();
    
    for (final entity in existingFiles) {
      final filename = p.basename(entity.path);
      if (!activeFilenames.contains(filename)) {
        await entity.delete();
      }
    }
  }

  Future<Playlist?> _parseM3u(File file) async {
    try {
      final lines = await file.readAsLines();
      final songPaths = <String>[];
      String? artworkPath;
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('#EXTIMG:')) {
          artworkPath = trimmed.substring(8).trim();
          continue;
        }
        if (trimmed.startsWith('#')) continue;
        songPaths.add(trimmed);
      }
      
      final name = p.basenameWithoutExtension(file.path);
      
      return Playlist(
        id: name,
        name: name,
        songPaths: songPaths,
        createdAt: await file.lastModified(),
        artworkPath: artworkPath,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _writeM3u(File file, List<String> paths, [String? artworkPath]) async {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    if (artworkPath != null) {
      buffer.writeln('#EXTIMG:$artworkPath');
    }
    for (final path in paths) {
      buffer.writeln(path);
    }
    await file.writeAsString(buffer.toString());
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
