import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.songPaths,
    required this.createdAt,
    this.artworkPath,
  });

  final String id;
  final String name;
  final List<String> songPaths;
  final DateTime createdAt;
  final String? artworkPath;

  @override
  List<Object?> get props => [id, name, songPaths, createdAt, artworkPath];

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songPaths,
    DateTime? createdAt,
    String? artworkPath,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songPaths: songPaths ?? this.songPaths,
      createdAt: createdAt ?? this.createdAt,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songPaths: List<String>.from(json['songPaths'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      artworkPath: json['artworkPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songPaths': songPaths,
      'createdAt': createdAt.toIso8601String(),
      'artworkPath': artworkPath,
    };
  }
}
