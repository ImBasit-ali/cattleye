import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/cattle_status_format.dart';
import '../../providers/cattle_provider.dart';
import '../../services/cattle_service.dart';
import '../../widgets/home_shell_scope.dart';

class MilkingCowsInformationScreen extends StatefulWidget {
  const MilkingCowsInformationScreen({super.key});

  @override
  State<MilkingCowsInformationScreen> createState() =>
      _MilkingCowsInformationScreenState();
}

class _MilkingCowsInformationScreenState
    extends State<MilkingCowsInformationScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final cattle = context.watch<CattleProvider>();
    final all = cattle.allDetections;
    final detections = _applyFilter(all);
    final stats = cattle.stats;

    final lactatingCount = stats.milkingCattle;
    final dryCount =
        all.where((d) => d.milkingStatus == 'dry').length;
    final totalRecords = stats.totalRecords;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: HomeShellScope.leading(context),
        title: Text(context.l10n.milkingCows),
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
              Text(
                'All records · $totalRecords detections',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _SummaryCard(
                        label: 'Lactating',
                        count: lactatingCount,
                        color: AppTheme.greenCard,
                        icon: Icons.water_drop)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SummaryCard(
                        label: 'Dry',
                        count: dryCount,
                        color: AppTheme.blueCard,
                        icon: Icons.block)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SummaryCard(
                        label: 'Total',
                        count: totalRecords,
                        color: AppTheme.limeCard,
                        icon: Icons.pets,
                        textDark: true)),
              ]),
              const SizedBox(height: AppTheme.spacingSm),
              Row(children: [
                const Text('Filter: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                ...['All', 'lactating', 'dry'].map((f) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text(f == 'lactating'
                            ? 'Milking'
                            : f == 'dry'
                                ? 'Not Milking'
                                : 'All'),
                        selected: _filter == f,
                        selectedColor: AppTheme.primaryTeal,
                        labelStyle: TextStyle(
                            color: _filter == f ? Colors.white : null),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    )),
              ]),
              const SizedBox(height: AppTheme.spacingMd),
              if (detections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(children: [
                    Icon(Icons.water_drop_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No milking records yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Run video or live camera analysis to collect data',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                )
              else
                ...detections.map((d) => _MilkingCard(detection: d)),
            ],
          ),
        ),
      ),
    );
  }

  List<CattleDetection> _applyFilter(List<CattleDetection> all) {
    if (_filter == 'All') return all;
    return all.where((d) => d.milkingStatus == _filter).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool textDark;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.textDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textDark ? AppTheme.textPrimary : Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: fg, fontSize: 11)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(count.toString(),
                style: TextStyle(
                    color: fg, fontSize: 24, fontWeight: FontWeight.bold)),
            Icon(icon, color: fg, size: 20),
          ]),
        ],
      ),
    );
  }
}

class _MilkingCard extends StatelessWidget {
  final CattleDetection detection;
  const _MilkingCard({required this.detection});

  @override
  Widget build(BuildContext context) {
    final isLactating = detection.milkingStatus == 'lactating';
    final statusColor = isLactating ? Colors.green : Colors.blueGrey;
    final time = detection.detectedAt;
    final dateStr =
        '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Icon(
            isLactating ? Icons.water_drop : Icons.water_drop_outlined,
            color: statusColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(detection.cattleId,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                  CattleStatusFormat.milkingLabel(detection.milkingStatus),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text('${detection.cattleCount} cattle · ${detection.source}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              if (detection.isLame) ...[
                const SizedBox(width: 8),
                Text(
                  CattleStatusFormat.lamenessLabel(
                    isLame: true,
                    score: detection.lamenessScore,
                  ),
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ]),
          ]),
        ),
        Text(dateStr,
            style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
      ]),
    );
  }
}
