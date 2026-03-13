import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muses/features/library/models/song.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDir = await getApplicationSupportDirectory();
    final path = join(appDir.path, 'muses_library.db');

    // Ensure directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs(
        path TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        album TEXT,
        duration INTEGER,
        dateModified INTEGER,
        year INTEGER,
        trackNumber INTEGER,
        discNumber INTEGER,
        hasArtwork INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE artist_artworks(
        name TEXT PRIMARY KEY,
        path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE album_artworks(
        key TEXT PRIMARY KEY,
        path TEXT
      )
    ''');
  }

  Future<void> insertSong(Song song) async {
    final db = await database;
    await db.insert(
      'songs',
      song.toDbJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertSongs(List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert(
        'songs',
        song.toDbJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Song>> getSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');
    return List.generate(maps.length, (i) {
      return Song.fromDbJson(maps[i]);
    });
  }

  Future<void> updateSong(Song song) async {
    final db = await database;
    await db.update(
      'songs',
      song.toDbJson(),
      where: 'path = ?',
      whereArgs: [song.path],
    );
  }

  Future<void> deleteSong(String path) async {
    final db = await database;
    await db.delete(
      'songs',
      where: 'path = ?',
      whereArgs: [path],
    );
  }
  
  Future<void> deleteSongs(List<String> paths) async {
    final db = await database;
    final batch = db.batch();
    for (final path in paths) {
      batch.delete(
        'songs',
        where: 'path = ?',
        whereArgs: [path],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setArtistArtwork(String artistName, String path) async {
    final db = await database;
    await db.insert(
      'artist_artworks',
      {'name': artistName, 'path': path},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getArtistArtworks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('artist_artworks');
    return {
      for (final map in maps) map['name'] as String: map['path'] as String
    };
  }

  Future<void> setAlbumArtwork(String key, String path) async {
    final db = await database;
    await db.insert(
      'album_artworks',
      {'key': key, 'path': path},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAlbumArtworks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('album_artworks');
    return {
      for (final map in maps) map['key'] as String: map['path'] as String
    };
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('songs');
    await db.delete('artist_artworks');
    await db.delete('album_artworks');
  }
}
