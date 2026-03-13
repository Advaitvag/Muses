import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:muses/core/utils/artwork_manager.dart';
import 'package:muses/features/library/widgets/album_art.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/settings/bloc/shortcuts_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';
import 'package:muses/main.dart';
import 'package:window_manager/window_manager.dart';

class TrayPlayer extends StatelessWidget {
  const TrayPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final shortcutsBloc = context.read<ShortcutsBloc>();
          final shortcutsState = shortcutsBloc.state;

          if (shortcutsState.isRecording) return;

          final shortcuts = shortcutsState.shortcuts;
          final playerBloc = context.read<PlayerBloc>();
          final state = playerBloc.state;

          bool matches(ShortcutAction action) =>
              shortcuts[action]?.matches(event) ?? false;

          if (matches(ShortcutAction.playPause)) {
            if (state.status == PlayerStatus.playing) {
              playerBloc.add(PlayerPause());
            } else {
              playerBloc.add(PlayerResume());
            }
          } else if (matches(ShortcutAction.next)) {
            playerBloc.add(PlayerNext());
          } else if (matches(ShortcutAction.previous)) {
            playerBloc.add(PlayerPrevious());
          } else if (matches(ShortcutAction.shuffle)) {
            playerBloc.add(PlayerToggleShuffle());
          } else if (matches(ShortcutAction.repeat)) {
            playerBloc.add(PlayerToggleRepeat());
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<PlayerBloc, PlayerState>(
          buildWhen: (previous, current) =>
              previous.currentSong?.path != current.currentSong?.path ||
              previous.status != current.status,
          builder: (context, state) {
            final song = state.currentSong;
            if (song == null) {
              return _buildEmptyState(context);
            }

            return Stack(
              children: [
                // Blurred Background
                if (song.artwork != null)
                  Positioned.fill(
                    child: Image.memory(
                      song.artwork!,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (song.hasArtwork == true)
                  Positioned.fill(
                    child: FutureBuilder<File?>(
                      future: ArtworkManager().getArtworkFile(song.path),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: context.read<ThemeBloc>().state.blurSigma,
                      sigmaY: context.read<ThemeBloc>().state.blurSigma,
                    ),
                    child: Container(
                      color:
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        if (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS)
                          const _TrayHeader(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Artwork
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: AlbumArt(
                                      artwork: song.artwork,
                                      path: song.path,
                                      hasArtwork: song.hasArtwork == true,
                                      borderRadius: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Info
                                Text(
                                  song.title ?? 'Unknown Title',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist ?? 'Unknown Artist',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                // Progress
                                const _TrayProgressBar(),
                                const SizedBox(height: 12),
                                // Controls
                                const _TrayControls(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No music playing',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrayHeader extends StatelessWidget {
  const _TrayHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset('assets/muses_logo.jpg', width: 16, height: 16),
          const SizedBox(width: 8),
          Text(
            'Muses',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.open_in_full_rounded, size: 16),
            tooltip: 'Open Full Player',
            onPressed: () {
              musesAppKey.currentState?.showFullApp();
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, size: 16),
            tooltip: 'Exit',
            onPressed: () => windowManager.destroy(),
          ),
          const SizedBox(width: 4),
          const VerticalDivider(indent: 12, endIndent: 12, width: 1),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            tooltip: 'Hide',
            onPressed: () => windowManager.hide(),
          ),
        ],
      ),
    );
  }
}

class _TrayProgressBar extends StatelessWidget {
  const _TrayProgressBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.position != current.position ||
          previous.duration != current.duration,
      builder: (context, state) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            trackShape: const RectangularSliderTrackShape(),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        );
      },
    );
  }
}

class _TrayControls extends StatelessWidget {
  const _TrayControls();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.shuffleMode != current.shuffleMode ||
          previous.repeatMode != current.repeatMode,
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                state.shuffleMode ? Icons.shuffle : Icons.shuffle_outlined,
                size: 18,
              ),
              color: state.shuffleMode ? colorScheme.primary : colorScheme.onSurfaceVariant,
              onPressed: () => context.read<PlayerBloc>().add(PlayerToggleShuffle()),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 28,
                  onPressed: () => context.read<PlayerBloc>().add(PlayerPrevious()),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                  child: IconButton(
                    icon: Icon(
                      state.status == PlayerStatus.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    iconSize: 28,
                    color: colorScheme.onPrimary,
                    onPressed: () {
                      if (state.status == PlayerStatus.playing) {
                        context.read<PlayerBloc>().add(PlayerPause());
                      } else {
                        context.read<PlayerBloc>().add(PlayerResume());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 28,
                  onPressed: () => context.read<PlayerBloc>().add(PlayerNext()),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                state.repeatMode == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: 18,
              ),
              color: state.repeatMode != LoopMode.off ? colorScheme.primary : colorScheme.onSurfaceVariant,
              onPressed: () => context.read<PlayerBloc>().add(PlayerToggleRepeat()),
            ),
          ],
        );
      },
    );
  }
}