import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/filter_pill.dart';
import '../../../shared/widgets/month_dropdown.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/dashboard_filter_provider.dart';

/// Dashboard / Transactions 共用顶部过滤条：月份 + 货币 + 来源。
class DashboardFilterBar extends ConsumerWidget {
  const DashboardFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final filter = ref.watch(dashboardFilterProvider);
    final sourcesAsync = ref.watch(allSourcesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthDropdown(
            value: ym,
            onChanged: (ym) =>
                ref.read(currentMonthProvider.notifier).set(ym),
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: CurrencyFilterDropdown(
                  value: filter.currency,
                  onChanged: (v) =>
                      ref.read(dashboardFilterProvider.notifier).setCurrency(v),
                  label: l.dashFilterCurrency,
                  allLabel: l.dashFilterAll,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: SourceFilterDropdown(
                  value: filter.sourceId,
                  onChanged: (v) =>
                      ref.read(dashboardFilterProvider.notifier).setSource(v),
                  label: l.dashFilterSource,
                  allLabel: l.dashFilterAll,
                  sources: sourcesAsync.maybeWhen(
                    data: (rows) => rows,
                    orElse: () => const <Source>[],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
