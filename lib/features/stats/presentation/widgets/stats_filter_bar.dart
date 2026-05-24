import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/filter_pill.dart';
import '../../../../shared/widgets/pill_segmented.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/stats_filter.dart';
import '../../application/stats_filter_provider.dart';

/// Stats 顶部 pageHeader：与 DashboardFilterBar 风格一致——满宽 + surface 底色
/// + 底部 1pt 分割线，紧贴 AppBar 而不是浮在 bgMint 上的 Card。
class StatsFilterBar extends ConsumerWidget {
  const StatsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final sources = ref.watch(allSourcesProvider).valueOrNull ?? const [];
    final filteredSources =
        sources.where((s) => s.currency == f.currency).toList();

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
        children: [
          Row(
            children: [
              Expanded(
                child: CurrencyFilterDropdown(
                  value: f.currency,
                  label: l.dashFilterCurrency,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(statsFilterProvider.notifier).setCurrency(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: SourceFilterDropdown(
                  value: f.sourceId,
                  label: l.dashFilterSource,
                  allLabel: l.statsFilterAllSources,
                  sources: filteredSources,
                  onChanged:
                      (v) =>
                          ref.read(statsFilterProvider.notifier).setSourceId(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          PillSegmented<StatsPeriod>(
            value: f.period,
            segments: [
              PillSegment(value: StatsPeriod.week, label: l.statsPeriodWeek),
              PillSegment(value: StatsPeriod.month, label: l.statsPeriodMonth),
              PillSegment(value: StatsPeriod.year, label: l.statsPeriodYear),
            ],
            onChanged:
                (v) => ref.read(statsFilterProvider.notifier).setPeriod(v),
          ),
        ],
      ),
    );
  }
}
