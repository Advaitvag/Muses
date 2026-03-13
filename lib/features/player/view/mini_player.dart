import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:muses/features/library/widgets/album_art.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.currentSong != current.currentSong ||
          previous.queue.isNotEmpty != current.queue.isNotEmpty,
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 72,
                      child: Row(
                        children: [
                          Hero(
                            tag: 'artwork_${song.path}',
                            child: AlbumArt(
                              artwork: song.artwork,
                              path: song.path,
                              hasArtwork: song.hasArtwork == true,
                              size: 72,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  song.title ?? 'Unknown',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist ?? 'Unknown',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const _MiniPlayerControls(),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    BlocBuilder<PlayerBloc, PlayerState>(
                      buildWhen: (previous, current) =>
                          previous.position != current.position ||
                          previous.duration != current.duration,
                      builder: (context, state) {
                        final colorScheme = Theme.of(context).colorScheme;
                        
                        return SizedBox(
                          height: 4,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 0),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 0),
                              trackShape: const RectangularSliderTrackShape(),
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.4),
                            ),
                            child: Slider(
                              value: state.position.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0,
                                      state.duration.inMilliseconds.toDouble()),
                              min: 0.0,
                              max: state.duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                context.read<PlayerBloc>().add(
                                      PlayerSeek(
                                          Duration(milliseconds: value.toInt())),
                                    );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerControls extends StatelessWidget {
  const _MiniPlayerControls();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.repeatMode != current.repeatMode ||
          previous.shuffleMode != current.shuffleMode,
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.shuffle, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: state.shuffleMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                foregroundColor: state.shuffleMode
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerToggleShuffle());
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerPrevious());
              },
            ),
            IconButton(
              icon: Icon(
                state.status == PlayerStatus.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              onPressed: () {
                if (state.status == PlayerStatus.playing) {
                  context.read<PlayerBloc>().add(PlayerPause());
                } else {
                  context.read<PlayerBloc>().add(PlayerResume());
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerNext());
              },
            ),
            IconButton(
              icon: Icon(
                state.repeatMode == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: state.repeatMode != LoopMode.off
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                foregroundColor: state.repeatMode != LoopMode.off
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerToggleRepeat());
              },
            ),
          ],
        );
      },
    );
  }
}
