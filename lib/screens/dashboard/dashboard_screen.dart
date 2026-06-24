import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../core/ui/app_empty_view.dart';
import '../../core/ui/app_error_view.dart';
import '../../core/ui/app_skeleton.dart';
import '../../core/ui/detection_swiper.dart';
import '../../core/ui/premium_stat_card.dart';
import '../../core/utils/cattle_status_format.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cattle_provider.dart';
import '../../services/cattle_service.dart';
import '../../widgets/backend_status_indicator.dart';
import '../../widgets/home_shell_scope.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    final cattle = context.watch<CattleProvider>();

    final filtered = _applySearch(cattle.todaysDetections);

    final l = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: HomeShellScope.leading(context),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.searchCattleId,
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              )
            : Text(l.dashboard),
        centerTitle: true,
        actions: [
          const BackendStatusAppBarAction(),
          if (cattle.realtimeActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: l.liveUpdatesActive,
                child: Icon(Icons.circle, color: Colors.greenAccent, size: 12),
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = '';
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshDashboard(context, cattle),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshDashboard(context, cattle),
        child: _buildBody(context, cattle, auth, filtered),
      ),
    );
  }

  // ── Welcome ───────────────────────────────────────────────────────────────

  Widget _buildWelcome(BuildContext context, AuthProvider auth) {
    final l = context.l10n;
    final name = auth.currentUser?.name ??
        (auth.currentUser?.email.split('@').first ?? l.farmer);
    return Row(
      children: [
        Text(l.welcome,
            style: TextStyle(fontSize: 24, color: context.secondaryTextColor)),
        Text(name,
            style: const TextStyle(
                fontSize: 24,
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, DashboardStats s) {
    final l = context.l10n;
    return Row(children: [
      Expanded(
        child: PremiumStatCard(
          title: l.totalCows,
          value: s.totalCattle.toString(),
          color: AppTheme.greenCard,
          icon: Icons.pets,
          animationIndex: 0,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMd),
      Expanded(
        child: PremiumStatCard(
          title: l.milkingCows,
          value: s.milkingCattle.toString(),
          color: AppTheme.limeCard,
          icon: Icons.water_drop,
          animationIndex: 1,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMd),
      Expanded(
        child: PremiumStatCard(
          title: l.lamenessCases,
          value: s.lamenessCattle.toString(),
          color: AppTheme.blueCard,
          icon: Icons.warning_amber,
          animationIndex: 2,
        ),
      ),
    ]);
  }

  Future<void> _refreshDashboard(BuildContext context, CattleProvider cattle) async {
    await cattle.loadDetections();
  }

  Widget _buildBody(
    BuildContext context,
    CattleProvider cattle,
    AuthProvider auth,
    List<CattleDetection> filtered,
  ) {
    if (cattle.statsLoading && cattle.todaysDetections.isEmpty) {
      return const DashboardSkeleton();
    }

    if (cattle.statsError != null && cattle.todaysDetections.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: AppErrorView(
              title: 'Dashboard unavailable',
              message: 'We could not load your cattle data. Check your connection and try again.',
              onRetry: () => _refreshDashboard(context, cattle),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(context, auth),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${cattle.stats.totalRecords} ${context.l10n.recentDetections.toLowerCase()}',
              style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildStatCards(context, cattle.stats),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLg),
            DetectionSwiper(detections: filtered),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          LayoutBuilder(builder: (ctx, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildChart(context, cattle.stats)),
                  const SizedBox(width: AppTheme.spacingLg),
                  Expanded(child: _buildTable(context, filtered)),
                ],
              );
            }
            return Column(children: [
              _buildChart(context, cattle.stats),
              const SizedBox(height: AppTheme.spacingLg),
              _buildTable(context, filtered),
            ]);
          }),
        ],
      ),
    );
  }

  // ── Chart ─────────────────────────────────────────────────────────────────

  Widget _buildChart(BuildContext context, DashboardStats stats) {
    final l = context.l10n;
    final months = stats.monthlyDetections.keys.toList()..sort();
    final extras = context.appExtras;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: extras.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: extras.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.monthlyHealthReport,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(
          '${months.length} ${l.dashboard.toLowerCase()}',
          style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legend(AppTheme.chartPink, l.totalCows),
            _legend(AppTheme.blueCard, l.lamenessCases),
            _legend(AppTheme.limeCard, l.milkingCows),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (months.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                l.noDetectionsToday,
                style: TextStyle(color: context.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (months.length * 72.0).clamp(280, 1200),
              height: 220,
              child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) return const Text('');
                      return Text(
                        CattleStatusFormat.monthLabel(months[i]),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) =>
                        Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(months.length, (i) => FlSpot(
                      i.toDouble(),
                      (stats.monthlyDetections[months[i]] ?? 0).toDouble())),
                  isCurved: true,
                  color: AppTheme.chartPink,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: List.generate(months.length, (i) => FlSpot(
                      i.toDouble(),
                      (stats.monthlyLameness[months[i]] ?? 0).toDouble())),
                  isCurved: true,
                  color: AppTheme.blueCard,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: List.generate(months.length, (i) => FlSpot(
                      i.toDouble(),
                      (stats.monthlyMilking[months[i]] ?? 0).toDouble())),
                  isCurved: true,
                  color: AppTheme.primaryTeal,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            )),
            ),
          ),
      ]),
    );
  }

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  // ── Detection Table ────────────────────────────────────────────────────────

  Widget _buildTable(BuildContext context, List<CattleDetection> rows) {
    final l = context.l10n;
    final extras = context.appExtras;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: extras.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: extras.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.todaysCattle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('${rows.length}',
              style: TextStyle(fontSize: 12, color: context.secondaryTextColor)),
        ]),
        const SizedBox(height: AppTheme.spacingMd),
        if (rows.isEmpty)
          AppEmptyView(
            title: l.noDetectionsToday,
            message: l.pullToRefresh,
            icon: Icons.pets_outlined,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(extras.tableHeaderBackground),
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Cattle ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Lameness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Milking', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              ],
              rows: rows.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                return DataRow(cells: [
                  DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(d.cattleId, style: const TextStyle(fontSize: 12))),
                  DataCell(Text('${d.cattleCount}', style: const TextStyle(fontSize: 12))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.isLame
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      d.lamenessScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 11,
                        color: d.isLame ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                  DataCell(Text(
                    CattleStatusFormat.milkingLabel(d.milkingStatus),
                    style: const TextStyle(fontSize: 12),
                  )),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: d.isLame
                          ? Colors.orange.withValues(alpha: 0.15)
                          : AppTheme.greenCard.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      CattleStatusFormat.lamenessLabel(
                        isLame: d.isLame,
                        score: d.lamenessScore,
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: d.isLame ? Colors.orange[700] : AppTheme.greenCard,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ]);
              }).toList(),
            ),
          ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<CattleDetection> _applySearch(List<CattleDetection> rows) {
    if (_searchQuery.isEmpty) return rows;
    return rows.where((d) => d.cattleId.toLowerCase().contains(_searchQuery)).toList();
  }
}
