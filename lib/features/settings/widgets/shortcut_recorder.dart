import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muses/features/settings/bloc/shortcuts_bloc.dart';
import 'package:muses/features/settings/models/shortcut_combination.dart';

class ShortcutRecorder extends StatefulWidget {
  const ShortcutRecorder({
    required this.currentShortcut,
    required this.onChanged,
    super.key,
  });

  final ShortcutCombination currentShortcut;
  final ValueChanged<ShortcutCombination> onChanged;

  @override
  State<ShortcutRecorder> createState() => _ShortcutRecorderState();
}

class _ShortcutRecorderState extends State<ShortcutRecorder> {
  bool _isRecording = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    context.read<ShortcutsBloc>().add(const SetRecordingMode(true));
    _focusNode.requestFocus();
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    context.read<ShortcutsBloc>().add(const SetRecordingMode(false));
    _focusNode.unfocus();
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Ignore if only a modifier is pressed
      if (key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight ||
          key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight ||
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight ||
          key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight) {
        return;
      }

      final keyboard = HardwareKeyboard.instance;
      final newShortcut = ShortcutCombination(
        key: key,
        control: keyboard.isControlPressed,
        alt: keyboard.isAltPressed,
        shift: keyboard.isShiftPressed,
        meta: keyboard.isMetaPressed,
      );

      widget.onChanged(newShortcut);
      _stopRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: _isRecording ? _stopRecording : _startRecording,
      borderRadius: BorderRadius.circular(8),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _isRecording ? _onKeyEvent : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isRecording
                ? theme.colorScheme.primaryContainer
                : (isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isRecording
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isRecording ? 'Press keys...' : widget.currentShortcut.toString(),
                style: TextStyle(
                  color: _isRecording
                      ? theme.colorScheme.onPrimaryContainer
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (_isRecording) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
