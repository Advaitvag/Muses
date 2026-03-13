import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:muses/features/downloader/services/download_service.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/settings/bloc/folders_bloc.dart';

part 'downloader_event.dart';
part 'downloader_state.dart';

class DownloaderBloc extends Bloc<DownloaderEvent, DownloaderState> {
  DownloaderBloc({
    required DownloadService downloadService,
    required FoldersBloc foldersBloc,
  })  : _downloadService = downloadService,
        _foldersBloc = foldersBloc,
        super(DownloaderState(
          downloadPath: foldersBloc.state.folders.isNotEmpty 
              ? foldersBloc.state.folders.first 
              : '',
        )) {
    on<DownloaderUrlChanged>(_onUrlChanged);
    on<DownloaderPathChanged>(_onPathChanged);
    on<DownloaderStart>(_onStart);
    on<_DownloaderProgressUpdate>(_onProgressUpdate);
    on<_DownloaderMetadataUpdated>(_onMetadataUpdated);
    on<_DownloaderSuccess>(_onSuccess);
    on<_DownloaderFailure>(_onFailure);
  }

  final DownloadService _downloadService;
  final FoldersBloc _foldersBloc;
  StreamSubscription? _downloadSubscription;

  void _onUrlChanged(DownloaderUrlChanged event, Emitter<DownloaderState> emit) {
    emit(state.copyWith(url: event.url, status: DownloaderStatus.initial));
  }

  void _onPathChanged(DownloaderPathChanged event, Emitter<DownloaderState> emit) {
    emit(state.copyWith(downloadPath: event.path));
  }

  Future<void> _onStart(DownloaderStart event, Emitter<DownloaderState> emit) async {
    if (state.url.isEmpty) return;

    emit(state.copyWith(status: DownloaderStatus.loading, progress: 0.0, downloadStatus: 'Preparing...'));

    String outputDir = state.downloadPath;
    if (outputDir.isEmpty) {
       final folders = _foldersBloc.state.folders;
       if (folders.isEmpty) {
         emit(state.copyWith(status: DownloaderStatus.failure, error: 'No download folder configured.'));
         return;
       }
       outputDir = folders.first;
    }

    try {
      await _downloadSubscription?.cancel();
      _downloadSubscription = _downloadService.downloadMusic(state.url, outputDir).listen(
        (update) {
          add(_DownloaderProgressUpdate(update));
        },
        onError: (error) {
          add(_DownloaderFailure(error.toString()));
        },
        onDone: () {
          if (state.status != DownloaderStatus.failure) {
            add(const _DownloaderSuccess(''));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(status: DownloaderStatus.failure, error: e.toString()));
    }
  }

  void _onProgressUpdate(_DownloaderProgressUpdate event, Emitter<DownloaderState> emit) {
    final update = event.update;
    emit(state.copyWith(
      status: DownloaderStatus.downloading,
      progress: update.progress,
      downloadStatus: update.status,
    ));

    if (update.isFinished && update.filePath != null) {
       _extractMetadata(update.filePath!);
    }
  }

  Future<void> _extractMetadata(String filePath) async {
    try {
      final metadata = await MetadataGod.readMetadata(file: filePath);
      final song = Song(
        path: filePath,
        title: metadata.title ?? filePath.split('/').last,
        artist: metadata.artist,
        album: metadata.album,
        duration: metadata.duration,
        hasArtwork: metadata.picture != null,
        dateModified: DateTime.now(),
        trackNumber: metadata.trackNumber ?? 0,
        discNumber: metadata.discNumber ?? 1,
      );
      add(_DownloaderMetadataUpdated(song));
    } catch (_) {
      add(_DownloaderMetadataUpdated(Song(
        path: filePath, 
        title: filePath.split('/').last,
        dateModified: DateTime.now(),
      )));
    }
  }

  void _onMetadataUpdated(_DownloaderMetadataUpdated event, Emitter<DownloaderState> emit) {
    final newList = List<Song>.from(state.downloadedSongs);
    // Avoid duplicates if yt-dlp emits multiple finished for same file
    if (!newList.any((s) => s.path == event.song.path)) {
      newList.insert(0, event.song);
    } else {
      final index = newList.indexWhere((s) => s.path == event.song.path);
      newList[index] = event.song;
    }
    emit(state.copyWith(downloadedSongs: newList));
  }

  void _onSuccess(_DownloaderSuccess event, Emitter<DownloaderState> emit) {
    emit(state.copyWith(status: DownloaderStatus.success, progress: 1.0, downloadStatus: 'All downloads complete!'));
  }

  void _onFailure(_DownloaderFailure event, Emitter<DownloaderState> emit) {
    emit(state.copyWith(status: DownloaderStatus.failure, error: event.error));
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
