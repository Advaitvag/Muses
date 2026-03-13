part of 'theme_bloc.dart';

enum NavigationBarPosition { top, bottom }

class ThemeState extends Equatable {
  const ThemeState({
    this.theme = AppTheme.deepBlue,
    this.themeMode = ThemeMode.system,
    this.showAlbumArtBackground = true,
    this.useDynamicColor = true,
    this.sourceColor,
    this.navigationBarPosition = NavigationBarPosition.top,
    this.opacity = 1.0,
    this.blurSigma = 40.0,
    this.animationsEnabled = true,
    this.closeToTray = false,
    this.startInTray = false,
  });

  final AppTheme theme;
  final ThemeMode themeMode;
  final bool showAlbumArtBackground;
  final bool useDynamicColor;
  final Color? sourceColor;
  final NavigationBarPosition navigationBarPosition;
  final double opacity;
  final double blurSigma;
  final bool animationsEnabled;
  final bool closeToTray;
  final bool startInTray;

  @override
  List<Object> get props => [
        theme,
        themeMode,
        showAlbumArtBackground,
        useDynamicColor,
        sourceColor ?? Colors.transparent,
        navigationBarPosition,
        opacity,
        blurSigma,
        animationsEnabled,
        closeToTray,
        startInTray,
      ];

  ThemeState copyWith({
    AppTheme? theme,
    ThemeMode? themeMode,
    bool? showAlbumArtBackground,
    bool? useDynamicColor,
    Color? sourceColor,
    NavigationBarPosition? navigationBarPosition,
    double? opacity,
    double? blurSigma,
    bool? animationsEnabled,
    bool? closeToTray,
    bool? startInTray,
  }) {
    return ThemeState(
      theme: theme ?? this.theme,
      themeMode: themeMode ?? this.themeMode,
      showAlbumArtBackground:
          showAlbumArtBackground ?? this.showAlbumArtBackground,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      sourceColor: sourceColor ?? this.sourceColor,
      navigationBarPosition:
          navigationBarPosition ?? this.navigationBarPosition,
      opacity: opacity ?? this.opacity,
      blurSigma: blurSigma ?? this.blurSigma,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      closeToTray: closeToTray ?? this.closeToTray,
      startInTray: startInTray ?? this.startInTray,
    );
  }
}
