import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:audio_service/audio_service.dart';

import 'package:metadata_god/metadata_god.dart';
import 'package:muses/core/di.dart';
import 'package:muses/core/router.dart';
import 'package:muses/core/audio/audio_handler.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:muses/features/library/bloc/playlists_bloc.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/player/services/music_player.dart';
import 'package:muses/features/settings/bloc/folders_bloc.dart';
import 'package:muses/features/settings/bloc/shortcuts_bloc.dart';
import 'package:muses/features/settings/bloc/audio_settings_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

final GlobalKey<MusesAppState> musesAppKey = GlobalKey<MusesAppState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize storage first to get settings
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationSupportDirectory(),
  );

  final themeBloc = ThemeBloc();
  final bool startInTray = themeBloc.state.startInTray;
  final bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  if (isDesktop) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(450, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(450, 600));
      if (Platform.isLinux) {
        final String exePath = Platform.resolvedExecutable;
        final String exeDir = p.dirname(exePath);
        String iconPath = p.join(exeDir, 'data', 'app_icon.png');
        
        if (!File(iconPath).existsSync()) {
          iconPath = p.join(exeDir, 'data', 'flutter_assets', 'assets', 'muses_logo.png');
        }
        
        if (File(iconPath).existsSync()) {
          try {
            await windowManager.setIcon(iconPath);
          } catch (e) {
            debugPrint('Failed to set window icon: $e');
          }
        }
      }
      if (startInTray) {
        await windowManager.hide();
      }
    });

    await windowManager.setPreventClose(true);
  }

  JustAudioMediaKit.ensureInitialized();
  JustAudioMediaKit.mpvLogLevel = MPVLogLevel.error;

  MetadataGod.initialize();

  final audioPlayer = AudioPlayer();
  final audioHandler = await AudioService.init(
    builder: () => MusesAudioHandler(audioPlayer),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.muses.app.audio',
      androidNotificationChannelName: 'Muses Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Colors.deepPurple,
    ),
  );

  setupDI(themeBloc, audioHandler, audioPlayer);
  runApp(const MusesApp());
}

class MusesApp extends StatefulWidget {
  const MusesApp({super.key});

  @override
  State<MusesApp> createState() => MusesAppState();
}

class MusesAppState extends State<MusesApp> with WindowListener, TrayListener {
  late final ThemeBloc _themeBloc;
  bool _isTrayMode = false;
  final bool _isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    _themeBloc = getIt<ThemeBloc>();
    if (_isDesktop) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDesktop) {
        if (!_themeBloc.state.startInTray) {
          await windowManager.show();
          await windowManager.focus();
        }
      }
      FlutterNativeSplash.remove();
    });

    super.initState();
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initTray() async {
    if (!_isDesktop) return;
    await trayManager.setIcon('assets/tray_icon.jpg');
    await _updateTrayMenu();
  }

  Future<void> _updateTrayMenu() async {
    if (!_isDesktop) return;
    final playerBloc = getIt<PlayerBloc>();
    final state = playerBloc.state;
    final isPlaying = state.status == PlayerStatus.playing;
    final song = state.currentSong;
    final shuffle = state.shuffleMode;
    final repeat = state.repeatMode;

    String repeatLabel = 'Repeat: Off';
    if (repeat == LoopMode.all) repeatLabel = 'Repeat: All';
    if (repeat == LoopMode.one) repeatLabel = 'Repeat: One';

    final menu = Menu(
      items: [
        if (song != null) ...[
          MenuItem(
            key: 'song_info',
            label: '${song.title ?? 'Unknown'} - ${song.artist ?? 'Unknown'}',
            disabled: true,
          ),
          MenuItem.separator(),
        ],
        MenuItem(key: 'play_pause', label: isPlaying ? 'Pause' : 'Play'),
        MenuItem(key: 'next', label: 'Next'),
        MenuItem(key: 'previous', label: 'Previous'),
        MenuItem.separator(),
        MenuItem(
          key: 'toggle_shuffle',
          label: 'Shuffle: ${shuffle ? 'ON' : 'OFF'}',
        ),
        MenuItem(key: 'toggle_repeat', label: repeatLabel),
        MenuItem.separator(),
        MenuItem(key: 'show_window', label: 'Open Muses'),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() async {
    if (_isTrayMode) {
      await windowManager.hide();
      _isTrayMode = false;
    } else {
      await _showTrayPlayer();
    }
  }

  Future<void> _showTrayPlayer() async {
    _isTrayMode = true;
    router.go('/tray');

    const windowSize = Size(320, 480);

    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSize(windowSize);

    // Attempt to position near the tray icon
    try {
      final trayRect = await trayManager.getBounds();
      if (trayRect != null) {
        // Heuristic to position above or below the tray icon based on screen position
        double x =
            trayRect.left + (trayRect.width / 2) - (windowSize.width / 2);
        double y = trayRect.top;

        // If the tray is at the bottom of the screen (common)
        if (y > 500) {
          y = trayRect.top - windowSize.height - 10;
        } else {
          y = trayRect.bottom + 10;
        }

        await windowManager.setPosition(Offset(x, y));
      }
    } catch (e) {
      // Fallback to center if bounds detection fails
      await windowManager.center();
    }

    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> showFullApp() async {
    _isTrayMode = false;
    router.go('/player');
    await windowManager.setSkipTaskbar(false);
    await windowManager.setSize(const Size(1280, 720));
    await windowManager.setResizable(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowBlur() {
    // Automatically hide the tray player when clicking outside of it
    if (_isTrayMode) {
      windowManager.hide();
      _isTrayMode = false;
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final playerBloc = getIt<PlayerBloc>();

    if (menuItem.key == 'show_window') {
      showFullApp();
    } else if (menuItem.key == 'exit_app') {
      _exitApp();
    } else if (menuItem.key == 'play_pause') {
      final state = playerBloc.state;
      if (state.status == PlayerStatus.playing) {
        playerBloc.add(PlayerPause());
      } else {
        playerBloc.add(PlayerResume());
      }
    } else if (menuItem.key == 'next') {
      playerBloc.add(PlayerNext());
    } else if (menuItem.key == 'previous') {
      playerBloc.add(PlayerPrevious());
    } else if (menuItem.key == 'toggle_shuffle') {
      playerBloc.add(PlayerToggleShuffle());
    } else if (menuItem.key == 'toggle_repeat') {
      playerBloc.add(PlayerToggleRepeat());
    }
  }

  Future<void> _exitApp() async {
    await windowManager.hide();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    if (_themeBloc.state.closeToTray) {
      windowManager.hide();
      _isTrayMode = false;
    } else {
      _exitApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      key: musesAppKey,
      providers: [
        BlocProvider.value(value: _themeBloc),
        BlocProvider.value(value: getIt<ShortcutsBloc>()),
        BlocProvider.value(value: getIt<AudioSettingsBloc>()),
        BlocProvider.value(value: getIt<FoldersBloc>()),
        BlocProvider.value(value: getIt<LibraryBloc>()),
        BlocProvider.value(value: getIt<PlaylistsBloc>()),
        BlocProvider.value(value: getIt<PlayerBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AudioSettingsBloc, AudioSettingsState>(
            listener: (context, state) {
              final player = getIt<MusicPlayer>();
              player.setVolume(state.volume);
              player.setEqualizerBands(state.equalizerBands);
              player.setNormalization(state.isNormalizationEnabled);
              player.setGaplessPlayback(state.gaplessPlayback);
            },
          ),
          BlocListener<PlayerBloc, PlayerState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.currentSong?.path != current.currentSong?.path ||
                previous.shuffleMode != current.shuffleMode ||
                previous.repeatMode != current.repeatMode,
            listener: (context, state) {
              if (_isDesktop) {
                _updateTrayMenu();
              }
            },
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            ThemeData lightTheme;
            ThemeData darkTheme;

            if (state.useDynamicColor && state.sourceColor != null) {
              lightTheme = FlexThemeData.light(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: state.sourceColor!,
                  brightness: Brightness.light,
                ),
                surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
                blendLevel: 7,
                useMaterial3: true,
                fontFamily: GoogleFonts.outfit().fontFamily,
              );
              darkTheme = FlexThemeData.dark(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: state.sourceColor!,
                  brightness: Brightness.dark,
                ),
                surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
                blendLevel: 13,
                useMaterial3: true,
                fontFamily: GoogleFonts.outfit().fontFamily,
              );
            } else {
              lightTheme = state.theme.light;
              darkTheme = state.theme.dark;
            }

            return MaterialApp.router(
              title: 'Muses',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: state.themeMode,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

