import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/backend_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/app_loader.dart';
import '../../providers/backend_connection_provider.dart';

/// Shown when the local Python backend is not running.
class BackendOfflineScreen extends StatelessWidget {
  const BackendOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<BackendConnectionProvider>();
    final checking = backend.status == BackendConnectionStatus.checking;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 72,
                    color: AppTheme.errorRed.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Python backend not running',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start the local AI server on your PC first, then retry. '
                    'The app needs it for cattle detection and video analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(
                    title: 'Expected URL',
                    child: SelectableText(
                      backend.backendUrl,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Start command (project root)',
                    trailing: IconButton(
                      tooltip: 'Copy command',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: BackendConfig.backendStartCommand),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Command copied')),
                        );
                      },
                    ),
                    child: SelectableText(
                      BackendConfig.backendStartCommand,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    BackendConfig.platformHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppTheme.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                  if (backend.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      backend.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorRed.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: checking ? null : () => backend.check(userInitiated: true),
                      icon: checking
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: AppLoader.inline(size: 18),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(checking ? 'Checking…' : 'Try again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _InfoCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.mediumGray.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
