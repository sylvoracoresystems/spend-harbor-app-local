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
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/transactions_list_controller.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _MonthSwitcher(value: ym),
              ),
            ),
      body: async.when(
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
      ),
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

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher({required this.value});
  final YearMonth value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ctrl = ref.read(currentMonthProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: l.txMonthPrev,
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: ctrl.prev,
          ),
          const SizedBox(width: AppSpacing.x4),
          Text(
            value.key,
            style: AppTypography.base.copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          IconButton(
            tooltip: l.txMonthNext,
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: ctrl.next,
          ),
        ],
      ),
    );
  }
}

class _DayGroupView extends ConsumerWidget {
  const _DayGroupView({required this.group});
  final DayGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: AppSpacing.x2,
            ),
            child: Text(
              _formatDayLabel(context, group.date),
              style: AppTypography.xs.copyWith(
                color: c.textMuted,
                fontWeight: AppTypography.weightMedium,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.brXl,
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  _TransactionRow(tx: group.items[i]),
                  if (i < group.items.length - 1)
                    Divider(height: 1, color: c.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final sources = ref.watch(allSourcesProvider).valueOrNull ?? const [];
    final cat = categories.where((x) => x.id == tx.categoryId).firstOrNull;
    final src = sources.where((x) => x.id == tx.sourceId).firstOrNull;
    final isExpense = tx.type == TransactionType.expense;
    final amountColor = isExpense ? c.expense : c.income;
    final sign = isExpense ? '-' : '+';
    final symbol = Currency.byCode(tx.currency).symbol;
    final amount =
        '$sign$symbol${(tx.amountCents / 100).toStringAsFixed(2)}';
    final selection = ref.watch(selectionControllerProvider);
    final selectionCtrl = ref.read(selectionControllerProvider.notifier);
    final selecting = selection.isNotEmpty;
    final selected = selection.contains(tx.id);

    return InkWell(
      onTap: () {
        if (selecting) {
          selectionCtrl.toggle(tx.id);
        } else {
          context.push('/transactions/${tx.id}/edit');
        }
      },
      onLongPress: () => selectionCtrl.toggle(tx.id),
      borderRadius: AppRadius.brXl,
      child: Container(
        color: selected ? c.mintSoft : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        child: Row(
          children: [
            if (selecting) ...[
              Icon(
                selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 20,
                color: selected ? c.action : c.textMuted,
              ),
              const SizedBox(width: AppSpacing.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat == null
                        ? '—'
                        : (resolveDefaultName(AppL10n.of(context), cat.nameKey) ??
                            cat.name),
                    style: AppTypography.sm.copyWith(
                      color: c.actionInk,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tx.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.xs.copyWith(color: c.textBody),
                      ),
                    ),
                  if (src != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        resolveDefaultName(AppL10n.of(context), src.nameKey) ??
                            src.name,
                        style: AppTypography.xs.copyWith(color: c.textMuted),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Text(
              amount,
              style: AppTypography.sm
                  .merge(AppTypography.mono)
                  .copyWith(
                    color: amountColor,
                    fontWeight: AppTypography.weightSemibold,
                  ),
            ),
          ],
        ),
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
  final ds =
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  if (isToday) return '${l.dayToday} · $ds';
  if (isYesterday) return '${l.dayYesterday} · $ds';
  return ds;
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
