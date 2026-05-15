import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../dashboard/presentation/dashboard_filter_bar.dart';
import '../application/transactions_list_controller.dart';
import 'transaction_list_row.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionsFilterProvider);
    final selection = ref.watch(selectionControllerProvider);
    final selecting = selection.isNotEmpty;

    return Scaffold(
      appBar: selecting
          ? _buildSelectionAppBar(context, ref, selection)
          : AppBar(
              title: Text(l.tabTransactions),
              actions: [
                IconButton(
                  tooltip: l.recycleBinTitle,
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => context.push('/transactions/recycle-bin'),
                ),
              ],
            ),
      body: Column(
        children: [
          const DashboardFilterBar(),
          Expanded(
            child: _buildList(context, ref, async, filter, l, c),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Transaction>> async,
    TransactionsFilter? filter,
    AppL10n l,
    AppColors c,
  ) {
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          final body = rows.isEmpty
              ? Center(
                  child: Text(
                    l.txListEmpty,
                    style: AppTypography.sm.copyWith(color: c.textMuted),
                  ),
                )
              : Builder(builder: (_) {
                  final groups = groupByDay(rows);
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.x2),
                    itemCount: groups.length,
                    itemBuilder: (context, i) =>
                        _DayGroupView(group: groups[i]),
                  );
                });
          if (filter == null || filter.isEmpty) return body;
          return Column(
            children: [
              _FilterChip(filter: filter),
              Expanded(child: body),
            ],
          );
        },
      );
  }
}

PreferredSizeWidget _buildSelectionAppBar(
  BuildContext context,
  WidgetRef ref,
  Set<String> selection,
) {
  final l = AppL10n.of(context);
  return AppBar(
    leading: IconButton(
      tooltip: l.selectionCancel,
      icon: const Icon(LucideIcons.x),
      onPressed: () =>
          ref.read(selectionControllerProvider.notifier).clear(),
    ),
    title: Text(l.selectionTitle(selection.length)),
    actions: [
      IconButton(
        tooltip: l.selectionDelete,
        icon: const Icon(LucideIcons.trash2),
        onPressed: () => _confirmBulkDelete(context, ref, selection),
      ),
    ],
  );
}

Future<void> _confirmBulkDelete(
  BuildContext context,
  WidgetRef ref,
  Set<String> selection,
) async {
  final l = AppL10n.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.selectionDeleteConfirmTitle(selection.length)),
      content: Text(l.selectionDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.txCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.selectionDelete),
        ),
      ],
    ),
  );
  if (yes != true) return;
  await ref
      .read(transactionDaoProvider)
      .bulkSoftDelete(selection.toList());
  ref.read(selectionControllerProvider.notifier).clear();
}

class _DayGroupView extends ConsumerWidget {
  const _DayGroupView({required this.group});
  final DayGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeader(group: group),
        Container(
          color: c.surface,
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                TransactionListRow(
                  tx: group.items[i],
                  enableSelection: true,
                ),
                if (i < group.items.length - 1)
                  Divider(height: 1, color: c.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group});
  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      color: c.mintTint,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDayLabel(context, group.date),
              style: AppTypography.sm.copyWith(
                color: c.actionInk,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
          ),
          Text(
            _formatDayNet(group),
            style: AppTypography.sm.merge(AppTypography.mono).copyWith(
                  color: c.actionInk,
                  fontWeight: AppTypography.weightSemibold,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatDayLabel(BuildContext context, DateTime date) {
  final l = AppL10n.of(context);
  final today = DateTime.now();
  final isToday = today.year == date.year &&
      today.month == date.month &&
      today.day == date.day;
  final y = today.subtract(const Duration(days: 1));
  final isYesterday =
      y.year == date.year && y.month == date.month && y.day == date.day;
  if (isToday) return l.dayToday;
  if (isYesterday) return l.dayYesterday;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// 多币种不换算：取该日组内出现次数最多的货币，签名汇总（income +, expense -）。
/// 若组内有其他币种则附加 " +N"。
String _formatDayNet(DayGroup group) {
  final byCcy = <String, int>{};
  final counts = <String, int>{};
  for (final t in group.items) {
    final sign = t.type == TransactionType.income ? 1 : -1;
    byCcy[t.currency] = (byCcy[t.currency] ?? 0) + sign * t.amountCents;
    counts[t.currency] = (counts[t.currency] ?? 0) + 1;
  }
  if (byCcy.isEmpty) return '';
  final dominant = counts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  final cents = byCcy[dominant]!;
  final symbol = Currency.byCode(dominant).symbol;
  final body = '$symbol${(cents.abs() / 100).toStringAsFixed(2)}';
  final signed = cents < 0 ? '-$body' : body;
  final others = byCcy.length - 1;
  return others > 0 ? '$signed  +$others' : signed;
}


class _FilterChip extends ConsumerWidget {
  const _FilterChip({required this.filter});
  final TransactionsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final cat = filter.categoryId == null
        ? null
        : categories.where((x) => x.id == filter.categoryId).firstOrNull;
    String label;
    if (filter.dayIso != null) {
      label = filter.dayIso!;
    } else if (cat != null) {
      label = resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name;
    } else {
      label = '—';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text(label),
          avatar: Icon(LucideIcons.filter, size: 14, color: c.actionInk),
          onDeleted: () => ref
              .read(transactionsFilterProvider.notifier)
              .state = null,
        ),
      ),
    );
  }
}
