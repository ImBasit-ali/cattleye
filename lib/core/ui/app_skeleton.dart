import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Shimmer skeleton blocks for app bootstrap and data loading.
class AppSkeleton {
  AppSkeleton._();

  static Widget box({
    double? width,
    double height = 16,
    BorderRadius? radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: radius ?? BorderRadius.circular(AppTheme.radiusSm),
      ),
    );
  }

  static Widget wrap(BuildContext context, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF3A3A3A) : AppTheme.mediumGray,
      highlightColor: isDark
          ? const Color(0xFF4A4A4A)
          : AppTheme.lightBackground,
      child: child,
    );
  }
}

/// Full-screen skeleton while auth / app services initialize.
class AppBootstrapSkeleton extends StatelessWidget {
  const AppBootstrapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: AppSkeleton.wrap(context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    AppSkeleton.box(width: 56, height: 56, radius: BorderRadius.circular(28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton.box(width: 160, height: 18),
                          const SizedBox(height: 8),
                          AppSkeleton.box(width: 220, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                AppSkeleton.box(height: 120, radius: BorderRadius.circular(AppTheme.radiusMd)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: AppSkeleton.box(height: 90, radius: BorderRadius.circular(AppTheme.radiusMd))),
                    const SizedBox(width: 12),
                    Expanded(child: AppSkeleton.box(height: 90, radius: BorderRadius.circular(AppTheme.radiusMd))),
                  ],
                ),
                const SizedBox(height: 12),
                AppSkeleton.box(height: 90, radius: BorderRadius.circular(AppTheme.radiusMd)),
                const SizedBox(height: 24),
                AppSkeleton.box(height: 220, radius: BorderRadius.circular(AppTheme.radiusMd)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard content skeleton while stats load.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: AppSkeleton.wrap(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton.box(width: 220, height: 28),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: AppSkeleton.box(height: 100, radius: BorderRadius.circular(AppTheme.radiusMd))),
                const SizedBox(width: 12),
                Expanded(child: AppSkeleton.box(height: 100, radius: BorderRadius.circular(AppTheme.radiusMd))),
                const SizedBox(width: 12),
                Expanded(child: AppSkeleton.box(height: 100, radius: BorderRadius.circular(AppTheme.radiusMd))),
              ],
            ),
            const SizedBox(height: 24),
            AppSkeleton.box(height: 260, radius: BorderRadius.circular(AppTheme.radiusMd)),
            const SizedBox(height: 24),
            AppSkeleton.box(height: 180, radius: BorderRadius.circular(AppTheme.radiusMd)),
          ],
        ),
      ),
    );
  }
}

/// List skeleton for animals / detections.
class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, _) => AppSkeleton.wrap(
        ctx,
        AppSkeleton.box(
          height: 72,
          radius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}
