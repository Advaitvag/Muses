import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as ye;

class DownloadUpdate {
  final double progress;
  final String status;
  final String? title;
  final String? filePath;
  final bool isFinished;

  DownloadUpdate({
    required this.progress,
    required this.status,
    this.title,
    this.filePath,
    this.isFinished = false,
  });
}

class DownloadService {
  final ye.YoutubeExplode _yt = ye.YoutubeExplode();

  Future<bool> isYtDlpAvailable() async {
    try {
      final result = await Process.run('yt-dlp', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Stream<DownloadUpdate> downloadMusic(String url, String outputDir) async* {
    final hasYtDlp = await isYtDlpAvailable();
    
    if (hasYtDlp) {
      yield DownloadUpdate(progress: 0.0, status: 'Starting yt-dlp...');
      
      // Use yt-dlp for downloading and converting to m4a
      // --extract-audio --audio-format m4a
      // --add-metadata --embed-thumbnail
      final process = await Process.start('yt-dlp', [
        '-x',
        '--audio-format', 'm4a',
        '--add-metadata',
        '--embed-thumbnail',
        '--newline',
        '--progress-template', 'download:[download] %(progress)s  %(info.title)s',
        '-o', p.join(outputDir, '%(title)s.%(ext)s'),
        '--print', 'after_move:filepath:%(filepath)s',
        '--print', 'after_move:title:%(title)s',
        url,
      ]);

      final StreamController<DownloadUpdate> controller = StreamController();

      process.stdout.transform(SystemEncoding().decoder).transform(const LineSplitter()).listen((line) {
        if (line.startsWith('download:[download]')) {
          final parts = line.split(' ');
          if (parts.length >= 3) {
            final progressStr = parts[1].replaceAll('%', '');
            final progress = (double.tryParse(progressStr) ?? 0.0) / 100.0;
            final title = parts.sublist(2).join(' ').trim();
            controller.add(DownloadUpdate(
              progress: progress,
              status: 'Downloading...',
              title: title,
            ));
          }
        } else if (line.startsWith('filepath:')) {
          final path = line.substring(9).trim();
          controller.add(DownloadUpdate(
            progress: 1.0,
            status: 'Finished',
            filePath: path,
            isFinished: true,
          ));
        } else if (line.startsWith('title:')) {
           // Can be used if needed
        } else if (line.contains('[ExtractAudio]')) {
          controller.add(DownloadUpdate(progress: 1.0, status: 'Finalizing M4A...'));
        }
      });

      process.stderr.transform(SystemEncoding().decoder).listen((data) {
        // Log errors
      });

      process.exitCode.then((exitCode) {
        if (exitCode != 0) {
          controller.addError(Exception('yt-dlp failed with exit code $exitCode'));
        }
        controller.close();
      });
      
      yield* controller.stream;
    } else {
      // Fallback to youtube_explode_dart
      yield DownloadUpdate(progress: 0.0, status: 'yt-dlp not found, using fallback...');
      
      if (url.contains('playlist?list=')) {
         final playlist = await _yt.playlists.get(url);
         yield DownloadUpdate(progress: 0.0, status: 'Downloading playlist: ${playlist.title}');
         
         await for (final video in _yt.playlists.getVideos(playlist.id.value)) {
            yield* _downloadSingleVideoFallback(video.url, outputDir, video.title);
         }
      } else {
         yield* _downloadSingleVideoFallback(url, outputDir);
      }
    }
  }

  Stream<DownloadUpdate> _downloadSingleVideoFallback(String url, String outputDir, [String? title]) async* {
      final video = await _yt.videos.get(url);
      final displayTitle = title ?? video.title;
      yield DownloadUpdate(progress: 0.0, status: 'Fetching manifest...', title: displayTitle);
      
      final manifest = await _yt.videos.streamsClient.getManifest(url);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      final fileName = '${video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.m4a';
      final filePath = p.join(outputDir, fileName);
      final file = File(filePath);
      if (file.existsSync()) await file.delete();
      
      final output = file.openWrite();
      final stream = _yt.videos.streamsClient.get(audioStream);
      
      final totalSize = audioStream.size.totalBytes;
      int downloaded = 0;
      
      await for (final data in stream) {
        downloaded += data.length;
        output.add(data);
        final progress = downloaded / totalSize;
        yield DownloadUpdate(
          progress: progress, 
          status: 'Downloading: ${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB / ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
          title: displayTitle,
        );
      }
      
      await output.close();
      yield DownloadUpdate(
        progress: 1.0, 
        status: 'Download complete', 
        title: displayTitle,
        filePath: filePath,
        isFinished: true,
      );
  }

  void dispose() {
    _yt.close();
  }
}

