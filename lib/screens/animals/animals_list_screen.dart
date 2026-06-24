import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../core/ui/app_empty_view.dart';
import '../../core/ui/app_error_view.dart';
import '../../core/ui/app_skeleton.dart';
import '../../providers/cattle_provider.dart';
import '../../widgets/home_shell_scope.dart';

class AnimalsListScreen extends StatefulWidget {
  const AnimalsListScreen({super.key});

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cattle = context.watch<CattleProvider>();
    final rows = _filter(cattle.cattleDisplayRows);
    final loading = cattle.animalsLoading && cattle.cattleDisplayRows.isEmpty;

    final l = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: HomeShellScope.leading(context),
        title: Text(l.animals),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(context, cattle),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, cattle),
        backgroundColor: AppTheme.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l.addAnimal, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: context.cardColor,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchCattleId,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: loading
                ? const ListSkeleton()
                : cattle.animalsError != null && cattle.cattleDisplayRows.isEmpty
                    ? AppErrorView(
                        title: 'Could not load animals',
                        message: 'Please check your connection and try again.',
                        onRetry: () => _refresh(context, cattle),
                      )
                    : rows.isEmpty
                        ? AppEmptyView(
                            title: 'No cattle found',
                            message:
                                'Run video analysis or add animals manually to populate this list.',
                            icon: Icons.pets_outlined,
                            action: TextButton.icon(
                              onPressed: () => _showAddDialog(context, cattle),
                              icon: const Icon(Icons.add),
                              label: const Text('Add animal'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _refresh(context, cattle),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              children: [
                                Text(
                                  'All records · ${rows.length} cattle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _CattleRecordsTable(
                                  rows: rows,
                                  onDelete: (r) => _deleteAnimal(context, cattle, r),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  List<CattleDisplayRow> _filter(List<CattleDisplayRow> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where((r) => r.earTagId.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _refresh(BuildContext context, CattleProvider cattle) async {
    await Future.wait([cattle.loadAnimals(), cattle.loadDetections()]);
  }

  Future<void> _deleteAnimal(
    BuildContext context,
    CattleProvider cattle,
    CattleDisplayRow row,
  ) async {
    final id = row.animalRecordId;
    if (id == null) return;

    final l = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.deleteAnimal),
        content: Text(l.deleteAnimalMessage(row.earTagId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    await cattle.deleteAnimal(id);
  }

  void _showAddDialog(BuildContext context, CattleProvider cattle) {
    final l = context.l10n;
    final idCtrl = TextEditingController();
    final earTagCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String species = 'Cow';
    String health = 'Healthy';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(l.addNewAnimal),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                  labelText: '${l.earTagId} *',
                  hintText: 'e.g. ET-0001',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: earTagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alternate tag (optional)',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: species,
                decoration: const InputDecoration(labelText: 'Species'),
                items: ['Cow', 'Buffalo']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setS(() => species = v ?? 'Cow'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: health,
                decoration: const InputDecoration(labelText: 'Health Status'),
                items: ['Healthy', 'Under Observation', 'Sick', 'Critical']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setS(() => health = v ?? 'Healthy'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (idCtrl.text.trim().isEmpty) return;
                await cattle.addAnimal({
                  'animal_id': idCtrl.text.trim(),
                  'ear_tag': earTagCtrl.text.trim().isEmpty
                      ? idCtrl.text.trim()
                      : earTagCtrl.text.trim(),
                  'species': species,
                  'health_status': health,
                  'age': 0,
                  'notes': notesCtrl.text.trim(),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(l.add),
            ),
          ],
        );
      }),
    );
  }
}

/// All cattle table with column dividers and tick/cross status icons.
class _CattleRecordsTable extends StatelessWidget {
  final List<CattleDisplayRow> rows;
  final void Function(CattleDisplayRow row) onDelete;

  const _CattleRecordsTable({
    required this.rows,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final extras = context.appExtras;
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: extras.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: extras.cardShadow,
        border: Border.all(color: dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TableLine(
            background: context.appExtras.tableHeaderBackground,
            cells: [
              _FlexCell(flex: 2, child: Text(l.srNo, style: headerStyle)),
              _FlexCell(flex: 5, child: Text(l.earTagId, style: headerStyle)),
              _FlexCell(
                flex: 3,
                align: Alignment.center,
                child: Text(l.isMilking, style: headerStyle, textAlign: TextAlign.center),
              ),
              _FlexCell(
                flex: 3,
                align: Alignment.center,
                child: Text(l.isLameness, style: headerStyle, textAlign: TextAlign.center),
              ),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final isMilking = row.milkingStatus == 'lactating';
            final isLame = row.isLame == true;
            final hasMilkingData = row.hasDetection && row.milkingStatus != null;
            final hasLamenessData = row.hasDetection && row.isLame != null;

            return _TableLine(
              onLongPress: row.animalRecordId != null
                  ? () => onDelete(row)
                  : null,
              cells: [
                _FlexCell(
                  flex: 2,
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                _FlexCell(
                  flex: 5,
                  child: Text(
                    row.earTagId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _FlexCell(
                  flex: 3,
                  align: Alignment.center,
                  child: _StatusTickCross(
                    value: hasMilkingData ? isMilking : null,
                    yesColor: AppTheme.successGreen,
                    noColor: AppTheme.errorRed,
                  ),
                ),
                _FlexCell(
                  flex: 3,
                  align: Alignment.center,
                  child: _StatusTickCross(
                    value: hasLamenessData ? isLame : null,
                    yesColor: AppTheme.errorRed,
                    noColor: AppTheme.successGreen,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TableLine extends StatelessWidget {
  final List<_FlexCell> cells;
  final Color? background;
  final VoidCallback? onLongPress;

  const _TableLine({
    required this.cells,
    this.background,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildCells(dividerColor),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: dividerColor),
        ),
      ),
      child: onLongPress == null
          ? row
          : InkWell(onLongPress: onLongPress, child: row),
    );
  }

  List<Widget> _buildCells(Color dividerColor) {
    final out = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      out.add(
        Expanded(
          flex: cell.flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Align(
              alignment: cell.align,
              child: cell.child,
            ),
          ),
        ),
      );
      if (i < cells.length - 1) {
        out.add(VerticalDivider(
          width: 1,
          thickness: 1,
          color: dividerColor,
        ));
      }
    }
    return out;
  }
}

class _FlexCell {
  final Widget child;
  final int flex;
  final Alignment align;

  const _FlexCell({
    required this.child,
    this.flex = 1,
    this.align = Alignment.centerLeft,
  });
}

class _StatusTickCross extends StatelessWidget {
  /// `true` = tick, `false` = cross, `null` = unknown.
  final bool? value;
  final Color yesColor;
  final Color noColor;

  const _StatusTickCross({
    required this.value,
    required this.yesColor,
    required this.noColor,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Icon(Icons.remove, size: 20, color: AppTheme.textHint);
    }

    if (value!) {
      return Icon(Icons.check_circle, size: 22, color: yesColor);
    }

    return Icon(Icons.cancel, size: 22, color: noColor);
  }
}
