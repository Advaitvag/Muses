import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:muses/features/settings/models/shortcut_combination.dart';

part 'shortcuts_event.dart';
part 'shortcuts_state.dart';

class ShortcutsBloc extends HydratedBloc<ShortcutsEvent, ShortcutsState> {
  ShortcutsBloc() : super(const ShortcutsState()) {
    on<UpdateShortcut>(_onUpdateShortcut);
    on<ResetShortcuts>(_onResetShortcuts);
    on<SetRecordingMode>(_onSetRecordingMode);
  }

  void _onSetRecordingMode(SetRecordingMode event, Emitter<ShortcutsState> emit) {
    emit(state.copyWith(isRecording: event.isRecording));
  }

  void _onUpdateShortcut(UpdateShortcut event, Emitter<ShortcutsState> emit) {
    final newShortcuts = Map<ShortcutAction, ShortcutCombination>.from(state.shortcuts);
    newShortcuts[event.action] = event.shortcut;
    emit(state.copyWith(shortcuts: newShortcuts));
  }

  void _onResetShortcuts(ResetShortcuts event, Emitter<ShortcutsState> emit) {
    emit(const ShortcutsState());
  }

  @override
  ShortcutsState? fromJson(Map<String, dynamic> json) {
    try {
      final shortcutsJson = json['shortcuts'] as Map<String, dynamic>;
      
      // Start with default shortcuts from an empty state
      final Map<ShortcutAction, ShortcutCombination> shortcuts = 
          Map.from(const ShortcutsState().shortcuts);
      
      for (final entry in shortcutsJson.entries) {
        try {
          final action = ShortcutAction.values.firstWhere((e) => e.name == entry.key);
          shortcuts[action] = ShortcutCombination.fromJson(entry.value as Map<String, dynamic>);
        } catch (_) {
          // Ignore actions that no longer exist or are invalid
        }
      }
      
      return ShortcutsState(shortcuts: shortcuts);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ShortcutsState state) {
    final Map<String, dynamic> shortcutsJson = {};
    for (final entry in state.shortcuts.entries) {
      shortcutsJson[entry.key.name] = entry.value.toJson();
    }
    return {'shortcuts': shortcutsJson};
  }
}
