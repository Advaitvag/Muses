part of 'downloader_bloc.dart';

enum DownloaderStatus { initial, loading, downloading, success, failure }

class DownloaderState extends Equatable {
  const DownloaderState({
    this.url = '',
    this.status = DownloaderStatus.initial,
    this.progress = 0.0,
    this.downloadStatus = '',
    this.error,
    this.downloadedFilePath,
    this.downloadPath = '',
    this.downloadedSongs = const [],
  });

  final String url;
  final DownloaderStatus status;
  final double progress;
  final String downloadStatus;
  final String? error;
  final String? downloadedFilePath;
  final String downloadPath;
  final List<Song> downloadedSongs;

  DownloaderState copyWith({
    String? url,
    DownloaderStatus? status,
    double? progress,
    String? downloadStatus,
    String? error,
    String? downloadedFilePath,
    String? downloadPath,
    List<Song>? downloadedSongs,
  }) {
    return DownloaderState(
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      error: error ?? this.error,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      downloadPath: downloadPath ?? this.downloadPath,
      downloadedSongs: downloadedSongs ?? this.downloadedSongs,
    );
  }

  @override
  List<Object?> get props => [
        url,
        status,
        progress,
        downloadStatus,
        error,
        downloadedFilePath,
        downloadPath,
        downloadedSongs,
      ];
}
