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
            _Legend(
              incomeColor: c.income,
              expenseColor: c.expense,
              incomeLabel: l.statsTypeIncome,
              expenseLabel: l.statsTypeExpense,
              mutedColor: c.textBody,
            ),
            const SizedBox(height: AppSpacing.x2),
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
    final rawMax = rows
        .map((r) =>
            r.incomeCents > r.expenseCents ? r.incomeCents : r.expenseCents)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final maxY = rawMax == 0 ? 100.0 : rawMax * 1.05;
    final interval = maxY / 4;
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: c.borderSoft,
            strokeWidth: 1,
            dashArray: const [3, 3],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: c.borderSoft, width: 1),
            bottom: BorderSide(color: c.borderSoft, width: 1),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                if (v == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _shortAmount(v),
                    style: AppTypography.xs.copyWith(color: c.textMuted),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
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
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: rows[i].incomeCents.toDouble(),
                  color: rows[i].bucket.start == selected
                      ? c.income
                      : c.income.withValues(alpha: 0.4),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: rows[i].expenseCents.toDouble(),
                  color: rows[i].bucket.start == selected
                      ? c.expense
                      : c.expense.withValues(alpha: 0.4),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.incomeColor,
    required this.expenseColor,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.mutedColor,
  });

  final Color incomeColor;
  final Color expenseColor;
  final String incomeLabel;
  final String expenseLabel;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: incomeColor, label: incomeLabel, textColor: mutedColor),
        const SizedBox(width: 20),
        _LegendDot(
            color: expenseColor, label: expenseLabel, textColor: mutedColor),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.sm.copyWith(color: textColor),
        ),
      ],
    );
  }
}

/// 把 cents 缩为短金额标签（轴标）：始终用 k 单位，无币种符号。
/// 0.5k 以下保留两位小数（"0.05k"），其余 1 位小数（"3.8k"）；百万以上转 "M"。
String _shortAmount(double cents) {
  final dollars = cents / 100;
  final abs = dollars.abs();
  if (abs >= 1000000) return '${(dollars / 1000000).toStringAsFixed(1)}M';
  final inK = dollars / 1000;
  if (abs >= 500) return '${inK.toStringAsFixed(1)}k';
  return '${inK.toStringAsFixed(2)}k';
}
