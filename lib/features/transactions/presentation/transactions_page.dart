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
    final async = ref.watch(transactionsOfMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabTransactions),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthSwitcher(value: ym),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l.txListEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          final groups = groupByDay(rows);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            itemCount: groups.length,
            itemBuilder: (context, i) => _DayGroupView(group: groups[i]),
          );
        },
      ),
    );
  }
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

    return InkWell(
      onTap: () => context.push('/transactions/${tx.id}/edit'),
      borderRadius: AppRadius.brXl,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        child: Row(
          children: [
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
