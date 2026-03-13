import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:muses/features/theme/theme.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeChanged>(_onThemeChanged);
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<ThemeShowAlbumArtBackgroundChanged>(_onShowAlbumArtBackgroundChanged);
    on<ThemeUseDynamicColorChanged>(_onUseDynamicColorChanged);
    on<ThemeSourceColorChanged>(_onSourceColorChanged);
    on<ThemeNavigationBarPositionChanged>(_onNavigationBarPositionChanged);
    on<ThemeOpacityChanged>(_onOpacityChanged);
    on<ThemeBlurSigmaChanged>(_onBlurSigmaChanged);
    on<ThemeAnimationsEnabledChanged>(_onAnimationsEnabledChanged);
    on<ThemeCloseToTrayChanged>(_onCloseToTrayChanged);
    on<ThemeStartInTrayChanged>(_onStartInTrayChanged);
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(theme: event.theme));
  }

  void _onThemeModeChanged(ThemeModeChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onShowAlbumArtBackgroundChanged(
      ThemeShowAlbumArtBackgroundChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(showAlbumArtBackground: event.showAlbumArtBackground));
  }

  void _onUseDynamicColorChanged(
      ThemeUseDynamicColorChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(useDynamicColor: event.useDynamicColor));
  }

  void _onSourceColorChanged(
      ThemeSourceColorChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(sourceColor: event.sourceColor));
  }

  void _onNavigationBarPositionChanged(
      ThemeNavigationBarPositionChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(navigationBarPosition: event.position));
  }

  void _onOpacityChanged(
      ThemeOpacityChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(opacity: event.opacity));
  }

  void _onBlurSigmaChanged(
      ThemeBlurSigmaChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(blurSigma: event.blurSigma));
  }

  void _onAnimationsEnabledChanged(
      ThemeAnimationsEnabledChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(animationsEnabled: event.enabled));
  }

  void _onCloseToTrayChanged(
      ThemeCloseToTrayChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(closeToTray: event.closeToTray));
  }

  void _onStartInTrayChanged(
      ThemeStartInTrayChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(startInTray: event.startInTray));
  }

  @override
  ThemeState fromJson(Map<String, dynamic> json) {
    return ThemeState(
      theme: AppTheme.values[json['theme'] as int],
      themeMode: ThemeMode.values[json['themeMode'] as int],
      showAlbumArtBackground: json['showAlbumArtBackground'] as bool? ?? true,
      useDynamicColor: json['useDynamicColor'] as bool? ?? true,
      sourceColor: json['sourceColor'] != null ? Color(json['sourceColor'] as int) : null,
      navigationBarPosition: NavigationBarPosition.values[
          json['navigationBarPosition'] as int? ??
              NavigationBarPosition.top.index],
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      blurSigma: (json['blurSigma'] as num? ?? 40.0).toDouble(),
      animationsEnabled: json['animationsEnabled'] as bool? ?? true,
      closeToTray: json['closeToTray'] as bool? ?? false,
      startInTray: json['startInTray'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson(ThemeState state) {
    return {
      'theme': state.theme.index,
      'themeMode': state.themeMode.index,
      'showAlbumArtBackground': state.showAlbumArtBackground,
      'useDynamicColor': state.useDynamicColor,
      'sourceColor': state.sourceColor?.toARGB32(),
      'navigationBarPosition': state.navigationBarPosition.index,
      'opacity': state.opacity,
      'blurSigma': state.blurSigma,
      'animationsEnabled': state.animationsEnabled,
      'closeToTray': state.closeToTray,
      'startInTray': state.startInTray,
    };
  }
}
