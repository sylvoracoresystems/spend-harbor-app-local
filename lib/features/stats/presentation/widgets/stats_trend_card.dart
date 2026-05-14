import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../application/stats_controller.dart';
import '../../application/stats_filter.dart';
import '../../application/stats_filter_provider.dart';

class StatsTrendCard extends ConsumerWidget {
  const StatsTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final dataAsync = ref.watch(trendBucketsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 18, color: c.textPrimary),
                const SizedBox(width: 6),
                Text(
                  l.statsTrendTitle,
                  style: AppTypography.base.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _RangeChip(filter: f, locale: locale),
            const SizedBox(height: AppSpacing.x3),
            SizedBox(
              height: 180,
              child: dataAsync.when(
                loading: () => Center(
                  child: Text(
                    l.statsLoading,
                    style: AppTypography.xs.copyWith(color: c.textMuted),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    l.statsError,
                    style: AppTypography.xs.copyWith(color: c.expense),
                  ),
                ),
                data: (rows) => _Bars(
                  rows: rows,
                  selected: f.selectedBucketStart,
                  period: f.period,
                  locale: locale,
                  onTap: (start) => ref
                      .read(statsFilterProvider.notifier)
                      .selectBucket(start),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.filter, required this.locale});
  final StatsFilter filter;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = filter.selectedBucketStart;
    String text;
    switch (filter.period) {
      case StatsPeriod.week:
        final end = DateTime(s.year, s.month, s.day + 6);
        text =
            '${DateFormat.MMMd(locale).format(s)} – ${DateFormat.MMMd(locale).format(end)}';
        break;
      case StatsPeriod.month:
        text = DateFormat.yMMMM(locale).format(s);
        break;
      case StatsPeriod.year:
        text = DateFormat.y(locale).format(s);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.mintSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTypography.xs.copyWith(color: c.actionInk),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.rows,
    required this.selected,
    required this.period,
    required this.locale,
    required this.onTap,
  });

  final List<TrendBucketValues> rows;
  final DateTime selected;
  final StatsPeriod period;
  final String locale;
  final ValueChanged<DateTime> onTap;

  String _label(DateTime start) {
    switch (period) {
      case StatsPeriod.week:
        return DateFormat.MMMd(locale).format(start);
      case StatsPeriod.month:
        return DateFormat.MMM(locale).format(start);
      case StatsPeriod.year:
        return DateFormat.y(locale).format(start);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final maxY = rows
        .map((r) =>
            r.incomeCents > r.expenseCents ? r.incomeCents : r.expenseCents)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _label(rows[i].bucket.start),
                    style: AppTypography.xs.copyWith(color: c.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              final i = response!.spot!.touchedBarGroupIndex;
              onTap(rows[i].bucket.start);
            }
          },
        ),
        barGroups: [
          for (var i = 0; i < rows.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              showingTooltipIndicators:
                  rows[i].bucket.start == selected ? const [0, 1] : const [],
              barRods: [
                BarChartRodData(
                  toY: rows[i].incomeCents.toDouble(),
                  color: c.income,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: rows[i].expenseCents.toDouble(),
                  color: c.expense,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
