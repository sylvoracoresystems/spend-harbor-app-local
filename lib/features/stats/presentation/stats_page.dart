import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/stats_controller.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final barsAsync = ref.watch(dailyExpenseBarsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabStats),
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
      body: barsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bars) {
          final currency = dominantCurrency(bars);
          final hasData = bars.any((b) => b.byCurrency.isNotEmpty);
          if (!hasData) {
            return Center(
              child: Text(
                l.statsEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: [
              _TrendCard(bars: bars, currency: currency),
              const SizedBox(height: AppSpacing.x4),
              _CategoryDonutCard(currency: currency),
              const SizedBox(height: AppSpacing.x4),
              _TagDonutCard(currency: currency),
            ],
          );
        },
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.bars, required this.currency});
  final List<DailyExpenseBar> bars;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final maxValue = bars
        .map((b) => b.totalCentsForCurrency(currency))
        .fold<int>(0, (a, b) => b > a ? b : a);
    final maxY = (maxValue == 0 ? 100 : maxValue * 1.15).toDouble();
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.statsTrendTitle,
                style: AppTypography.sm.copyWith(
                  color: c.actionInk,
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
              Text(
                l.statsCurrencyHint(currency),
                style: AppTypography.xs.copyWith(color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        if (value == meta.max) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${Currency.byCode(currency).symbol}${(value / 100).toStringAsFixed(0)}',
                              style: AppTypography.xs
                                  .copyWith(color: c.textMuted),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final d = value.toInt() + 1;
                        // 每 5 天显示一次
                        if (d == 1 || d % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$d',
                              style: AppTypography.xs
                                  .copyWith(color: c.textMuted),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i]
                              .totalCentsForCurrency(currency)
                              .toDouble(),
                          color: c.expense,
                          width: 6,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _kDonutPalette = <int>[
  0xff10b981,
  0xfff97316,
  0xff0ea5e9,
  0xffec4899,
  0xff8b5cf6,
  0xffef4444,
  0xff6366f1,
  0xff14b8a6,
  0xfff59e0b,
  0xff64748b,
];

class _CategoryDonutCard extends ConsumerWidget {
  const _CategoryDonutCard({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(categorySlicesProvider);
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const <Category>[];
    final slices = async.valueOrNull ?? const [];
    if (slices.isEmpty) return const SizedBox.shrink();
    String labelOf(String id) {
      final cat = cats.where((x) => x.id == id).firstOrNull;
      if (cat == null) return '—';
      return resolveDefaultName(AppL10n.of(context), cat.nameKey) ?? cat.name;
    }
    return _DonutCard(
      title: l.statsByCategory,
      currency: currency,
      entries: [
        for (var i = 0; i < slices.length; i++)
          _DonutEntry(
            label: labelOf(slices[i].categoryId),
            valueCents: slices[i].totalCents,
            color: Color(_kDonutPalette[i % _kDonutPalette.length]),
          ),
      ],
      muted: c.textMuted,
      ink: c.actionInk,
    );
  }
}

class _TagDonutCard extends ConsumerWidget {
  const _TagDonutCard({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(tagSlicesProvider);
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const <Tag>[];
    final slices = async.valueOrNull ?? const [];
    String labelOf(String id) {
      final tag = tags.where((x) => x.id == id).firstOrNull;
      if (tag == null) return '—';
      return resolveDefaultName(AppL10n.of(context), tag.nameKey) ?? tag.name;
    }
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: slices.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.statsByTag,
                  style: AppTypography.sm.copyWith(
                    color: c.actionInk,
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  l.statsNoTags,
                  style: AppTypography.xs.copyWith(color: c.textMuted),
                ),
              ],
            )
          : _DonutBody(
              title: l.statsByTag,
              currency: currency,
              entries: [
                for (var i = 0; i < slices.length; i++)
                  _DonutEntry(
                    label: labelOf(slices[i].tagId),
                    valueCents: slices[i].totalCents,
                    color: Color(_kDonutPalette[i % _kDonutPalette.length]),
                  ),
              ],
              muted: c.textMuted,
              ink: c.actionInk,
            ),
    );
  }
}

class _DonutEntry {
  const _DonutEntry({
    required this.label,
    required this.valueCents,
    required this.color,
  });
  final String label;
  final int valueCents;
  final Color color;
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({
    required this.title,
    required this.currency,
    required this.entries,
    required this.muted,
    required this.ink,
  });
  final String title;
  final String currency;
  final List<_DonutEntry> entries;
  final Color muted;
  final Color ink;

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
      child: _DonutBody(
        title: title,
        currency: currency,
        entries: entries,
        muted: muted,
        ink: ink,
      ),
    );
  }
}

class _DonutBody extends StatelessWidget {
  const _DonutBody({
    required this.title,
    required this.currency,
    required this.entries,
    required this.muted,
    required this.ink,
  });
  final String title;
  final String currency;
  final List<_DonutEntry> entries;
  final Color muted;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (a, b) => a + b.valueCents);
    final symbol = Currency.byCode(currency).symbol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.sm.copyWith(
            color: ink,
            fontWeight: AppTypography.weightSemibold,
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: [
                for (final e in entries)
                  PieChartSectionData(
                    value: e.valueCents.toDouble(),
                    color: e.color,
                    title: '',
                    radius: 28,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: e.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    e.label,
                    style: AppTypography.xs.copyWith(color: ink),
                  ),
                ),
                Text(
                  '$symbol${(e.valueCents / 100).toStringAsFixed(2)}'
                  '  ·  ${total == 0 ? 0 : ((e.valueCents / total) * 100).toStringAsFixed(0)}%',
                  style: AppTypography.xs
                      .merge(AppTypography.mono)
                      .copyWith(color: muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
