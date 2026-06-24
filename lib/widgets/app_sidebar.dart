import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/backend_status_indicator.dart';

/// Shared sidebar used on desktop (fixed) and mobile (drawer).
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.onSettings,
    required this.onLogout,
  });

  static List<SidebarNavItem> navItems(BuildContext context) {
    final l = context.l10n;
    return [
      SidebarNavItem(icon: Icons.dashboard, label: l.dashboard),
      SidebarNavItem(icon: Icons.pets, label: l.animals),
      SidebarNavItem(icon: Icons.info, label: l.cattleInfo),
      SidebarNavItem(icon: Icons.water_drop, label: l.milking),
      SidebarNavItem(icon: Icons.videocam, label: l.cameras),
    ];
  }

  /// Compact width — fits labels without stealing content space.
  static const double preferredWidth = 220;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final items = navItems(context);
    final initial = (auth.currentUser?.name ??
            auth.currentUser?.email ??
            'U')[0]
        .toUpperCase();

    return Material(
      color: AppTheme.primaryTeal,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile header ───────────────────────────────────────────
            ColoredBox(
              color: AppTheme.primaryTeal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                child: Row(
                  children: [
                    AvatarGlow(
                      glowColor: AppTheme.lightTeal,
                      glowRadiusFactor: 0.22,
                      duration: const Duration(milliseconds: 2000),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.white,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.name ?? l10n.farmer,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.currentUser?.email ?? '',
                            style: TextStyle(
                              color: AppTheme.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Routes + bottom actions ─────────────────────────────────
            Expanded(
              child: ColoredBox(
                color: AppTheme.primaryTeal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    ...List.generate(items.length, (i) {
                      final item = items[i];
                      return _SidebarNavTile(
                        icon: item.icon,
                        label: item.label,
                        active: currentIndex == i,
                        onTap: () => onNavTap(i),
                      );
                    }),
                    const Spacer(),
                    const BackendStatusSidebarTile(),
                    Divider(
                      color: AppTheme.white.withValues(alpha: 0.25),
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _SidebarNavTile(
                      icon: Icons.settings,
                      label: l10n.settings,
                      onTap: onSettings,
                    ),
                    _SidebarNavTile(
                      icon: Icons.logout,
                      label: l10n.logout,
                      iconColor: AppTheme.errorRed,
                      labelColor: AppTheme.errorRed,
                      onTap: onLogout,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? iconColor;
  final Color? labelColor;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ??
        (active
            ? AppTheme.white
            : AppTheme.white.withValues(alpha: 0.75));
    final lColor = labelColor ??
        (active
            ? AppTheme.white
            : AppTheme.white.withValues(alpha: 0.85));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.white.withValues(alpha: 0.12),
        highlightColor: AppTheme.white.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: active
              ? BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.15),
                  border: const Border(
                    left: BorderSide(color: AppTheme.white, width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              if (!active) const SizedBox(width: 3),
              Icon(icon, color: iColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: lColor,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarNavItem {
  final IconData icon;
  final String label;

  const SidebarNavItem({required this.icon, required this.label});
}
