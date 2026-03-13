import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme {
  deepBlue(FlexScheme.deepBlue, 'Deep Blue'),
  sakura(FlexScheme.sakura, 'Sakura'),
  green(FlexScheme.green, 'Green'),
  mandyRed(FlexScheme.mandyRed, 'Mandy Red'),
  indigo(FlexScheme.indigo, 'Indigo'),
  wasabi(FlexScheme.wasabi, 'Wasabi'),
  gold(FlexScheme.gold, 'Gold'),
  catppuccinMocha(null, 'Catppuccin Mocha',
      customColors: FlexSchemeColor(
        primary: Color(0xFF89B4FA),
        primaryContainer: Color(0xFF1E1E2E),
        secondary: Color(0xFFF5C2E7),
        secondaryContainer: Color(0xFF181825),
        tertiary: Color(0xFF94E2D5),
      )),
  tokyoNight(null, 'Tokyo Night',
      customColors: FlexSchemeColor(
        primary: Color(0xFF7AA2F7),
        primaryContainer: Color(0xFF1A1B26),
        secondary: Color(0xFFBB9AF7),
        secondaryContainer: Color(0xFF24283B),
        tertiary: Color(0xFF7DCFFF),
      ));

  const AppTheme(this.scheme, this.name, {this.customColors});
  final FlexScheme? scheme;
  final String name;
  final FlexSchemeColor? customColors;

  ThemeData get light => FlexThemeData.light(
        scheme: scheme,
        colors: customColors,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.outfit().fontFamily,
      );
  ThemeData get dark => FlexThemeData.dark(
        scheme: scheme,
        colors: customColors,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.outfit().fontFamily,
      );
}
