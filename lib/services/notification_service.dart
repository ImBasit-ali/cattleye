import 'package:flutter/material.dart';
import '../core/app_messenger.dart';
import 'settings_service.dart';

/// Notification Service - Handles app notifications based on settings
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final SettingsService _settingsService = SettingsService.instance;

  ScaffoldMessengerState? get _messenger =>
      AppMessenger.messenger;

  /// Show a notification if enabled in settings.
  void showNotification(
    String type,
    String title,
    String message, {
    BuildContext? context,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!_settingsService.shouldShowNotification(type)) {
      debugPrint('Notification blocked by settings: $type - $title');
      return;
    }

    final messenger = context != null
        ? ScaffoldMessenger.maybeOf(context)
        : _messenger;
    if (messenger == null) {
      debugPrint('Notification skipped (no messenger): $type - $title');
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor ?? _getColorForType(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: messenger.hideCurrentSnackBar,
        ),
      ),
    );

    debugPrint('✅ Notification shown: $type - $title');
  }

  void showLamenessAlert(
    String animalId,
    double lamenessScore,
    String severity, {
    BuildContext? context,
  }) {
    showNotification(
      'lameness',
      'Lameness Detected',
      'Animal $animalId has $severity (Score: ${lamenessScore.toStringAsFixed(1)}/5)',
      context: context,
      backgroundColor: Colors.orange,
    );
  }

  void showMilkingAlert(
    String animalId,
    bool isMilking, {
    BuildContext? context,
  }) {
    showNotification(
      'milking',
      'Milking Status Update',
      'Animal $animalId is ${isMilking ? "lactating" : "not lactating"}',
      context: context,
      backgroundColor: Colors.blue,
    );
  }

  void showHealthAlert(
    String animalId,
    String healthIssue, {
    BuildContext? context,
  }) {
    showNotification(
      'health',
      'Health Alert',
      'Animal $animalId: $healthIssue',
      context: context,
      backgroundColor: Colors.red,
    );
  }

  void notifyDetection({
    required String cattleId,
    required bool isLame,
    required double lamenessScore,
    required String milkingStatus,
    required bool feedingAlert,
    BuildContext? context,
  }) {
    if (isLame) {
      final severity = lamenessScore >= 4
          ? 'severe lameness'
          : lamenessScore >= 3
              ? 'moderate lameness'
              : 'mild lameness';
      showLamenessAlert(cattleId, lamenessScore, severity, context: context);
    }

    if (milkingStatus == 'lactating') {
      showMilkingAlert(cattleId, true, context: context);
    }

    if (feedingAlert) {
      showHealthAlert(
        cattleId,
        'Unusual feeding behavior detected',
        context: context,
      );
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'lameness':
        return Colors.orange;
      case 'milking':
        return Colors.blue;
      case 'health':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }
}
