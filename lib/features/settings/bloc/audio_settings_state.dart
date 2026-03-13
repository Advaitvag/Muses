part of 'audio_settings_bloc.dart';

class AudioSettingsState extends Equatable {
  const AudioSettingsState({
    this.volume = 1.0,
    this.isNormalizationEnabled = true,
    this.equalizerEnabled = false,
    this.gaplessPlayback = true,
    this.pauseOnMute = true,
    this.wasAutoPaused = false,
    this.equalizerBands = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  });

  final double volume;
  final bool isNormalizationEnabled;
  final bool equalizerEnabled;
  final bool gaplessPlayback;
  final bool pauseOnMute;
  final bool wasAutoPaused;
  final List<double> equalizerBands;

  AudioSettingsState copyWith({
    double? volume,
    bool? isNormalizationEnabled,
    bool? equalizerEnabled,
    bool? gaplessPlayback,
    bool? pauseOnMute,
    bool? wasAutoPaused,
    List<double>? equalizerBands,
  }) {
    return AudioSettingsState(
      volume: volume ?? this.volume,
      isNormalizationEnabled: isNormalizationEnabled ?? this.isNormalizationEnabled,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      pauseOnMute: pauseOnMute ?? this.pauseOnMute,
      wasAutoPaused: wasAutoPaused ?? this.wasAutoPaused,
      equalizerBands: equalizerBands ?? this.equalizerBands,
    );
  }

  @override
  List<Object> get props => [
        volume,
        isNormalizationEnabled,
        equalizerEnabled,
        gaplessPlayback,
        pauseOnMute,
        wasAutoPaused,
        equalizerBands,
      ];
}
