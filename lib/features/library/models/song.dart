import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class Song extends Equatable {
  const Song({
    required this.path,
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.duration,
    this.dateModified,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.hasArtwork,
  });

  final String path;
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;
  final Duration? duration;
  final DateTime? dateModified;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final bool? hasArtwork;

  List<String> get artistList {
    if (artist == null || artist!.isEmpty) return ['Unknown Artist'];
    final regex = RegExp(r'\s*(?:,|&|/|\band\b|\bfeat\.?)\s*', caseSensitive: false);
    return artist!
        .split(regex)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [
        path,
        title,
        artist,
        album,
        artwork,
        duration,
        dateModified,
        year,
        trackNumber,
        discNumber,
        hasArtwork
      ];

  Song copyWith({
    String? path,
    String? title,
    String? artist,
    String? album,
    Uint8List? artwork,
    Duration? duration,
    DateTime? dateModified,
    int? year,
    int? trackNumber,
    int? discNumber,
    bool? hasArtwork,
  }) {
    return Song(
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artwork: artwork ?? this.artwork,
      duration: duration ?? this.duration,
      dateModified: dateModified ?? this.dateModified,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      hasArtwork: hasArtwork ?? this.hasArtwork,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      path: json['path'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      dateModified: json['dateModified'] != null
          ? DateTime.parse(json['dateModified'] as String)
          : null,
      year: json['year'] as int?,
      trackNumber: json['trackNumber'] as int?,
      discNumber: json['discNumber'] as int?,
      artwork: null,
      hasArtwork: json['hasArtwork'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration?.inMilliseconds,
      'dateModified': dateModified?.toIso8601String(),
      'year': year,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'hasArtwork': hasArtwork,
    };
  }

  factory Song.fromDbJson(Map<String, dynamic> json) {
    return Song(
      path: json['path'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      dateModified: json['dateModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateModified'] as int)
          : null,
      year: json['year'] as int?,
      trackNumber: json['trackNumber'] as int?,
      discNumber: json['discNumber'] as int?,
      hasArtwork: (json['hasArtwork'] as int?) == 1,
    );
  }

  Map<String, dynamic> toDbJson() {
    return {
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration?.inMilliseconds,
      'dateModified': dateModified?.millisecondsSinceEpoch,
      'year': year,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'hasArtwork': hasArtwork == true ? 1 : 0,
    };
  }
}