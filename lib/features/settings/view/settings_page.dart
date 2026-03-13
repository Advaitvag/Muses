import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/settings/bloc/audio_settings_bloc.dart';
import 'package:muses/features/settings/bloc/folders_bloc.dart';
import 'package:muses/features/settings/bloc/shortcuts_bloc.dart';
import 'package:muses/features/settings/widgets/shortcut_recorder.dart';
import 'package:muses/features/theme/theme.dart';
import 'package:muses/features/theme/theme_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _pickFolder(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null && context.mounted) {
      context.read<FoldersBloc>().add(AddFolder(selectedDirectory));
    }
  }

  Widget _buildShortcutTile(
    BuildContext context,
    String label,
    ShortcutAction action,
    ShortcutsState state,
  ) {
    final shortcut = state.shortcuts[action];
    if (shortcut == null) return const SizedBox.shrink();

    return ListTile(
      title: Text(label),
      trailing: ShortcutRecorder(
        currentShortcut: shortcut,
        onChanged: (newShortcut) {
          context.read<ShortcutsBloc>().add(UpdateShortcut(action, newShortcut));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.3) 
        : Colors.black.withValues(alpha: 0.1);
    final sectionBgColor = isDark 
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.4);
    
    // High contrast slider theme
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: isDark ? Colors.white : theme.colorScheme.primary,
      inactiveTrackColor: isDark ? Colors.white24 : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      thumbColor: isDark ? Colors.white : theme.colorScheme.primary,
      overlayColor: (isDark ? Colors.white : theme.colorScheme.primary).withValues(alpha: 0.1),
      valueIndicatorColor: isDark ? Colors.grey[800] : theme.colorScheme.primary,
    );

    final segmentedButtonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? Colors.white : theme.colorScheme.primary;
        }
        return null;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? Colors.black : theme.colorScheme.onPrimary;
        }
        return isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
      }),
      side: WidgetStateProperty.all(BorderSide(color: borderColor)),
    );

    final isTopNav = context.read<ThemeBloc>().state.navigationBarPosition ==
        NavigationBarPosition.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        toolbarHeight: isTopNav ? 48 : null,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        children: [
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
            _buildSectionHeader(context, 'General'),
            _SettingsSection(
              borderColor: borderColor,
              backgroundColor: sectionBgColor,
              children: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Close to Tray'),
                          subtitle: const Text(
                              'Keep the app running in the system tray when closed'),
                          value: state.closeToTray,
                          onChanged: (bool value) {
                            context
                                .read<ThemeBloc>()
                                .add(ThemeCloseToTrayChanged(value));
                          },
                        ),
                        const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.white10),
                                              SwitchListTile(
                                                title: const Text('Start in Tray'),
                                                subtitle: const Text('Automatically hide the window on startup'),
                                                value: state.startInTray,
                                                onChanged: (bool value) {
                                                  context
                                                      .read<ThemeBloc>()
                                                      .add(ThemeStartInTrayChanged(value));
                                                },
                                              ),
                                              const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                                              SwitchListTile(
                                                title: const Text('Enable Animations'),
                                                subtitle: const Text('Enable smooth transitions and animations'),
                                                value: state.animationsEnabled,
                                                onChanged: (bool value) {
                                                  context
                                                      .read<ThemeBloc>()
                                                      .add(ThemeAnimationsEnabledChanged(value));
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
            const SizedBox(height: 16),
          ],
          _buildSectionHeader(context, 'Appearance'),
          _SettingsSection(
            borderColor: borderColor,
            backgroundColor: sectionBgColor,
            children: [
              BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _ResponsiveSettingsTile(
                        title: 'Theme Mode',
                        child: SegmentedButton<ThemeMode>(
                          style: segmentedButtonStyle,
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto),
                              label: Text('Auto'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {state.themeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            context
                                .read<ThemeBloc>()
                                .add(ThemeModeChanged(newSelection.first));
                          },
                        ),
                      ),
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white10),
                      ListTile(
                        title: const Text('Color Theme'),
                        subtitle: Text(state.theme.name),
                        trailing: DropdownButton<AppTheme>(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: BorderRadius.circular(12),
                          value: state.theme,
                          onChanged: (AppTheme? newValue) {
                            if (newValue != null) {
                              context
                                  .read<ThemeBloc>()
                                  .add(ThemeChanged(newValue));
                            }
                          },
                          items: AppTheme.values.map((AppTheme theme) {
                            return DropdownMenuItem<AppTheme>(
                              value: theme,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(theme.name),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white10),
                      SwitchListTile(
                        title: const Text('Show Album Art Background'),
                        subtitle: const Text(
                            'Blur the current song artwork in the background'),
                        value: state.showAlbumArtBackground,
                        onChanged: (bool value) {
                          context
                              .read<ThemeBloc>()
                              .add(ThemeShowAlbumArtBackgroundChanged(value));
                        },
                      ),
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white10),
                      SwitchListTile(
                        title: const Text('Use Dynamic Color'),
                        subtitle: const Text(
                            'Extract accent color from current song artwork'),
                        value: state.useDynamicColor,
                        onChanged: (bool value) {
                          context
                              .read<ThemeBloc>()
                              .add(ThemeUseDynamicColorChanged(value));
                        },
                      ),
                      if (Platform.isWindows ||
                          Platform.isLinux ||
                          Platform.isMacOS) ...[
                        const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.white10),
                        ListTile(
                          enabled: !state.showAlbumArtBackground,
                          title: const Text('Background Opacity'),
                          subtitle: SliderTheme(
                            data: sliderTheme.copyWith(
                              activeTrackColor: state.showAlbumArtBackground
                                  ? theme.disabledColor
                                  : sliderTheme.activeTrackColor,
                              thumbColor: state.showAlbumArtBackground
                                  ? theme.disabledColor
                                  : sliderTheme.thumbColor,
                            ),
                            child: Slider(
                              value: state.opacity,
                              onChanged: state.showAlbumArtBackground
                                  ? null
                                  : (value) {
                                      context
                                          .read<ThemeBloc>()
                                          .add(ThemeOpacityChanged(value));
                                    },
                            ),
                          ),
                          trailing: Text(
                            '${(state.opacity * 100).toInt()}%',
                            style: TextStyle(
                              color: state.showAlbumArtBackground
                                  ? theme.disabledColor
                                  : null,
                            ),
                          ),
                        ),
                      ],
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white10),
                      ListTile(
                        enabled: state.showAlbumArtBackground,
                        title: const Text('Background Blur'),
                        subtitle: SliderTheme(
                          data: sliderTheme.copyWith(
                            activeTrackColor: !state.showAlbumArtBackground
                                ? theme.disabledColor
                                : sliderTheme.activeTrackColor,
                            thumbColor: !state.showAlbumArtBackground
                                ? theme.disabledColor
                                : sliderTheme.thumbColor,
                          ),
                          child: Slider(
                            value: state.blurSigma,
                            min: 0.0,
                            max: 100.0,
                            onChanged: !state.showAlbumArtBackground
                                ? null
                                : (value) {
                                    context
                                        .read<ThemeBloc>()
                                        .add(ThemeBlurSigmaChanged(value));
                                  },
                          ),
                        ),
                        trailing: Text(
                          state.blurSigma.toInt().toString(),
                          style: TextStyle(
                            color: !state.showAlbumArtBackground
                                ? theme.disabledColor
                                : null,
                          ),
                        ),
                      ),
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white10),
                      _ResponsiveSettingsTile(
                        title: 'Navigation Bar Position',
                        child: SegmentedButton<NavigationBarPosition>(
                          style: segmentedButtonStyle,
                          segments: const [
                            ButtonSegment(
                              value: NavigationBarPosition.top,
                              icon: Icon(Icons.vertical_align_top),
                              label: Text('Top'),
                            ),
                            ButtonSegment(
                              value: NavigationBarPosition.bottom,
                              icon: Icon(Icons.vertical_align_bottom),
                              label: Text('Bottom'),
                            ),
                          ],
                          selected: {state.navigationBarPosition},
                          onSelectionChanged:
                              (Set<NavigationBarPosition> newSelection) {
                            context.read<ThemeBloc>().add(
                                ThemeNavigationBarPositionChanged(
                                    newSelection.first));
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
            _buildSectionHeader(context, 'Keyboard Shortcuts'),
            _SettingsSection(
              borderColor: borderColor,
              backgroundColor: sectionBgColor,
              children: [
                BlocBuilder<ShortcutsBloc, ShortcutsState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        _buildShortcutTile(
                          context,
                          'Play / Pause',
                          ShortcutAction.playPause,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Next Song',
                          ShortcutAction.next,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Previous Song',
                          ShortcutAction.previous,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Toggle Shuffle',
                          ShortcutAction.shuffle,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Toggle Repeat',
                          ShortcutAction.repeat,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Next Tab',
                          ShortcutAction.nextTab,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Previous Tab',
                          ShortcutAction.previousTab,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Go Back',
                          ShortcutAction.back,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        _buildShortcutTile(
                          context,
                          'Search',
                          ShortcutAction.search,
                          state,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        ListTile(
                          title: const Text('Reset Shortcuts'),
                          trailing: TextButton(
                            onPressed: () {
                              context.read<ShortcutsBloc>().add(ResetShortcuts());
                            },
                            child: const Text('Reset to Default'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _buildSectionHeader(context, 'Audio'),
          _SettingsSection(
            borderColor: borderColor,
            backgroundColor: sectionBgColor,
            children: [
              BlocBuilder<AudioSettingsBloc, AudioSettingsState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      ListTile(
                        title: const Text('Volume'),
                        subtitle: SliderTheme(
                          data: sliderTheme,
                          child: Slider(
                            value: state.volume,
                            onChanged: (value) {
                              context.read<AudioSettingsBloc>().add(VolumeChanged(value));
                            },
                          ),
                        ),
                        trailing: Text('${(state.volume * 100).toInt()}%'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                      SwitchListTile(
                        title: const Text('Volume Normalization'),
                        subtitle: const Text('Make the volume of the songs more consistent'),
                        value: state.isNormalizationEnabled,
                        onChanged: (value) {
                          context.read<AudioSettingsBloc>().add(NormalizationToggled(value));
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                      SwitchListTile(
                        title: const Text('Gapless Playback'),
                        subtitle: const Text('Eliminate silence between consecutive tracks'),
                        value: state.gaplessPlayback,
                        onChanged: (value) {
                          context.read<AudioSettingsBloc>().add(GaplessPlaybackToggled(value));
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                      SwitchListTile(
                        title: const Text('Pause on Mute'),
                        subtitle: const Text('Automatically pause playback when system volume is 0'),
                        value: state.pauseOnMute,
                        onChanged: (value) {
                          context.read<AudioSettingsBloc>().add(PauseOnMuteToggled(value));
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                      ListTile(
                        title: const Text('Sound Equalizer'),
                        trailing: Switch(
                          value: state.equalizerEnabled,
                          onChanged: (value) {
                            context.read<AudioSettingsBloc>().add(EqualizerToggled(value));
                          },
                        ),
                      ),
                      if (state.equalizerEnabled) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Bands'),
                                  TextButton(
                                    onPressed: () {
                                      context.read<AudioSettingsBloc>().add(EqualizerReset());
                                    },
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.equalizerBands.length,
                                  itemBuilder: (context, index) {
                                    final frequencies = [
                                      '60Hz', '170Hz', '310Hz', '600Hz', '1kHz', 
                                      '3kHz', '6kHz', '12kHz', '14kHz', '16kHz'
                                    ];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: SliderTheme(
                                                data: sliderTheme,
                                                child: Slider(
                                                  value: state.equalizerBands[index],
                                                  min: -10.0,
                                                  max: 10.0,
                                                  onChanged: (value) {
                                                    context.read<AudioSettingsBloc>().add(
                                                      EqualizerBandChanged(index, value),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            frequencies[index],
                                            style: theme.textTheme.labelSmall,
                                          ),
                                          Text(
                                            '${state.equalizerBands[index].toStringAsFixed(1)}dB',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Library'),
          _SettingsSection(
            borderColor: borderColor,
            backgroundColor: sectionBgColor,
            children: [
              ListTile(
                title: const Text('Music Folders'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _pickFolder(context),
                ),
              ),
              BlocBuilder<FoldersBloc, FoldersState>(
                builder: (context, state) {
                  if (state.folders.isEmpty) {
                    return const ListTile(
                      title: Text(
                        'No folders added',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.folders.length,
                    itemBuilder: (context, index) {
                      final folder = state.folders[index];
                      return Column(
                        children: [
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
                          ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(folder),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                context.read<FoldersBloc>().add(RemoveFolder(folder));
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ResponsiveSettingsTile extends StatelessWidget {
  const _ResponsiveSettingsTile({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        if (isNarrow) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          );
        }

        return ListTile(
          title: Text(title),
          trailing: child,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
    required this.borderColor,
    required this.backgroundColor,
  });

  final List<Widget> children;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}