part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ThemeChanged extends ThemeEvent {
  const ThemeChanged(this.theme);

  final AppTheme theme;

  @override
  List<Object> get props => [theme];
}

class ThemeModeChanged extends ThemeEvent {
  const ThemeModeChanged(this.themeMode);

  final ThemeMode themeMode;

  @override
  List<Object> get props => [themeMode];
}

class ThemeShowAlbumArtBackgroundChanged extends ThemeEvent {
  const ThemeShowAlbumArtBackgroundChanged(this.showAlbumArtBackground);

  final bool showAlbumArtBackground;

  @override
  List<Object> get props => [showAlbumArtBackground];
}

class ThemeUseDynamicColorChanged extends ThemeEvent {
  const ThemeUseDynamicColorChanged(this.useDynamicColor);

  final bool useDynamicColor;

  @override
  List<Object> get props => [useDynamicColor];
}

class ThemeSourceColorChanged extends ThemeEvent {
  const ThemeSourceColorChanged(this.sourceColor);

  final Color? sourceColor;

  @override
  List<Object> get props => [sourceColor ?? Colors.transparent];
}

class ThemeNavigationBarPositionChanged extends ThemeEvent {
  const ThemeNavigationBarPositionChanged(this.position);

  final NavigationBarPosition position;

  @override
  List<Object> get props => [position];
}

class ThemeOpacityChanged extends ThemeEvent {
  const ThemeOpacityChanged(this.opacity);

  final double opacity;

  @override
  List<Object> get props => [opacity];
}

class ThemeBlurSigmaChanged extends ThemeEvent {
  const ThemeBlurSigmaChanged(this.blurSigma);

  final double blurSigma;

  @override
  List<Object> get props => [blurSigma];
}

class ThemeAnimationsEnabledChanged extends ThemeEvent {
  const ThemeAnimationsEnabledChanged(this.enabled);

  final bool enabled;

  @override
  List<Object> get props => [enabled];
}

class ThemeCloseToTrayChanged extends ThemeEvent {
  const ThemeCloseToTrayChanged(this.closeToTray);

  final bool closeToTray;

  @override
  List<Object> get props => [closeToTray];
}

class ThemeStartInTrayChanged extends ThemeEvent {
  const ThemeStartInTrayChanged(this.startInTray);

  final bool startInTray;

  @override
  List<Object> get props => [startInTray];
}
