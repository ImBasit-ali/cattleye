import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config/backend_config.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_loader.dart';
import '../l10n/app_localizations.dart';
import '../providers/backend_connection_provider.dart';

/// Shared palette for backend connection status.
class BackendStatusStyle {
  const BackendStatusStyle({
    required this.dotColor,
    required this.label,
  });

  final Color dotColor;
  final String label;

  static BackendStatusStyle from(
    BackendConnectionStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case BackendConnectionStatus.idle:
        return BackendStatusStyle(
          dotColor: AppTheme.white.withValues(alpha: 0.45),
          label: l10n.aiServerNeverChecked,
        );
      case BackendConnectionStatus.connected:
        return BackendStatusStyle(
          dotColor: const Color(0xFF4ADE80),
          label: l10n.aiServerOnline,
        );
      case BackendConnectionStatus.checking:
        return BackendStatusStyle(
          dotColor: AppTheme.warningOrange,
          label: l10n.aiServerChecking,
        );
      case BackendConnectionStatus.disconnected:
        return BackendStatusStyle(
          dotColor: AppTheme.errorRed,
          label: l10n.aiServerOffline,
        );
    }
  }
}

/// Sidebar footer row — always visible on desktop, in drawer on mobile.
class BackendStatusSidebarTile extends StatelessWidget {
  const BackendStatusSidebarTile({super.key});

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<BackendConnectionProvider>();
    final l10n = context.l10n;
    final style = BackendStatusStyle.from(backend.status, l10n);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => BackendStatusSheet.show(context),
        splashColor: AppTheme.white.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              _StatusDot(color: style.dotColor, pulse: backend.status == BackendConnectionStatus.checking),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiServer,
                      style: TextStyle(
                        color: AppTheme.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      style.label,
                      style: TextStyle(
                        color: AppTheme.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.white.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact app-bar chip — matches the dashboard live-sync indicator.
class BackendStatusAppBarAction extends StatelessWidget {
  const BackendStatusAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<BackendConnectionProvider>();
    final l10n = context.l10n;
    final style = BackendStatusStyle.from(backend.status, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: '${l10n.aiServer}: ${style.label}',
        child: InkWell(
          onTap: () => BackendStatusSheet.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: style.dotColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDot(
                  color: style.dotColor,
                  pulse: backend.status == BackendConnectionStatus.checking,
                  size: 7,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.aiServerShort,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final bool pulse;
  final double size;

  const _StatusDot({
    required this.color,
    this.pulse = false,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: pulse ? 6 : 3,
          ),
        ],
      ),
    );

    if (!pulse) return dot;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: dot,
    );
  }
}

/// Details sheet — reconnect without leaving the current screen.
class BackendStatusSheet {
  BackendStatusSheet._();

  static Future<void> show(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 720) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const _BackendStatusPanel(),
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: _BackendStatusPanel(),
      ),
    );
  }
}

class _BackendStatusPanel extends StatelessWidget {
  const _BackendStatusPanel();

  String _lastCheckedLabel(AppLocalizations l10n, DateTime? at) {
    if (at == null) return l10n.aiServerNeverChecked;
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return l10n.aiServerCheckedJustNow;
    if (diff.inMinutes < 60) {
      return l10n.aiServerCheckedMinutes(diff.inMinutes);
    }
    return l10n.aiServerCheckedAt(DateFormat.jm().format(at));
  }

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<BackendConnectionProvider>();
    final l10n = context.l10n;
    final style = BackendStatusStyle.from(backend.status, l10n);
    final checking = backend.status == BackendConnectionStatus.checking;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.memory_outlined, color: AppTheme.primaryTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiServer,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiServerSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: style.dotColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: style.dotColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                _StatusDot(color: style.dotColor, pulse: checking),
                const SizedBox(width: 10),
                Text(
                  style.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: style.dotColor.withValues(alpha: 0.95),
                  ),
                ),
                const Spacer(),
                Text(
                  _lastCheckedLabel(l10n, backend.lastVerifiedAt),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(label: l10n.aiServerEndpoint, value: backend.backendUrl),
          if (backend.errorMessage != null && !backend.isConnected) ...[
            const SizedBox(height: 10),
            Text(
              backend.errorMessage!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.errorRed.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (!backend.isConnected) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                BackendConfig.backendStartCommand,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: BackendConfig.backendStartCommand),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copy)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l10n.copyCommand),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: checking
                  ? null
                  : () => backend.check(userInitiated: true),
              icon: checking
                  ? SizedBox(width: 18, height: 18, child: AppLoader.inline(size: 18))
                  : const Icon(Icons.refresh, size: 18),
              label: Text(checking ? l10n.aiServerChecking : l10n.aiServerReconnect),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
