part of 'shortcuts_bloc.dart';

abstract class ShortcutsEvent extends Equatable {
  const ShortcutsEvent();

  @override
  List<Object> get props => [];
}

class UpdateShortcut extends ShortcutsEvent {
  const UpdateShortcut(this.action, this.shortcut);

  final ShortcutAction action;
  final ShortcutCombination shortcut;

  @override
  List<Object> get props => [action, shortcut];
}

class ResetShortcuts extends ShortcutsEvent {}

class SetRecordingMode extends ShortcutsEvent {
  const SetRecordingMode(this.isRecording);
  final bool isRecording;

  @override
  List<Object> get props => [isRecording];
}
