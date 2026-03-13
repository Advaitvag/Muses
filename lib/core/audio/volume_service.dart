import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:muses/features/player/bloc/player_bloc.dart';
import 'package:muses/features/settings/bloc/audio_settings_bloc.dart';

class VolumeService {
  final PlayerBloc _playerBloc;
  final AudioSettingsBloc _audioSettingsBloc;

  VolumeService(this._playerBloc, this._audioSettingsBloc);

  void init() {
    FlutterVolumeController.addListener((volume) {
      final state = _audioSettingsBloc.state;
      if (!state.pauseOnMute) return;

      if (volume == 0) {
        if (_playerBloc.state.status == PlayerStatus.playing) {
          _playerBloc.add(PlayerPause());
          _audioSettingsBloc.add(const WasAutoPausedChanged(true));
        }
      } else if (volume > 0) {
        if (state.wasAutoPaused && _playerBloc.state.status != PlayerStatus.playing) {
          _playerBloc.add(PlayerResume());
          _audioSettingsBloc.add(const WasAutoPausedChanged(false));
        } else if (state.wasAutoPaused) {
          // If already playing but wasAutoPaused is still true, clear it
          _audioSettingsBloc.add(const WasAutoPausedChanged(false));
        }
      }
    });
  }

  void dispose() {
    FlutterVolumeController.removeListener();
  }
}
