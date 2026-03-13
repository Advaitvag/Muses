import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

class ShortcutCombination extends Equatable {
  const ShortcutCombination({
    required this.key,
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  final LogicalKeyboardKey key;
  final bool control;
  final bool alt;
  final bool shift;
  final bool meta;

  @override
  List<Object?> get props => [key, control, alt, shift, meta];

  ShortcutCombination copyWith({
    LogicalKeyboardKey? key,
    bool? control,
    bool? alt,
    bool? shift,
    bool? meta,
  }) {
    return ShortcutCombination(
      key: key ?? this.key,
      control: control ?? this.control,
      alt: alt ?? this.alt,
      shift: shift ?? this.shift,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': key.keyId,
      'keyLabel': key.keyLabel,
      'control': control,
      'alt': alt,
      'shift': shift,
      'meta': meta,
    };
  }

  factory ShortcutCombination.fromJson(Map<String, dynamic> json) {
    return ShortcutCombination(
      key: LogicalKeyboardKey(json['keyId'] as int),
      control: json['control'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
    );
  }

  bool matches(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    return event.logicalKey == key &&
        keyboard.isControlPressed == control &&
        keyboard.isAltPressed == alt &&
        keyboard.isShiftPressed == shift &&
        keyboard.isMetaPressed == meta;
  }

  @override
  String toString() {
    final List<String> parts = [];
    if (control) parts.add('Ctrl');
    if (alt) parts.add('Alt');
    if (shift) parts.add('Shift');
    if (meta) parts.add('Meta');
    parts.add(key.keyLabel);
    return parts.join(' + ');
  }
}
