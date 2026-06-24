import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/cattle_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _applySyncSettings() async {
    if (!mounted) return;
    await context.read<CattleProvider>().applySyncSettings();
  }

  void _reconfigureCameraTimers() {
    if (!mounted) return;
    context.read<CameraProvider>().reconfigureAnalysisTimers();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final l = context.l10n;
    final syncLabels = SettingsService.syncIntervalOptions
        .map((m) => l.syncMinutes(m))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(l.notifications),
          _buildCard(context, [
            _buildSwitchTile(
              l.enableNotifications,
              l.enableNotificationsSub,
              settingsProvider.enableNotifications,
              (value) => settingsProvider.setEnableNotifications(value),
            ),
            if (settingsProvider.enableNotifications) ...[
              _buildSwitchTile(
                l.lamenessAlerts,
                l.lamenessAlertsSub,
                settingsProvider.lamenessAlerts,
                (value) => settingsProvider.setLamenessAlerts(value),
              ),
              _buildSwitchTile(
                l.milkingAlerts,
                l.milkingAlertsSub,
                settingsProvider.milkingAlerts,
                (value) => settingsProvider.setMilkingAlerts(value),
              ),
              _buildSwitchTile(
                l.healthAlerts,
                l.healthAlertsSub,
                settingsProvider.healthAlerts,
                (value) => settingsProvider.setHealthAlerts(value),
              ),
            ],
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.aiDetectionSettings),
          _buildCard(context, [
            _buildSliderTile(
              l.detectionConfidence,
              l.detectionConfidenceSub,
              settingsProvider.detectionConfidence,
              0.5,
              1.0,
              (value) => settingsProvider.setDetectionConfidence(value),
              valueLabel:
                  '${(settingsProvider.detectionConfidence * 100).toInt()}%',
            ),
            _buildSwitchTile(
              l.autoProcessVideos,
              l.autoProcessVideosSub,
              settingsProvider.autoProcessVideos,
              (value) => settingsProvider.setAutoProcessVideos(value),
            ),
            _buildSwitchTile(
              l.saveProcessedVideos,
              l.saveProcessedVideosSub,
              settingsProvider.saveProcessedVideos,
              (value) => settingsProvider.setSaveProcessedVideos(value),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.cameraSettings),
          _buildCard(context, [
            _buildDropdownTile(
              l.cameraFps,
              l.cameraFpsSub,
              settingsProvider.cameraFPS.toString(),
              const ['15', '24', '30', '60'],
              (value) async {
                if (value != null) {
                  await settingsProvider.setCameraFPS(int.parse(value));
                  _reconfigureCameraTimers();
                }
              },
            ),
            _buildDropdownTile(
              l.videoQuality,
              l.videoQualitySub,
              settingsProvider.videoQuality,
              const ['low', 'medium', 'high', 'ultra'],
              (value) => settingsProvider.setVideoQuality(value!),
              itemLabel: (v) => l.videoQualityLabel(v),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.dataAndSync),
          _buildCard(context, [
            _buildSwitchTile(
              l.autoSync,
              l.autoSyncSub,
              settingsProvider.autoSync,
              (value) async {
                await settingsProvider.setAutoSync(value);
                await _applySyncSettings();
              },
            ),
            if (settingsProvider.autoSync)
              _buildDropdownTile(
                l.syncInterval,
                l.syncIntervalSub,
                l.syncMinutes(settingsProvider.dataSyncInterval),
                syncLabels,
                (value) async {
                  final idx = syncLabels.indexOf(value!);
                  if (idx >= 0) {
                    await settingsProvider.setDataSyncInterval(
                      SettingsService.syncIntervalOptions[idx],
                    );
                    await _applySyncSettings();
                  }
                },
              ),
            _buildSwitchTile(
              l.wifiOnly,
              l.wifiOnlySub,
              settingsProvider.wifiOnly,
              (value) async {
                await settingsProvider.setWifiOnly(value);
                await _applySyncSettings();
              },
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.display),
          _buildCard(context, [
            _buildSwitchTile(
              l.darkMode,
              l.darkModeSub,
              settingsProvider.darkMode,
              (value) => settingsProvider.setDarkMode(value),
            ),
            _buildDropdownTile(
              l.language,
              l.languageSub,
              settingsProvider.languageCode,
              AppLocalizations.supportedLanguageCodes,
              (value) => settingsProvider.setLanguageCode(value!),
              itemLabel: (code) => l.languageDisplayName(code),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.account),
          _buildCard(context, [
            _buildActionTile(
              l.profile,
              l.profileSub,
              Icons.person,
              () => _showProfileDialog(authProvider),
            ),
            _buildActionTile(
              l.privacySecurity,
              l.privacySecuritySub,
              Icons.security,
              () => _showPrivacyDialog(settingsProvider),
            ),
            _buildActionTile(
              l.dataManagement,
              l.dataManagementSub,
              Icons.storage,
              () => _showDataManagementDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.support),
          _buildCard(context, [
            _buildActionTile(
              l.helpFaq,
              l.helpFaqSub,
              Icons.help,
              () => _showHelpDialog(),
            ),
            _buildActionTile(
              l.contactSupport,
              l.contactSupportSub,
              Icons.contact_support,
              () => _showContactSupportDialog(),
            ),
            _buildActionTile(
              l.sendFeedback,
              l.sendFeedbackSub,
              Icons.feedback,
              () => _showFeedbackDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader(l.dangerZone, color: AppTheme.errorRed),
          _buildCard(context, [
            _buildActionTile(
              l.clearCache,
              l.clearCacheSub,
              Icons.delete_sweep,
              () => _showClearCacheDialog(),
              textColor: AppTheme.errorRed,
            ),
            _buildActionTile(
              l.resetSettings,
              l.resetSettingsSub,
              Icons.restore,
              () => _showResetSettingsDialog(),
              textColor: AppTheme.errorRed,
            ),
            _buildActionTile(
              l.logout,
              l.logoutSub,
              Icons.logout,
              () => _showLogoutDialog(authProvider),
              textColor: AppTheme.errorRed,
            ),
          ]),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  l.appName,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.0.0 — Supabase + Railway',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: context.appExtras.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Material(
          color: context.cardColor,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryTeal,
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String? valueLabel,
  }) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Text(
            valueLabel ?? value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 10,
            activeColor: AppTheme.primaryTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String Function(String value)? itemLabel,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
      ),
      trailing: DropdownButton<String>(
        value: safeValue,
        underline: const SizedBox(),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(itemLabel?.call(item) ?? item),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryTeal),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? context.appExtras.hintText,
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.aboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 2.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(l.aboutBody, style: TextStyle(color: ctx.secondaryTextColor)),
            const SizedBox(height: 12),
            Text(
              '© 2026 ${l.appName}',
              style: TextStyle(fontSize: 12, color: ctx.appExtras.hintText),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
        ],
      ),
    );
  }

  void _showProfileDialog(AuthProvider authProvider) {
    final l = context.l10n;
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');
    final farmController = TextEditingController(text: user?.farmName ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.profile),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l.nameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: farmController,
                decoration: InputDecoration(labelText: l.farmNameLabel),
              ),
              const SizedBox(height: 12),
              Text(
                '${l.email}: ${user?.email ?? '—'}',
                style: TextStyle(color: dialogContext.secondaryTextColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              final ok = await authProvider.updateProfile(
                name: nameController.text,
                farmName: farmController.text,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? l.profileUpdated
                        : authProvider.errorMessage ?? l.profileUpdateFailed,
                  ),
                ),
              );
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(SettingsProvider settingsProvider) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.privacySecurity),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(l.shareAnalytics),
                subtitle: Text(l.shareAnalyticsSub),
                value: settingsProvider.shareAnalytics,
                onChanged: (v) async {
                  await settingsProvider.setShareAnalytics(v);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: Text(l.crashReporting),
                subtitle: Text(l.crashReportingSub),
                value: settingsProvider.crashReporting,
                onChanged: (v) async {
                  await settingsProvider.setCrashReporting(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              Text(
                l.privacyNote,
                style: TextStyle(fontSize: 13, color: ctx.secondaryTextColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.done),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final l = context.l10n;
    final faqs = [
      (l.faqUploadTitle, l.faqUploadBody),
      (l.faqSyncTitle, l.faqSyncBody),
      (l.faqConfidenceTitle, l.faqConfidenceBody),
      (l.faqNotificationsTitle, l.faqNotificationsBody),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.helpFaq),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: faqs.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) => ListTile(
              title: Text(
                faqs[i].$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(faqs[i].$2),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    final l = context.l10n;
    const email = 'support@cattle-ai.app';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.contactSupport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.contactSupportBody),
            const SizedBox(height: 8),
            SelectableText(
              email,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: email));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l.supportEmailCopied)));
            },
            child: Text(l.copy),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final l = context.l10n;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.sendFeedback),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l.feedbackHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              debugPrint('User feedback: ${controller.text}');
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l.feedbackThanks)));
            },
            child: Text(l.send),
          ),
        ],
      ),
    );
  }

  void _showDataManagementDialog() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dataManagement),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(l.exportData),
              subtitle: Text(l.exportDataSub),
              onTap: () {
                Navigator.pop(ctx);
                _exportDataSummary();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppTheme.errorRed),
              title: Text(
                l.deleteAllData,
                style: TextStyle(color: AppTheme.errorRed),
              ),
              subtitle: Text(l.deleteAllDataSub),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDataDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDataSummary() async {
    final cattle = context.read<CattleProvider>();
    final stats = cattle.stats;
    final summary =
        '''
CattleEye — Data Export
Generated: ${DateTime.now().toIso8601String()}

Animals (manual records): ${cattle.animals.length}
Total detections (all time): ${stats.totalRecords}
Milking cattle: ${stats.milkingCattle}
Lameness cases: ${stats.lamenessCattle}
Today's detections: ${stats.todayRecords}
''';

    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.dataExported)));
  }

  void _showDeleteDataDialog() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAllData),
        content: Text(l.deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(ctx);
              final cattleProvider = ctx.read<CattleProvider>();

              nav.pop();
              final ok = await cattleProvider.deleteAllUserData();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? l.allDataDeleted : l.deleteDataFailed),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearCache),
        content: Text(l.clearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(ctx);
              final settingsProvider = ctx.read<SettingsProvider>();

              final cleared = await settingsProvider.clearAnalysisCache();
              if (!mounted) return;
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    cleared > 0 ? l.cacheClearedCount(cleared) : l.cacheEmpty,
                  ),
                ),
              );
            },
            child: Text(l.clear),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetSettings),
        content: Text(l.resetSettingsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(ctx);
              final settingsProvider = ctx.read<SettingsProvider>();

              await settingsProvider.resetToDefault();
              await _applySyncSettings();
              _reconfigureCameraTimers();
              if (!mounted) return;
              nav.pop();
              messenger.showSnackBar(SnackBar(content: Text(l.settingsReset)));
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(l.reset),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logoutConfirm),
        content: Text(l.logoutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<CattleProvider>().clearData();
              await authProvider.signOut();

              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(l.logout),
          ),
        ],
      ),
    );
  }
}
