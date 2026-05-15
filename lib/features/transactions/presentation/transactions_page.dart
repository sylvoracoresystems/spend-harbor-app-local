import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
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
    final selection = ref.watch(selectionControllerProvider);
    final selecting = selection.isNotEmpty;

    // Stats 跳转应用 category/tag/dateRange 临时筛选时弹 toast 提示。
    ref.listen<TransactionsFilter?>(transactionsFilterProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      if (prev == next) return;
      final msg = _filterLabel(context, ref, next);
      if (msg == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.funnel, size: 16, color: c.textMuted),
              const SizedBox(width: AppSpacing.x2),
              Flexible(
                child: Text(
                  msg,
                  style: AppTypography.sm.copyWith(color: c.textBody),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              InkWell(
                borderRadius: AppRadius.brLg,
                onTap: () {
                  ref.read(transactionsFilterProvider.notifier).state = null;
                  messenger.hideCurrentSnackBar();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: AppSpacing.x1,
                  ),
                  child: Text(
                    l.txFilterClear,
                    style: AppTypography.sm.copyWith(
                      color: c.action,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 2500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: BorderSide(color: c.border),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x6,
            vertical: AppSpacing.x4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    });

    return RootPageScaffold(
      title: l.tabTransactions,
      customAppBar:
          selecting ? _buildSelectionAppBar(context, ref, selection) : null,
      actions: [
        IconButton(
          tooltip: l.recycleBinTitle,
          icon: const Icon(LucideIcons.trash2),
          onPressed: () => context.push('/transactions/recycle-bin'),
        ),
      ],
      pageHeader: const DashboardFilterBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return RootPageEmpty(text: l.txListEmpty);
          }
          final groups = groupByDay(rows);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            itemCount: groups.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _ListSummary(rows: rows);
              return _DayGroupView(group: groups[i - 1]);
            },
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

/// 从 [filter] 派生 toast 文案。返回 null 表示无可展示的临时筛选。
String? _filterLabel(
  BuildContext context,
  WidgetRef ref,
  TransactionsFilter filter,
) {
  final l = AppL10n.of(context);
  if (filter.categoryId != null) {
    final categories = ref.read(allCategoriesProvider).valueOrNull ?? const [];
    final cat =
        categories.where((x) => x.id == filter.categoryId).firstOrNull;
    final name = cat == null
        ? filter.categoryId!
        : (resolveDefaultName(l, cat.nameKey) ?? cat.name);
    return l.txFilterAppliedCategory(name);
  }
  if (filter.tagId != null) {
    final tags = ref.read(allTagsProvider).valueOrNull ?? const [];
    final tag = tags.where((x) => x.id == filter.tagId).firstOrNull;
    final name = tag?.name ?? filter.tagId!;
    return l.txFilterAppliedTag(name);
  }
  if (filter.untagged) return l.txFilterAppliedUntagged;
  if (filter.hasDateRange) return l.txFilterAppliedDateRange;
  return null;
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

/// 列表顶部汇总：左侧笔数，右侧各币种 income/expense 合计。
/// 单币种 → 单行；多币种 → 笔数占第一行，多币种行右对齐堆叠。
class _ListSummary extends StatelessWidget {
  const _ListSummary({required this.rows});
  final List<Transaction> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final income = <String, int>{};
    final expense = <String, int>{};
    for (final t in rows) {
      if (t.type == TransactionType.income) {
        income[t.currency] = (income[t.currency] ?? 0) + t.amountCents;
      } else {
        expense[t.currency] = (expense[t.currency] ?? 0) + t.amountCents;
      }
    }
    final currencies = <String>{...income.keys, ...expense.keys}.toList()
      ..sort();
    final showCcy = currencies.length > 1;
    final countText = Text(
      l.txListCount(rows.length),
      style: AppTypography.xs.copyWith(
        color: c.textMuted,
        fontWeight: AppTypography.weightSemibold,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x1,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          countText,
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final ccy in currencies)
                _SummaryAmounts(
                  currency: ccy,
                  incomeCents: income[ccy] ?? 0,
                  expenseCents: expense[ccy] ?? 0,
                  showCurrencyLabel: showCcy,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryAmounts extends StatelessWidget {
  const _SummaryAmounts({
    required this.currency,
    required this.incomeCents,
    required this.expenseCents,
    required this.showCurrencyLabel,
  });
  final String currency;
  final int incomeCents;
  final int expenseCents;
  final bool showCurrencyLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final symbol = Currency.byCode(currency).symbol;
    final numStyle = AppTypography.xs.merge(AppTypography.mono).copyWith(
          fontWeight: AppTypography.weightSemibold,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCurrencyLabel) ...[
            Text(
              currency,
              style: AppTypography.xs.copyWith(color: c.textMuted),
            ),
            const SizedBox(width: AppSpacing.x2),
          ],
          Text(
            '$symbol${(incomeCents / 100).toStringAsFixed(2)}',
            style: numStyle.copyWith(color: c.income),
          ),
          const SizedBox(width: AppSpacing.x3),
          Text(
            '-$symbol${(expenseCents / 100).toStringAsFixed(2)}',
            style: numStyle.copyWith(color: c.expense),
          ),
        ],
      ),
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
