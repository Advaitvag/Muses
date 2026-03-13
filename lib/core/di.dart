import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muses/core/audio/audio_handler.dart';
import 'package:muses/core/audio/volume_service.dart';
import 'package:muses/core/mpris/mpris_service.dart';
import 'package:muses/features/library/bloc/library_bloc.dart';
import 'package:muses/features/library/bloc/playlists_bloc.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/player/services/music_player.dart';
import 'package:muses/features/library/services/playlist_service.dart';
import 'package:muses/features/settings/bloc/audio_settings_bloc.dart';
import 'package:muses/features/settings/bloc/folders_bloc.dart';
import 'package:muses/features/settings/bloc/shortcuts_bloc.dart';
import 'package:muses/features/theme/theme_bloc.dart';

final getIt = GetIt.instance;

void setupDI(ThemeBloc themeBloc, MusesAudioHandler audioHandler, AudioPlayer audioPlayer) {
  getIt.registerSingleton<MusicPlayer>(MusicPlayer(audioHandler, audioPlayer));
  getIt.registerSingleton<ThemeBloc>(themeBloc);
  
  final shortcutsBloc = ShortcutsBloc();
  getIt.registerSingleton<ShortcutsBloc>(shortcutsBloc);
  
  final foldersBloc = FoldersBloc();
  getIt.registerSingleton<FoldersBloc>(foldersBloc);
  
  final audioSettingsBloc = AudioSettingsBloc();
  getIt.registerSingleton<AudioSettingsBloc>(audioSettingsBloc);
  
  final playlistService = PlaylistService();
  getIt.registerSingleton<PlaylistService>(playlistService);

  final libraryBloc = LibraryBloc(
    foldersBloc: foldersBloc,
    playlistService: playlistService,
  )..add(LoadLibrary());
  getIt.registerSingleton<LibraryBloc>(libraryBloc);
  
  final playlistsBloc = PlaylistsBloc(playlistService: playlistService);
  getIt.registerSingleton<PlaylistsBloc>(playlistsBloc);
  
  final playerBloc = PlayerBloc(
    musicPlayer: getIt<MusicPlayer>(),
    libraryBloc: libraryBloc,
    audioSettingsBloc: audioSettingsBloc,
  );
  getIt.registerSingleton<PlayerBloc>(playerBloc);

  final volumeService = VolumeService(playerBloc, audioSettingsBloc);
  volumeService.init();
  getIt.registerSingleton<VolumeService>(volumeService);

  if (Platform.isLinux) {
    getIt.registerSingleton<MusesMprisService>(MusesMprisService(playerBloc));
  }
}