import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  final bool _isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    if (_isDesktop) {
      windowManager.addListener(this);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(child: Container(color: Colors.transparent)),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  bool _isMaximized = false;
  final bool _isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    if (_isDesktop) {
      windowManager.addListener(this);
      _init();
    }
    super.initState();
  }

  void _init() async {
    if (!_isDesktop) return;
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;

    return Row(
      children: [
        _WindowButton(
          icon: Icon(Icons.remove, size: 16, color: color),
          onPressed: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: Icon(
            _isMaximized ? Icons.filter_none : Icons.crop_square,
            size: 16,
            color: color,
          ),
          onPressed: () {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: Icon(Icons.close, size: 16, color: color),
          onPressed: () => windowManager.close(),
          isClose: true,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      hoverColor: isClose ? Colors.red : null,
      child: SizedBox(width: 40, height: 32, child: Center(child: icon)),
    );
  }
}
