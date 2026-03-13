import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:muses/features/library/bloc/playlists_bloc.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/library/widgets/edit_metadata_dialog.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  const SongOptionsBottomSheet({
    super.key,
    required this.song,
    this.playlistId,
    this.inQueue = false,
    this.queueIndex,
  });

  final Song song;
  final String? playlistId;
  final bool inQueue;
  final int? queueIndex;

  static Future<void> show(
    BuildContext context, {
    required Song song,
    String? playlistId,
    bool inQueue = false,
    int? queueIndex,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SongOptionsBottomSheet(
        song: song,
        playlistId: playlistId,
        inQueue: inQueue,
        queueIndex: queueIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                song.title ?? 'Unknown Title',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.playlist_add_circle_outlined),
              title: const Text('Play Next'),
              onTap: () {
                if (inQueue && queueIndex != null) {
                   context.read<PlayerBloc>().add(PlayerPlayNext(queueIndex!));
                } else {
                   context.read<PlayerBloc>().add(PlayerAddNext(song));
                }
                Navigator.pop(context);
              },
            ),
            if (!inQueue)
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Queue'),
                onTap: () {
                  context.read<PlayerBloc>().add(PlayerAddToEnd(song));
                  Navigator.pop(context);
                },
              ),
            if (inQueue && queueIndex != null) ...[
              ListTile(
                leading: const Icon(Icons.control_point_duplicate),
                title: const Text('Duplicate'),
                onTap: () {
                  context.read<PlayerBloc>().add(PlayerDuplicateInQueue(queueIndex!));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Remove from Queue'),
                onTap: () {
                  context.read<PlayerBloc>().add(PlayerRemoveFromQueue(queueIndex!));
                  Navigator.pop(context);
                },
              ),
            ],
            if (!inQueue)
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Edit Metadata'),
                onTap: () async {
                  // Close sheet first
                  Navigator.pop(context);
                  
                  final updatedSong = await showDialog<Song>(
                    context: context,
                    builder: (context) => EditMetadataDialog(song: song),
                  );
                  if (updatedSong != null && context.mounted) {
                    context.read<LibraryBloc>().add(UpdateSong(updatedSong));
                  }
                },
              ),
            if (playlistId != null)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Remove from Playlist'),
                onTap: () {
                  context.read<PlaylistsBloc>().add(RemoveSongFromPlaylist(
                        playlistId: playlistId!,
                        songPath: song.path,
                      ));
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Add to Playlist',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            BlocBuilder<PlaylistsBloc, PlaylistsState>(
              builder: (context, state) {
                return Column(
                  children: state.playlists.map((p) {
                    return ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: Text(p.name),
                      onTap: () {
                        context.read<PlaylistsBloc>().add(AddSongsToPlaylist(
                              playlistId: p.id,
                              songPaths: [song.path],
                            ));
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
