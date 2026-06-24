import 'package:flutter/material.dart';

/// Provides drawer control to tab screens when [HomeScreen] is in mobile mode.
class HomeShellScope extends InheritedWidget {
  final bool showDrawerButton;
  final VoidCallback openDrawer;
  final ValueChanged<int> setTab;

  const HomeShellScope({
    super.key,
    required this.showDrawerButton,
    required this.openDrawer,
    required this.setTab,
    required super.child,
  });

  static HomeShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellScope>();
  }

  /// AppBar leading widget — menu button on mobile, nothing on desktop.
  static Widget? leading(BuildContext context) {
    final shell = maybeOf(context);
    if (shell == null || !shell.showDrawerButton) return null;
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Menu',
      onPressed: shell.openDrawer,
    );
  }

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) {
    return showDrawerButton != oldWidget.showDrawerButton ||
        openDrawer != oldWidget.openDrawer ||
        setTab != oldWidget.setTab;
  }
}
