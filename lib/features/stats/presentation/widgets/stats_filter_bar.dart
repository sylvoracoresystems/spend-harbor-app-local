import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database_provider.dart';
import '../../../../domain/value_objects/currency.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/stats_filter.dart';
import '../../application/stats_filter_provider.dart';

class StatsFilterBar extends ConsumerWidget {
  const StatsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
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
                  child: _PillDropdown<String>(
                    value: f.currency,
                    label: l.statsFilterCurrency,
                    items: [
                      for (final c in Currency.all)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.code} ${c.symbol}'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(statsFilterProvider.notifier).setCurrency(v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: _PillDropdown<String?>(
                    value: f.sourceId,
                    label: l.statsFilterSource,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l.statsFilterAllSources),
                      ),
                      for (final s in filteredSources)
                        DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                    ],
                    onChanged: (v) =>
                        ref.read(statsFilterProvider.notifier).setSourceId(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<StatsPeriod>(
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

class _PillDropdown<T> extends StatelessWidget {
  const _PillDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
