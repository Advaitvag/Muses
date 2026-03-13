import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:muses/features/home/view/home_page.dart';
import 'package:muses/features/library/widgets/album_art.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.currentSong != current.currentSong,
      builder: (context, state) {
        final song = state.currentSong;
        final artwork = song?.artwork;

    final isTopNav = context.read<ThemeBloc>().state.navigationBarPosition ==
        NavigationBarPosition.top;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Now Playing'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: isTopNav ? 48 : null,
            scrolledUnderElevation: 0,
          ),
          body: song == null
              ? const Center(child: Text('No music playing'))
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        // Artwork
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: ValueListenableBuilder<double>(
                              valueListenable: PageOffsetProvider.of(context) ??
                                  ValueNotifier(0.0),
                              builder: (context, page, child) {
                                final progress = page.clamp(0.0, 1.0);
                                final scale = 1.0 - (progress * 0.2);
                                final opacity = 1.0 - (progress * 0.5);

                                return Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Hero(
                                        tag: 'artwork_${song.path}',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                    alpha: 0.3),
                                                blurRadius: 30,
                                                offset: const Offset(0, 15),
                                              ),
                                            ],
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                          child: AlbumArt(
                                            artwork: artwork,
                                            path: song.path,
                                            hasArtwork: song.hasArtwork == true,
                                            borderRadius: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                        // Info
                        Text(
                          song.title ?? 'Unknown Title',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist ?? 'Unknown Artist',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(flex: 1),
                        const _ProgressBar(),
                        const SizedBox(height: 24),
                        const _PlayerControls(),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.position != current.position ||
          previous.duration != current.duration,
      builder: (context, state) {
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: state.position.inMilliseconds.toDouble().clamp(
                      0.0,
                      state.duration.inMilliseconds.toDouble(),
                    ),
                min: 0.0,
                max: state.duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  context.read<PlayerBloc>().add(
                        PlayerSeek(Duration(milliseconds: value.toInt())),
                      );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(state.position),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    _formatDuration(state.duration),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.shuffleMode != current.shuffleMode ||
          previous.repeatMode != current.repeatMode,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.shuffle),
              style: IconButton.styleFrom(
                backgroundColor: state.shuffleMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                foregroundColor: state.shuffleMode
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerToggleShuffle());
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 42,
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerPrevious());
              },
            ),
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  state.status == PlayerStatus.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                iconSize: 42,
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  if (state.status == PlayerStatus.playing) {
                    context.read<PlayerBloc>().add(PlayerPause());
                  } else {
                    context.read<PlayerBloc>().add(PlayerResume());
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 42,
              onPressed: () {
                context.read<PlayerBloc>().add(PlayerNext());
              },
            ),
            IconButton(
              icon: Icon(state.repeatMode == LoopMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded),
              style: IconButton.styleFrom(
                backgroundColor: state.repeatMode != LoopMode.off
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                foregroundColor: state.repeatMode != LoopMode.off
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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