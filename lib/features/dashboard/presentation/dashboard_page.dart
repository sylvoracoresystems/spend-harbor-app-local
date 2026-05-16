import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../data_io/presentation/backup_reminder_banner.dart';
import '../../transactions/presentation/transaction_list_row.dart';
import '../application/budget_progress_provider.dart';
import '../application/dashboard_summary_controller.dart';
import 'dashboard_filter_bar.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return RootPageScaffold(
      title: l.tabDashboard,
      pageHeader: const DashboardFilterBar(),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (metrics) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: [
              const BackupReminderBanner(),
              _MetricsGrid(metrics: metrics),
              if (metrics.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x6),
                  child: RootPageEmpty(text: l.dashEmpty),
                ),
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
  const _MetricsGrid({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    // Net 金额按符号上色保留语义；卡片底色统一走 mint 与 income/expense 区分。
    final netColor = metrics.netCents >= 0 ? c.income : c.expense;

    final cards = <Widget>[
      _TileMetricCard(
        label: l.dashIncome,
        icon: LucideIcons.coins,
        accentColor: c.income,
        bgStart: c.incomeSoft,
        bgEnd: Color.lerp(c.incomeSoft, c.income, 0.18)!,
        amount: _formatAmount(
          metrics.incomeCents,
          metrics.dominantCurrency,
          signed: true,
        ),
        currencyBadge: metrics.dominantCurrency,
        otherCurrencyCount: metrics.otherCurrencyCount,
      ),
      _TileMetricCard(
        label: l.dashExpense,
        icon: LucideIcons.shoppingBag,
        accentColor: c.expense,
        bgStart: c.expenseSoft,
        bgEnd: Color.lerp(c.expenseSoft, c.expense, 0.18)!,
        amount: _formatAmount(
          metrics.expenseCents,
          metrics.dominantCurrency,
          signed: true,
          forceNegative: true,
        ),
        currencyBadge: metrics.dominantCurrency,
        otherCurrencyCount: metrics.otherCurrencyCount,
      ),
      // Net：左上始终走品牌 mint（与 income/expense 卡形成可识别差异），
      // 右下走符号色（≥0 → income 绿，<0 → expense 红），背景对角渐变即「品牌→符号」。
      _TileMetricCard(
        label: l.dashNet,
        icon: LucideIcons.scale,
        accentColor: netColor,
        bgStart: c.mintTint,
        bgEnd: Color.lerp(c.mintTint, netColor, 0.35)!,
        amount: _formatAmount(
          metrics.netCents,
          metrics.dominantCurrency,
          signed: true,
        ),
        currencyBadge: metrics.dominantCurrency,
        otherCurrencyCount: metrics.otherCurrencyCount,
      ),
      _TileMetricCard(
        label: l.dashCount,
        icon: LucideIcons.listChecks,
        accentColor: c.info,
        bgStart: c.infoSoft,
        bgEnd: Color.lerp(c.infoSoft, c.info, 0.18)!,
        amount: '${metrics.transactionCount}',
        currencyBadge: null,
        otherCurrencyCount: 0,
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.x3,
      crossAxisSpacing: AppSpacing.x3,
      childAspectRatio: 1.35,
      children: cards,
    );
  }
}

class _TileMetricCard extends StatelessWidget {
  const _TileMetricCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.bgStart,
    required this.bgEnd,
    required this.amount,
    required this.currencyBadge,
    required this.otherCurrencyCount,
  });
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color bgStart;
  final Color bgEnd;
  final String amount;
  final String? currencyBadge;
  final int otherCurrencyCount;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tile icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: AppRadius.brLg,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              if (currencyBadge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    otherCurrencyCount > 0
                        ? '$currencyBadge  ${l.dashOthersBadge(otherCurrencyCount)}'
                        : currencyBadge!,
                    style: AppTypography.xs.copyWith(
                      color: accentColor,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: AppTypography.sm.copyWith(
              color: c.textBody,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.xl.merge(AppTypography.mono).copyWith(
                    color: accentColor,
                    fontWeight: AppTypography.weightBold,
                  ),
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
                TransactionListRow(tx: rows[i]),
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
            borderRadius: AppRadius.brFull,
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

String _formatAmount(
  int cents,
  String? code, {
  bool signed = false,
  bool forceNegative = false,
}) {
  // 无数据：占位 0.00（不带符号），统一对齐视觉。
  if (code == null) return '0.00';
  final symbol = Currency.byCode(code).symbol;
  final abs = cents.abs();
  final body = '$symbol${(abs / 100).toStringAsFixed(2)}';
  if (forceNegative && cents > 0) return '-$body';
  if (!signed || cents == 0) return body;
  return cents < 0 ? '-$body' : '+$body';
}
