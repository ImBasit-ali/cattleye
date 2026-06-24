import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backend_connection_provider.dart';
import '../../providers/cattle_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/home_shell_scope.dart';
import '../dashboard/dashboard_screen.dart';
import '../animals/animals_list_screen.dart';
import '../animals/cattle_information_screen.dart';
import '../animals/milking_cows_information_screen.dart';
import '../cameras/camera_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static const List<Widget> _screens = [
    DashboardScreen(),
    AnimalsListScreen(),
    CattleInformationScreen(),
    MilkingCowsInformationScreen(),
    CameraScreen(),
  ];

  static const double _sidebarWidth = AppSidebar.preferredWidth;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CattleProvider>().loadAnimals();
        final backend = context.read<BackendConnectionProvider>();
        if (backend.hasBeenChecked) {
          backend.startMonitoring();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) return _buildDesktopLayout();
    return _buildMobileLayout();
  }

  Widget _buildSidebar() {
    return AppSidebar(
      currentIndex: _currentIndex,
      onNavTap: _onNavTap,
      onSettings: _openSettings,
      onLogout: () => _handleLogout(context),
    );
  }

  void _onNavTap(int index) {
    if (!_isDesktop) _scaffoldKey.currentState?.closeDrawer();
    setState(() => _currentIndex = index);
  }

  void _openSettings() {
    if (!_isDesktop) _scaffoldKey.currentState?.closeDrawer();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Widget _buildDesktopLayout() {
    return HomeShellScope(
      showDrawerButton: false,
      openDrawer: () {},
      setTab: _onNavTap,
      child: Scaffold(
        body: Row(
          children: [
            SizedBox(width: _sidebarWidth, child: _buildSidebar()),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return HomeShellScope(
      showDrawerButton: true,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      setTab: _onNavTap,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          width: _sidebarWidth,
          backgroundColor: context.appExtras.drawerBackground,
          child: _buildSidebar(),
        ),
        body: IndexedStack(index: _currentIndex, children: _screens),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (!_isDesktop) _scaffoldKey.currentState?.closeDrawer();

    final cattle = context.read<CattleProvider>();
    final auth = context.read<AuthProvider>();

    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logoutConfirm),
        content: Text(l10n.logoutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      cattle.clearData();
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }
}

class HomeScreenWithTab extends HomeScreen {
  const HomeScreenWithTab({super.key, required super.initialTab});
}
