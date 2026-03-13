part of 'shortcuts_bloc.dart';

enum ShortcutAction {
  playPause,
  next,
  previous,
  shuffle,
  repeat,
  nextTab,
  previousTab,
  back,
  search,
}

class ShortcutsState extends Equatable {
  const ShortcutsState({
    this.shortcuts = const {
      ShortcutAction.playPause: ShortcutCombination(key: LogicalKeyboardKey.space),
      ShortcutAction.next: ShortcutCombination(key: LogicalKeyboardKey.bracketRight),
      ShortcutAction.previous: ShortcutCombination(key: LogicalKeyboardKey.bracketLeft),
      ShortcutAction.shuffle: ShortcutCombination(key: LogicalKeyboardKey.keyR),
      ShortcutAction.repeat: ShortcutCombination(key: LogicalKeyboardKey.keyL),
      ShortcutAction.nextTab: ShortcutCombination(key: LogicalKeyboardKey.arrowRight),
      ShortcutAction.previousTab: ShortcutCombination(key: LogicalKeyboardKey.arrowLeft),
      ShortcutAction.back: ShortcutCombination(key: LogicalKeyboardKey.escape),
      ShortcutAction.search: ShortcutCombination(key: LogicalKeyboardKey.keyS),
    },
    this.isRecording = false,
  });

  final Map<ShortcutAction, ShortcutCombination> shortcuts;
  final bool isRecording;

  ShortcutsState copyWith({
    Map<ShortcutAction, ShortcutCombination>? shortcuts,
    bool? isRecording,
  }) {
    return ShortcutsState(
      shortcuts: shortcuts ?? this.shortcuts,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  @override
  List<Object> get props => [shortcuts, isRecording];
}
