import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/filter_pill.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/stats_filter.dart';
import '../../application/stats_filter_provider.dart';

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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
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
                    onChanged: (v) =>
                        ref.read(statsFilterProvider.notifier).setSourceId(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: c.borderSoft),
                borderRadius: BorderRadius.circular(999),
              ),
              child: SegmentedButton<StatsPeriod>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  side: const WidgetStatePropertyAll(BorderSide.none),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return c.mintSoft;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return c.actionInk;
                    }
                    return c.textMuted;
                  }),
                  overlayColor:
                      WidgetStatePropertyAll(c.mintSoft.withValues(alpha: 0.6)),
                  elevation: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected) ? 2 : 0;
                  }),
                  shadowColor: WidgetStatePropertyAll(
                    c.action.withValues(alpha: 0.25),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: StatsPeriod.week,
                    label: Text(l.statsPeriodWeek),
                  ),
                  ButtonSegment(
                    value: StatsPeriod.month,
                    label: Text(l.statsPeriodMonth),
                  ),
                  ButtonSegment(
                    value: StatsPeriod.year,
                    label: Text(l.statsPeriodYear),
                  ),
                ],
                selected: {f.period},
                onSelectionChanged: (s) => ref
                    .read(statsFilterProvider.notifier)
                    .setPeriod(s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

