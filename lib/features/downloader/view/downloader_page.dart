import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/downloader/bloc/downloader_bloc.dart';
import 'package:muses/features/downloader/services/download_service.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/library/widgets/album_art.dart';
import 'package:muses/features/library/widgets/edit_metadata_dialog.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/settings/bloc/folders_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';

class DownloaderPage extends StatelessWidget {
  const DownloaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloaderBloc(
        downloadService: DownloadService(),
        foldersBloc: context.read<FoldersBloc>(),
      ),
      child: const DownloaderView(),
    );
  }
}

class DownloaderView extends StatefulWidget {
  const DownloaderView({super.key});

  @override
  State<DownloaderView> createState() => _DownloaderViewState();
}

class _DownloaderViewState extends State<DownloaderView> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder(BuildContext context) async {
    final bloc = context.read<DownloaderBloc>();
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
      bloc.add(DownloaderPathChanged(result));
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _urlController.text = data!.text!;
      context.read<DownloaderBloc>().add(DownloaderUrlChanged(data.text!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isTopNav = context.read<ThemeBloc>().state.navigationBarPosition ==
        NavigationBarPosition.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Downloader'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isTopNav ? 48 : null,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to your collection',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paste a YouTube link to download high-quality audio',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Main Input Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'https://www.youtube.com/...',
                            labelText: 'Video or Playlist URL',
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.link_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_paste_rounded),
                              onPressed: _pasteFromClipboard,
                            ),
                          ),
                          onChanged: (value) {
                            context
                                .read<DownloaderBloc>()
                                .add(DownloaderUrlChanged(value));
                          },
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _pickFolder(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.folder_open_rounded, size: 20, color: colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Save location', style: theme.textTheme.labelSmall),
                                        BlocBuilder<DownloaderBloc, DownloaderState>(
                                          builder: (context, state) {
                                            return Text(
                                              state.downloadPath.isEmpty ? 'Default Music Folder' : state.downloadPath,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        BlocBuilder<DownloaderBloc, DownloaderState>(
                          builder: (context, state) {
                            final isDownloading =
                                state.status == DownloaderStatus.downloading ||
                                    state.status == DownloaderStatus.loading;

                            return FilledButton.icon(
                              onPressed: state.url.isEmpty || isDownloading
                                  ? null
                                  : () {
                                      context
                                          .read<DownloaderBloc>()
                                          .add(const DownloaderStart());
                                    },
                              icon: isDownloading 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.download_rounded),
                              label: Text(
                                  isDownloading ? 'Processing...' : 'Download Now'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Active Progress Section
                  BlocBuilder<DownloaderBloc, DownloaderState>(
                    builder: (context, state) {
                      if (state.status == DownloaderStatus.initial &&
                          state.downloadedSongs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      if (state.status == DownloaderStatus.initial) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    state.downloadStatus,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(state.progress * 100).toInt()}%',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: state.progress,
                              borderRadius: BorderRadius.circular(8),
                              minHeight: 6,
                              backgroundColor: colorScheme.surface,
                            ),
                            if (state.status == DownloaderStatus.failure) ...[
                              const SizedBox(height: 12),
                              Text(
                                state.error ?? 'Something went wrong',
                                style: TextStyle(color: colorScheme.error, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  
                  if (context.watch<DownloaderBloc>().state.downloadedSongs.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Downloads',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          BlocBuilder<DownloaderBloc, DownloaderState>(
            builder: (context, state) {
              if (state.downloadedSongs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_download_outlined, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text(
                          'Your downloads will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = state.downloadedSongs[index];
                      return _DownloadedSongTile(song: song);
                    },
                    childCount: state.downloadedSongs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }
}

class _DownloadedSongTile extends StatelessWidget {
  const _DownloadedSongTile({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          leading: Hero(
            tag: 'downloader_art_${song.path}',
            child: AlbumArt(
              path: song.path,
              hasArtwork: song.hasArtwork == true,
              size: 56,
              borderRadius: 12,
            ),
          ),
          title: Text(
            song.title ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              song.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                onPressed: () async {
                  final updated = await showDialog<Song>(
                    context: context,
                    builder: (context) => EditMetadataDialog(song: song),
                  );
                  if (updated != null && context.mounted) {
                    context.read<LibraryBloc>().add(UpdateSong(updated));
                  }
                },
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                onPressed: () {
                  context.read<PlayerBloc>().add(PlayerPlay(song));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

