part of '../dashboard_page.dart';

/// Dashboard 预算卡片：列出当前周期的预算进度，空列表则不渲染。
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
                  if (i < list.length - 1) Divider(height: 1, color: c.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条预算进度行：名称 + 已用/总额 + 进度条。
class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({required this.progress});
  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final b = progress.budget;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final cat = b.categoryId == null ? null : categories.byId(b.categoryId!);
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
