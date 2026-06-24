import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../theme/app_theme.dart';

/// Branded loading indicators.
class AppLoader {
  AppLoader._();

  static Widget inline({double size = 42, String? label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingAnimationWidget.staggeredDotsWave(
          color: AppTheme.primaryTeal,
          size: size,
        ),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  static Widget page({String label = 'Loading…'}) {
    return Center(child: inline(size: 50, label: label));
  }

  static Widget overlay({String label = 'Please wait…'}) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        color: AppTheme.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: inline(label: label),
        ),
      ),
    );
  }
}
