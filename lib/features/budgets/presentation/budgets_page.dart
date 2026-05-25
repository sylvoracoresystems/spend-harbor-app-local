import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/budget_form_controller.dart';

/// 预算列表页（设置入口）：展示全部预算并支持新建/进入编辑。
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allBudgetsProvider);

    return SubPageScaffold(
      title: l.settingsBudgets,
      actions: [
        IconButton(
          tooltip: l.budgetAdd,
          icon: const Icon(LucideIcons.plus),
          onPressed: () => context.push('/settings/budgets/new'),
        ),
      ],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l.budgetEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: c.border, indent: AppSpacing.x4),
            itemBuilder: (context, i) => _BudgetRow(b: rows[i]),
          );
        },
      ),
    );
  }
}

/// 单条预算行：展示 scope/period/金额，点击进入编辑。
class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({required this.b});
  final Budget b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final cat = b.categoryId == null
        ? null
        : categories.where((x) => x.id == b.categoryId).firstOrNull;

    final scopeLabel = b.scope == BudgetScope.total
        ? l.budgetScopeTotal
        : cat == null
            ? l.budgetScopeCategory
            : (resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name);
    final periodLabel = switch (b.period) {
      BudgetPeriod.week => l.budgetPeriodWeek,
      BudgetPeriod.month => l.budgetPeriodMonth,
      BudgetPeriod.year => l.budgetPeriodYear,
    };
    final amount =
        '${Currency.byCode(b.currency).symbol}${(b.amountCents / 100).toStringAsFixed(2)}';

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.action.withValues(alpha: 0.15),
          borderRadius: AppRadius.brFull,
        ),
        child: Icon(LucideIcons.target, color: c.action, size: 18),
      ),
      title: Text(
        scopeLabel,
        style: AppTypography.sm.copyWith(
          color: c.actionInk,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
      subtitle: Text(
        '$periodLabel · $amount · ${b.startsOn}',
        style: AppTypography.xs.copyWith(color: c.textMuted),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () => context.push('/settings/budgets/${b.id}/edit'),
    );
  }
}
