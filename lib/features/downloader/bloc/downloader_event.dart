part of 'downloader_bloc.dart';

abstract class DownloaderEvent extends Equatable {
  const DownloaderEvent();

  @override
  List<Object?> get props => [];
}

class DownloaderUrlChanged extends DownloaderEvent {
  const DownloaderUrlChanged(this.url);
  final String url;

  @override
  List<Object?> get props => [url];
}

class DownloaderStart extends DownloaderEvent {
  const DownloaderStart();
}

class DownloaderPathChanged extends DownloaderEvent {
  const DownloaderPathChanged(this.path);
  final String path;

  @override
  List<Object?> get props => [path];
}

class _DownloaderProgressUpdate extends DownloaderEvent {
  const _DownloaderProgressUpdate(this.update);
  final DownloadUpdate update;

  @override
  List<Object?> get props => [update];
}

class _DownloaderMetadataUpdated extends DownloaderEvent {
  const _DownloaderMetadataUpdated(this.song);
  final Song song;

  @override
  List<Object?> get props => [song];
}

class _DownloaderSuccess extends DownloaderEvent {
  const _DownloaderSuccess(this.filePath);
  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class _DownloaderFailure extends DownloaderEvent {
  const _DownloaderFailure(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}
