import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/library/widgets/album_art.dart';
import 'package:muses/features/library/widgets/song_options_bottom_sheet.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Schedule a scroll to the current index after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentIndex();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentIndex() {
    final state = context.read<PlayerBloc>().state;
    if (state.effectiveQueue.isNotEmpty &&
        state.currentIndex < state.effectiveQueue.length &&
        _scrollController.hasClients) {
      // Approximate item height (ListTile + Padding)
      const itemHeight = 72.0;
      final offset =
          (state.currentIndex * itemHeight) -
          (MediaQuery.of(context).size.height / 3);
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTopNav = context.read<ThemeBloc>().state.navigationBarPosition ==
        NavigationBarPosition.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Queue'),
        backgroundColor: Colors.transparent,
        toolbarHeight: isTopNav ? 48 : null,
        scrolledUnderElevation: 0,
      ),
      body: BlocListener<PlayerBloc, PlayerState>(
        listenWhen: (previous, current) =>
            previous.queueScrollId != current.queueScrollId,
        listener: (context, state) {
          _scrollToCurrentIndex();
        },
        child: BlocBuilder<PlayerBloc, PlayerState>(
          buildWhen: (previous, current) =>
              previous.effectiveQueue != current.effectiveQueue ||
              previous.currentIndex != current.currentIndex ||
              previous.shuffleMode != current.shuffleMode,
          builder: (context, state) {
            final queue = state.effectiveQueue;
            if (queue.isEmpty) {
              return const Center(child: Text('Queue is empty'));
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 140),
              buildDefaultDragHandles: false,
              scrollController: _scrollController,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                context.read<PlayerBloc>().add(
                  PlayerMoveQueueItem(oldIndex: oldIndex, newIndex: newIndex),
                );
              },
              itemCount: queue.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Material(
                      elevation: 8,
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final song = queue[index];
                final isCurrent = index == state.currentIndex;

                return Padding(
                  key: ValueKey('${song.path}_$index'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: Stack(
                    children: [
                      if (isCurrent)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        selected: isCurrent,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: AlbumArt(
                          artwork: song.artwork,
                          path: song.path,
                          hasArtwork: song.hasArtwork == true,
                          size: 48,
                          borderRadius: 8,
                        ),
                        title: Text(
                          song.title ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          song.artist ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                SongOptionsBottomSheet.show(
                                  context,
                                  song: song,
                                  inQueue: true,
                                  queueIndex: index,
                                );
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.read<PlayerBloc>().add(PlayerPlay(song));
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
