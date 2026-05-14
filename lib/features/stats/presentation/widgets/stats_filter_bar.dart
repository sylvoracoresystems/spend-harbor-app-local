import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database_provider.dart';
import '../../../../domain/value_objects/currency.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
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
                  child: _PillDropdown<String>(
                    value: f.currency,
                    icon: Icons.attach_money,
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
                    icon: Icons.account_balance_wallet_outlined,
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

class _PillDropdown<T> extends StatelessWidget {
  const _PillDropdown({
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surfacePress,
        border: Border.all(color: c.borderSoft),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                isDense: true,
                style: AppTypography.sm.copyWith(color: c.textPrimary),
                icon: Icon(Icons.expand_more, size: 18, color: c.textMuted),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
