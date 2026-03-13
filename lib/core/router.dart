import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muses/features/home/view/home_page.dart';
import 'package:muses/features/library/view/library_page.dart';
import 'package:muses/features/player/view/player_page.dart';
import 'package:muses/features/queue/view/queue_page.dart';
import 'package:muses/features/settings/view/settings_page.dart';
import 'package:muses/features/downloader/view/downloader_page.dart';
import 'package:muses/features/theme/theme_bloc.dart';

import 'package:muses/features/player/view/tray_player.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/player',
  routes: [
    GoRoute(
      path: '/tray',
      builder: (context, state) => const TrayPlayer(),
    ),
    StatefulShellRoute(
      builder: (context, state, navigationShell) {
        return HomePage(navigationShell: navigationShell);
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return _SwipeableShell(
          navigationShell: navigationShell,
          children: children,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/player',
              builder: (context, state) => const PlayerPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/queue',
              builder: (context, state) => const QueuePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => LibraryPage(key: LibraryPage.globalKey),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/downloader',
              builder: (context, state) => const DownloaderPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _SwipeableShell extends StatefulWidget {
  const _SwipeableShell({
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<_SwipeableShell> createState() => _SwipeableShellState();
}

class _SwipeableShellState extends State<_SwipeableShell> {
  late PageController _pageController;
  bool _isProgrammaticChange = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
  }

  @override
  void didUpdateWidget(_SwipeableShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure we animate to the new page if the index changed programmatically
    // (e.g. via tab tap or keyboard shortcut)
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round();
      if (widget.navigationShell.currentIndex != currentPage) {
        _isProgrammaticChange = true;
        final animationsEnabled =
            context.read<ThemeBloc>().state.animationsEnabled;
        if (animationsEnabled) {
          _pageController.animateToPage(
            widget.navigationShell.currentIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          ).then((_) {
            if (mounted) {
              setState(() {
                _isProgrammaticChange = false;
              });
            }
          });
        } else {
          _pageController.jumpToPage(widget.navigationShell.currentIndex);
          _isProgrammaticChange = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        if (!_isProgrammaticChange && index != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        }
      },
      children: widget.children,
    );
  }
}
