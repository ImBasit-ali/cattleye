import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import '../../widgets/app_sidebar.dart';

/// Sidebar + scrollable content shell used on desktop and inside drawer.
class AppShellLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showMobileDrawer;
  final Color? backgroundColor;

  const AppShellLayout({
    super.key,
    required this.sidebar,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.scaffoldKey,
    this.showMobileDrawer = false,
    this.backgroundColor,
  });

  factory AppShellLayout.desktop({
    required Widget sidebar,
    required Widget body,
    PreferredSizeWidget? appBar,
  }) {
    return AppShellLayout(
      sidebar: sidebar,
      body: body,
      appBar: appBar,
    );
  }

  factory AppShellLayout.mobile({
    required GlobalKey<ScaffoldState> scaffoldKey,
    required Widget sidebar,
    required Widget body,
    required Widget bottomNavigationBar,
    Widget? floatingActionButton,
  }) {
    return AppShellLayout(
      scaffoldKey: scaffoldKey,
      sidebar: sidebar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      showMobileDrawer: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    if (!showMobileDrawer && bottomNavigationBar == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: appBar,
        body: Row(
          children: [
            SizedBox(width: AppSidebar.preferredWidth, child: sidebar),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: bg,
      drawer: showMobileDrawer
          ? Drawer(
              width: AppSidebar.preferredWidth,
              backgroundColor: context.appExtras.drawerBackground,
              child: sidebar,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
