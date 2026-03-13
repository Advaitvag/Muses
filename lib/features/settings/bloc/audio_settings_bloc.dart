import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'audio_settings_event.dart';
part 'audio_settings_state.dart';

class AudioSettingsBloc extends HydratedBloc<AudioSettingsEvent, AudioSettingsState> {
  AudioSettingsBloc() : super(const AudioSettingsState()) {
    on<VolumeChanged>(_onVolumeChanged);
    on<NormalizationToggled>(_onNormalizationToggled);
    on<EqualizerToggled>(_onEqualizerToggled);
    on<EqualizerBandChanged>(_onEqualizerBandChanged);
    on<GaplessPlaybackToggled>(_onGaplessPlaybackToggled);
    on<PauseOnMuteToggled>(_onPauseOnMuteToggled);
    on<WasAutoPausedChanged>(_onWasAutoPausedChanged);
    on<EqualizerReset>(_onEqualizerReset);
  }

  void _onVolumeChanged(VolumeChanged event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(volume: event.volume));
  }

  void _onNormalizationToggled(NormalizationToggled event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(isNormalizationEnabled: event.enabled));
  }

  void _onEqualizerToggled(EqualizerToggled event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(equalizerEnabled: event.enabled));
  }

  void _onGaplessPlaybackToggled(GaplessPlaybackToggled event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(gaplessPlayback: event.enabled));
  }

  void _onPauseOnMuteToggled(PauseOnMuteToggled event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(pauseOnMute: event.enabled));
  }

  void _onWasAutoPausedChanged(WasAutoPausedChanged event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(wasAutoPaused: event.wasAutoPaused));
  }

  void _onEqualizerBandChanged(EqualizerBandChanged event, Emitter<AudioSettingsState> emit) {
    final newBands = List<double>.from(state.equalizerBands);
    if (event.index >= 0 && event.index < newBands.length) {
      newBands[event.index] = event.gain;
      emit(state.copyWith(equalizerBands: newBands));
    }
  }

  void _onEqualizerReset(EqualizerReset event, Emitter<AudioSettingsState> emit) {
    emit(state.copyWith(
      equalizerBands: List.filled(state.equalizerBands.length, 0.0),
    ));
  }

  @override
  AudioSettingsState? fromJson(Map<String, dynamic> json) {
    return AudioSettingsState(
      volume: (json['volume'] as num? ?? 1.0).toDouble(),
      isNormalizationEnabled: json['isNormalizationEnabled'] as bool? ?? true,
      equalizerEnabled: json['equalizerEnabled'] as bool? ?? false,
      gaplessPlayback: json['gaplessPlayback'] as bool? ?? true,
      pauseOnMute: json['pauseOnMute'] as bool? ?? true,
      wasAutoPaused: json['wasAutoPaused'] as bool? ?? false,
      equalizerBands: (json['equalizerBands'] as List?)?.cast<double>() ??
          const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    );
  }

  @override
  Map<String, dynamic>? toJson(AudioSettingsState state) {
    return {
      'volume': state.volume,
      'isNormalizationEnabled': state.isNormalizationEnabled,
      'equalizerEnabled': state.equalizerEnabled,
      'gaplessPlayback': state.gaplessPlayback,
      'pauseOnMute': state.pauseOnMute,
      'wasAutoPaused': state.wasAutoPaused,
      'equalizerBands': state.equalizerBands,
    };
  }
}
