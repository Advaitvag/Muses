part of 'audio_settings_bloc.dart';

abstract class AudioSettingsEvent extends Equatable {
  const AudioSettingsEvent();

  @override
  List<Object> get props => [];
}

class VolumeChanged extends AudioSettingsEvent {
  const VolumeChanged(this.volume);
  final double volume;

  @override
  List<Object> get props => [volume];
}

class NormalizationToggled extends AudioSettingsEvent {
  const NormalizationToggled(this.enabled);
  final bool enabled;

  @override
  List<Object> get props => [enabled];
}

class EqualizerToggled extends AudioSettingsEvent {
  const EqualizerToggled(this.enabled);
  final bool enabled;

  @override
  List<Object> get props => [enabled];
}

class EqualizerBandChanged extends AudioSettingsEvent {
  const EqualizerBandChanged(this.index, this.gain);
  final int index;
  final double gain;

  @override
  List<Object> get props => [index, gain];
}

class GaplessPlaybackToggled extends AudioSettingsEvent {
  const GaplessPlaybackToggled(this.enabled);
  final bool enabled;

  @override
  List<Object> get props => [enabled];
}

class PauseOnMuteToggled extends AudioSettingsEvent {
  const PauseOnMuteToggled(this.enabled);
  final bool enabled;

  @override
  List<Object> get props => [enabled];
}

class WasAutoPausedChanged extends AudioSettingsEvent {
  const WasAutoPausedChanged(this.wasAutoPaused);
  final bool wasAutoPaused;

  @override
  List<Object> get props => [wasAutoPaused];
}

class EqualizerReset extends AudioSettingsEvent {}
