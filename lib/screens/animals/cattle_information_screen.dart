import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/cattle_provider.dart';
import '../../services/cattle_service.dart';
import '../../widgets/home_shell_scope.dart';

class CattleInformationScreen extends StatefulWidget {
  const CattleInformationScreen({super.key});

  @override
  State<CattleInformationScreen> createState() =>
      _CattleInformationScreenState();
}

class _CattleInformationScreenState extends State<CattleInformationScreen> {
  @override
  Widget build(BuildContext context) {
    final cattle = context.watch<CattleProvider>();
    final stats = cattle.stats;
    final detections = cattle.todaysDetections;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: HomeShellScope.leading(context),
        title: Text(context.l10n.cattleInfo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cattle.loadDetections(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => cattle.loadDetections(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview cards
              _buildOverviewCards(stats),
              const SizedBox(height: AppTheme.spacingLg),

              // Health distribution
              _buildHealthSection(stats),
              const SizedBox(height: AppTheme.spacingLg),

              // Recent detections timeline
              _buildDetectionsTimeline(detections),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(DashboardStats s) {
    final items = [
      _InfoCardData(
        label: 'Total Cattle',
        value: s.totalCattle.toString(),
        icon: Icons.pets,
        color: AppTheme.greenCard,
      ),
      _InfoCardData(
        label: 'Healthy',
        value: s.healthyCattle.toString(),
        icon: Icons.favorite,
        color: Colors.green,
      ),
      _InfoCardData(
        label: 'Milking',
        value: s.milkingCattle.toString(),
        icon: Icons.water_drop,
        color: AppTheme.limeCard,
        textDark: true,
      ),
      _InfoCardData(
        label: 'Lameness',
        value: s.lamenessCattle.toString(),
        icon: Icons.warning_amber,
        color: AppTheme.blueCard,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'All records · ${s.totalRecords}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 8.0;
            final computedCardWidth =
                (constraints.maxWidth - (spacing * 3)) / 4;
            final cardWidth = computedCardWidth < 95 ? 95.0 : computedCardWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == items.length - 1 ? 0 : spacing,
                    ),
                    child: SizedBox(
                      width: cardWidth,
                      child: _InfoCard(
                        label: item.label,
                        value: item.value,
                        icon: item.icon,
                        color: item.color,
                        textDark: item.textDark,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHealthSection(DashboardStats s) {
    final total = s.totalRecords == 0 ? 1 : s.totalRecords;
    final healthPct = ((s.healthyCattle / total) * 100).clamp(0, 100).toInt();
    final lamenessPct = ((s.lamenessCattle / total) * 100)
        .clamp(0, 100)
        .toInt();
    final milkingPct = ((s.milkingCattle / total) * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Health Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'All records',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildHealthBar('Healthy', healthPct, s.healthyCattle, Colors.green),
          const SizedBox(height: 8),
          _buildHealthBar(
            'Lameness',
            lamenessPct,
            s.lamenessCattle,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildHealthBar(
            'Milking',
            milkingPct,
            s.milkingCattle,
            AppTheme.primaryTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, int pct, int count, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count ($pct%)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDetectionsTimeline(List<CattleDetection> detections) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Detections',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${detections.length} today',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Daily report only',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (detections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No detections yet — demo data will appear soon',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 600
                    ? 3
                    : 2;
                final spacing = 8.0;
                final itemWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: detections
                      .take(20)
                      .map(
                        (d) => SizedBox(
                          width: itemWidth,
                          child: _DetectionCard(detection: d),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool textDark;

  const _InfoCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.textDark = false,
  });
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool textDark;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.textDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textDark ? AppTheme.textPrimary : Colors.white;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontSize: 9),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: fg, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final CattleDetection detection;
  const _DetectionCard({required this.detection});

  @override
  Widget build(BuildContext context) {
    final time = detection.detectedAt;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: detection.isLame
            ? Colors.orange.withValues(alpha: 0.08)
            : Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: detection.isLame
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                detection.isLame
                    ? Icons.warning_amber
                    : Icons.check_circle_outline,
                color: detection.isLame ? Colors.orange : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detection.cattleId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${detection.cattleCount} cattle',
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            detection.milkingStatus,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            detection.source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
