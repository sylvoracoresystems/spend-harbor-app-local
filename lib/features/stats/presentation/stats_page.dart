import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
