import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/budget_progress_provider.dart';
import '../application/dashboard_summary_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabDashboard),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x2),
            child: Text(
              ym.key,
              style: AppTypography.xs.copyWith(color: c.textMuted),
            ),
          ),
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (summary) {
          if (summary.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: Text(
                  l.dashEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.sm.copyWith(color: c.textMuted),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: [
              _MetricsGrid(summary: summary),
              const SizedBox(height: AppSpacing.x6),
              const _BudgetsSection(),
              _RecentSection(asyncRows: recentAsync),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    // 4 张卡：收入 / 支出 / 净额 / 笔数
    // 多币种：在前三张卡内分行展示
    return LayoutBuilder(
      builder: (context, constraints) {
        // 宽屏：2 列；窄屏：1 列
        final cols = constraints.maxWidth >= 540 ? 2 : 1;
        final cards = <Widget>[
          _MetricCard(
            label: l.dashIncome,
            color: c.income,
            rows: [
              for (final s in summary.byCurrency)
                (currency: s.currency, cents: s.incomeCents),
            ],
          ),
          _MetricCard(
            label: l.dashExpense,
            color: c.expense,
            rows: [
              for (final s in summary.byCurrency)
                (currency: s.currency, cents: s.expenseCents),
            ],
          ),
          _MetricCard(
            label: l.dashNet,
            color: c.actionInk,
            signed: true,
            rows: [
              for (final s in summary.byCurrency)
                (currency: s.currency, cents: s.netCents),
            ],
          ),
          _CountCard(label: l.dashCount, count: summary.transactionCount),
        ];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: AppSpacing.x3,
          crossAxisSpacing: AppSpacing.x3,
          childAspectRatio: cols == 2 ? 2.0 : 2.8,
          children: cards,
        );
      },
    );
  }
}

typedef _CcyRow = ({String currency, int cents});

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.color,
    required this.rows,
    this.signed = false,
  });
  final String label;
  final Color color;
  final List<_CcyRow> rows;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.xs.copyWith(
              color: c.textMuted,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _formatAmount(r.cents, r.currency, signed: signed),
                style: AppTypography.lg
                    .merge(AppTypography.mono)
                    .copyWith(
                      color: color,
                      fontWeight: AppTypography.weightSemibold,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.xs.copyWith(
              color: c.textMuted,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            '$count',
            style: AppTypography.xxl.copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSection extends ConsumerWidget {
  const _RecentSection({required this.asyncRows});
  final AsyncValue<List<Transaction>> asyncRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final rows = asyncRows.valueOrNull ?? const <Transaction>[];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.dashRecent,
                style: AppTypography.xs.copyWith(
                  color: c.textMuted,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/transactions'),
                child: Text(
                  l.dashViewAll,
                  style: AppTypography.xs.copyWith(
                    color: c.action,
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
              ),
            ],
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
              for (var i = 0; i < rows.length; i++) ...[
                _RecentRow(tx: rows[i]),
                if (i < rows.length - 1)
                  Divider(height: 1, color: c.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentRow extends ConsumerWidget {
  const _RecentRow({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final cat = categories.where((x) => x.id == tx.categoryId).firstOrNull;
    final isExpense = tx.type == TransactionType.expense;
    final amount = _formatAmount(
      isExpense ? -tx.amountCents : tx.amountCents,
      tx.currency,
      signed: true,
    );
    final amountColor = isExpense ? c.expense : c.income;
    final catLabel = cat == null
        ? '—'
        : (resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name);
    return InkWell(
      onTap: () => context.push('/transactions/${tx.id}/edit'),
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
                    catLabel,
                    style: AppTypography.sm.copyWith(
                      color: c.actionInk,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tx.transactedOn,
                      style: AppTypography.xs.copyWith(color: c.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: AppTypography.sm.merge(AppTypography.mono).copyWith(
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

class _BudgetsSection extends ConsumerWidget {
  const _BudgetsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(budgetProgressListProvider);
    final list = async.valueOrNull ?? const <BudgetProgress>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: AppSpacing.x2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.dashBudgets,
                  style: AppTypography.xs.copyWith(
                    color: c.textMuted,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/settings/budgets'),
                  child: Text(
                    l.dashBudgetManage,
                    style: AppTypography.xs.copyWith(
                      color: c.action,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
              ],
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
                for (var i = 0; i < list.length; i++) ...[
                  _BudgetRow(progress: list[i]),
                  if (i < list.length - 1)
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

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({required this.progress});
  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final b = progress.budget;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final cat = b.categoryId == null
        ? null
        : categories.where((x) => x.id == b.categoryId).firstOrNull;
    final scopeLabel = b.scope == BudgetScope.total
        ? l.dashBudgetTotal
        : cat == null
            ? l.budgetScopeCategory
            : (resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name);
    final periodLabel = switch (b.period) {
      BudgetPeriod.week => l.budgetPeriodWeek,
      BudgetPeriod.month => l.budgetPeriodMonth,
      BudgetPeriod.year => l.budgetPeriodYear,
    };
    final symbol = Currency.byCode(b.currency).symbol;
    final spent = '$symbol${(progress.spentCents / 100).toStringAsFixed(2)}';
    final budget = '$symbol${(b.amountCents / 100).toStringAsFixed(2)}';
    final clamped = progress.ratio.clamp(0.0, 1.0);
    final progressColor = progress.overBudget ? c.expense : c.action;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$scopeLabel · $periodLabel',
                  style: AppTypography.sm.copyWith(
                    color: c.actionInk,
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
              ),
              Text(
                '$spent / $budget',
                style: AppTypography.xs
                    .merge(AppTypography.mono)
                    .copyWith(color: c.textBody),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (progress.overBudget)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.dashBudgetOver(_overAmount(progress)),
                style: AppTypography.xs.copyWith(
                  color: c.expense,
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _overAmount(BudgetProgress p) {
    final symbol = Currency.byCode(p.budget.currency).symbol;
    final over = (p.spentCents - p.budget.amountCents).abs();
    return '$symbol${(over / 100).toStringAsFixed(2)}';
  }
}

String _formatAmount(int cents, String code, {bool signed = false}) {
  final symbol = Currency.byCode(code).symbol;
  final abs = cents.abs();
  final body = '$symbol${(abs / 100).toStringAsFixed(2)}';
  if (!signed || cents == 0) return body;
  return cents < 0 ? '-$body' : '+$body';
}
