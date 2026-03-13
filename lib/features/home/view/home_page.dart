import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muses/core/utils/artwork_manager.dart';
import 'package:muses/core/widgets/window_controls.dart';
import 'package:muses/features/library/models/song.dart';
import 'package:muses/features/library/view/library_page.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/player/view/mini_player.dart';
import 'package:muses/features/settings/bloc/shortcuts_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomePage> createState() => _HomePageState();
}

class PageOffsetProvider extends InheritedWidget {
  const PageOffsetProvider({
    super.key,
    required this.pageOffset,
    required super.child,
  });

  final ValueNotifier<double> pageOffset;

  static ValueNotifier<double>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageOffsetProvider>()
        ?.pageOffset;
  }

  @override
  bool updateShouldNotify(PageOffsetProvider oldWidget) {
    return pageOffset != oldWidget.pageOffset;
  }
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<double> _pageOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _pageOffset.value = widget.navigationShell.currentIndex.toDouble();
    _requestPermissions();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _pageOffset.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != oldWidget.navigationShell.currentIndex) {
      // If animations are disabled, we should update the offset immediately
      final animationsEnabled = context.read<ThemeBloc>().state.animationsEnabled;
      if (!animationsEnabled) {
        _pageOffset.value = widget.navigationShell.currentIndex.toDouble();
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.status.isDenied) {
        await Permission.audio.request();
      }
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  Future<void> _updatePalette(Song? song) async {
    if (song == null) return;
    try {
      ImageProvider? imageProvider;
      if (song.artwork != null) {
        imageProvider = MemoryImage(song.artwork!);
      } else if (song.hasArtwork == true) {
        final file = await ArtworkManager().getArtworkFile(song.path);
        if (file != null) {
          imageProvider = FileImage(file);
        }
      }

      if (imageProvider == null) return;

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5,
      );
      if (mounted) {
        final color =
            paletteGenerator.dominantColor?.color ??
            paletteGenerator.vibrantColor?.color ??
            paletteGenerator.mutedColor?.color;

        context.read<ThemeBloc>().add(ThemeSourceColorChanged(color));
      }
    } catch (e) {
      developer.log('Error generating palette', error: e, name: 'HomePage');
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final shortcutsBloc = context.read<ShortcutsBloc>();
    final shortcutsState = shortcutsBloc.state;
    if (shortcutsState.isRecording) return false;

    final shortcuts = shortcutsState.shortcuts;
    final playerBloc = context.read<PlayerBloc>();
    final playerState = playerBloc.state;

    bool matches(ShortcutAction action) =>
        shortcuts[action]?.matches(event) ?? false;

    // Exception for 'back' shortcut: Allow it even if focused on a text field (to exit search)
    final isBackMatch = matches(ShortcutAction.back);

    // Don't trigger other shortcuts if user is typing in any text field
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null && !isBackMatch) {
      final widgetType = primaryFocus.context!.widget;
      if (widgetType is EditableText || 
          primaryFocus.context!.findAncestorWidgetOfExactType<TextField>() != null) {
        return false;
      }
    }

    if (matches(ShortcutAction.playPause)) {
      if (playerState.status == PlayerStatus.playing) {
        playerBloc.add(PlayerPause());
      } else {
        playerBloc.add(PlayerResume());
      }
      return true;
    } else if (matches(ShortcutAction.next)) {
      playerBloc.add(PlayerNext());
      return true;
    } else if (matches(ShortcutAction.previous)) {
      playerBloc.add(PlayerPrevious());
      return true;
    } else if (matches(ShortcutAction.shuffle)) {
      playerBloc.add(PlayerToggleShuffle());
      return true;
    } else if (matches(ShortcutAction.repeat)) {
      playerBloc.add(PlayerToggleRepeat());
      return true;
    } else if (matches(ShortcutAction.nextTab)) {
      final nextIndex = (widget.navigationShell.currentIndex + 1) % 5;
      _onTap(context, nextIndex);
      return true;
    } else if (matches(ShortcutAction.previousTab)) {
      final prevIndex = (widget.navigationShell.currentIndex - 1 + 5) % 5;
      _onTap(context, prevIndex);
      return true;
    } else if (matches(ShortcutAction.back)) {
      final libState = LibraryPage.globalKey.currentState;
      if (libState != null &&
          libState.canGoBack &&
          widget.navigationShell.currentIndex == 2) {
        libState.goBack();
        return true;
      } else {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.maybePop();
          return true;
        }
      }
    } else if (matches(ShortcutAction.search)) {
      _onTap(context, 2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LibraryPage.globalKey.currentState?.enterSearch();
      });
      return true;
    }

    return false;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (previous, current) =>
          previous.currentSong?.path != current.currentSong?.path,
      listener: (context, state) {
        if (context.read<ThemeBloc>().state.useDynamicColor) {
          _updatePalette(state.currentSong);
        }
      },
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<PlayerBloc, PlayerState>(
            buildWhen: (previous, current) =>
                previous.currentSong?.path != current.currentSong?.path,
            builder: (context, playerState) {
              final song = playerState.currentSong;
              final isBottomNav =
                  themeState.navigationBarPosition ==
                  NavigationBarPosition.bottom;

              Widget buildNavBar({bool transparent = false, double? height}) {
                final navBar = NavigationBar(
                  height: height,
                  backgroundColor: transparent
                      ? Colors.transparent
                      : (themeState.showAlbumArtBackground
                          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
                          : null),
                  elevation: 0,
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (int index) => _onTap(context, index),
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.play_circle_outline),
                      selectedIcon: Icon(Icons.play_circle_filled),
                      label: 'Player',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.queue_music_outlined),
                      selectedIcon: Icon(Icons.queue_music),
                      label: 'Queue',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: 'Library',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.download_outlined),
                      selectedIcon: Icon(Icons.download),
                      label: 'Downloader',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                );

                if (transparent) return navBar;

                return ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: navBar,
                  ),
                );
              }

              Widget? backgroundArt;
              if (themeState.showAlbumArtBackground && song != null) {
                 if (song.artwork != null) {
                    backgroundArt = Image.memory(
                      song.artwork!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                 } else if (song.hasArtwork == true) {
                    backgroundArt = FutureBuilder<File?>(
                      future: ArtworkManager().getArtworkFile(song.path),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                 }
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(
                  Platform.isWindows || Platform.isLinux || Platform.isMacOS
                      ? 8
                      : 0,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: themeState.opacity),
                      ),
                    ),
                    if (backgroundArt != null)
                      Positioned.fill(
                        child: backgroundArt,
                      ),
                    if (backgroundArt != null)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: themeState.blurSigma,
                            sigmaY: themeState.blurSigma,
                          ),
                          child: Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),

                    PopScope(
                      canPop: widget.navigationShell.currentIndex == 0 &&
                          !(widget.navigationShell.currentIndex == 2 &&
                              (LibraryPage.globalKey.currentState?.canGoBack ??
                                  false)),
                      onPopInvokedWithResult: (didPop, result) {
                        if (didPop) return;

                        // Case 1: In Library branch and it has its own back stack
                        if (widget.navigationShell.currentIndex == 2) {
                          final libState = LibraryPage.globalKey.currentState;
                          if (libState != null && libState.canGoBack) {
                            libState.goBack();
                            return;
                          }
                        }

                        // Case 2: Not on Player page, go to Player page (index 0)
                        if (widget.navigationShell.currentIndex != 0) {
                          _onTap(context, 0);
                        }
                      },
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Column(
                        children: [
                          if (!isBottomNav)
                            ClipRect(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  color: themeState.showAlbumArtBackground
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.5)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (Platform.isWindows ||
                                          Platform.isLinux ||
                                          Platform.isMacOS)
                                        const WindowControls()
                                      else
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                              .padding
                                              .top,
                                        ),
                                      MediaQuery.removePadding(
                                        context: context,
                                        removeBottom: true,
                                        removeTop: true,
                                        child: buildNavBar(
                                          transparent: true,
                                          height: 65,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (Platform.isWindows ||
                              Platform.isLinux ||
                              Platform.isMacOS)
                            const WindowControls(),
                          Expanded(
                            child: MediaQuery.removePadding(
                              context: context,
                              removeTop: !isBottomNav,
                              child: PageOffsetProvider(
                                pageOffset: _pageOffset,
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification.metrics is PageMetrics) {
                                      final metrics =
                                          notification.metrics as PageMetrics;
                                      _pageOffset.value = metrics.page ?? 0;
                                    }
                                    return false;
                                  },
                                  child: widget.navigationShell,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      bottomNavigationBar: isBottomNav ? buildNavBar() : null,
                    ),
                  ),
                    ValueListenableBuilder<double>(
                      valueListenable: _pageOffset,
                      builder: (context, page, child) {
                        final progress = page.clamp(0.0, 1.0);
                        if (progress == 0) return const SizedBox.shrink();

                        return Positioned(
                          left: 0,
                          right: 0,
                          bottom: isBottomNav
                              ? 80 + MediaQuery.of(context).padding.bottom
                              : MediaQuery.of(context).padding.bottom,
                          child: FractionalTranslation(
                            translation: Offset(0, 1.0 - progress),
                            child: Opacity(
                              opacity: progress,
                              child: IgnorePointer(
                                ignoring: progress < 0.5,
                                child: MiniPlayer(
                                  onTap: () {
                                    _onTap(context, 0);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == 1) {
      context.read<PlayerBloc>().add(PlayerQueueEntered());
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
