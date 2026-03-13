import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';

class ArtworkManager {
  static final ArtworkManager _instance = ArtworkManager._internal();
  factory ArtworkManager() => _instance;
  ArtworkManager._internal();

  Directory? _cacheDir;

  Future<void> init() async {
    if (_cacheDir != null) return;
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/muses_art_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  File getCacheFile(String songPath, int songId) {
    if (_cacheDir == null) {
      throw StateError('ArtworkManager not initialized. Call init() first.');
    }
    // Using hashCode of path as ID if not provided, but generally we want a unique ID.
    // The song object has `path.hashCode` usage in other places.
    return File('${_cacheDir!.path}/$songId.jpg');
  }

  Future<File?> getArtworkFile(String songPath) async {
    await init();
    final fileId = songPath.hashCode;
    final file = getCacheFile(songPath, fileId);

    if (await file.exists()) {
      return file;
    }

    // Attempt to extract and cache
    try {
      final metadata = await MetadataGod.readMetadata(file: songPath);
      final artwork = metadata.picture?.data;
      if (artwork != null) {
        await file.writeAsBytes(artwork);
        return file;
      }
    } catch (e) {
      debugPrint('Error extracting artwork for $songPath: $e');
    }
    return null;
  }

  Future<Uint8List?> getArtworkBytes(String songPath) async {
    final file = await getArtworkFile(songPath);
    return file?.readAsBytes();
  }
  
  /// Checks if artwork is cached without attempting to extract it.
  Future<bool> isArtworkCached(String songPath) async {
    await init();
    final fileId = songPath.hashCode;
    final file = getCacheFile(songPath, fileId);
    return file.exists();
  }

  Future<void> clearCache() async {
    await init();
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create();
    }
  }
}
