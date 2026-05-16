import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../application/stats_buckets.dart';
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
                Icon(Icons.insert_chart, size: 18, color: c.action),
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
            const SizedBox(height: AppSpacing.x1),
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
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
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
        borderRadius: AppRadius.brLg,
      ),
      child: Text(
        text,
        style: AppTypography.xs.copyWith(color: c.actionInk),
      ),
    );
  }
}

class _Bars extends StatefulWidget {
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

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> {
  static const double _yAxisWidth = 36;
  static const double _bottomReserved = 28;

  final ScrollController _ctrl = ScrollController();
  double? _visibleMaxY;
  bool _didInitialJump = false;
  double _barSlot = 48; // 实际宽度按 viewport / defaultBucketCount 算

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _Bars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rows.length != oldWidget.rows.length) {
      // 桶数变了（period 切换 / filter 变 → 数据跨度变）→ 需要重新对齐
      _visibleMaxY = null;
      _didInitialJump = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
    }
  }

  /// 默认把视口贴到最右端（最近的桶），更直观。
  void _jumpToEnd() {
    if (!_ctrl.hasClients) return;
    final maxExt = _ctrl.position.maxScrollExtent;
    if (maxExt > 0 && _ctrl.offset != maxExt) {
      _ctrl.jumpTo(maxExt);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() => _recompute();

  void _recompute() {
    if (!_ctrl.hasClients) return;
    final vw = _ctrl.position.viewportDimension;
    final offset = _ctrl.offset;
    final start =
        (offset / _barSlot).floor().clamp(0, widget.rows.length - 1);
    final end =
        ((offset + vw) / _barSlot).ceil().clamp(start + 1, widget.rows.length);
    final next = _maxOver(widget.rows.sublist(start, end));
    if (next != _visibleMaxY) setState(() => _visibleMaxY = next);
  }

  double _maxOver(Iterable<TrendBucketValues> rs) {
    final raw = rs
        .map((r) => math.max(r.incomeCents, r.expenseCents))
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    return raw == 0 ? 100.0 : raw * 1.05;
  }

  String _label(DateTime start) {
    switch (widget.period) {
      case StatsPeriod.week:
        return DateFormat.MMMd(widget.locale).format(start);
      case StatsPeriod.month:
        return DateFormat.MMM(widget.locale).format(start);
      case StatsPeriod.year:
        return DateFormat.y(widget.locale).format(start);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 视口里目标可见桶数：按 viewport 自适应，每根柱子目标宽度 ~56pt，
        // 不少于 defaultBucketCount（窄屏的最低底线）。
        // 例：iPhone 322pt → 5~6 桶；iPad 横屏 ~1000pt → 17 桶左右。
        final viewport = constraints.maxWidth - _yAxisWidth;
        final minCount = defaultBucketCount(widget.period);
        final visibleCount = math.max(
          minCount,
          (viewport / 56).floor(),
        );
        final scrollable = widget.rows.length > visibleCount;
        if (!scrollable) {
          final maxY = _maxOver(widget.rows);
          return _buildChart(
            context,
            maxY: maxY,
            showLeftTitles: true,
          );
        }
        // 滚动模式：viewport 正好放 visibleCount 个桶，slot 宽度由此推算
        _barSlot = viewport / visibleCount;
        final contentWidth = widget.rows.length * _barSlot;
        // 首次进入滚动模式：默认显示最右端（最近）的 visibleCount 个桶
        final initialVisible =
            widget.rows.sublist(widget.rows.length - visibleCount);
        final maxY = _visibleMaxY ?? _maxOver(initialVisible);
        if (!_didInitialJump) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _jumpToEnd();
            _didInitialJump = true;
          });
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _yAxisWidth, child: _buildYAxis(context, maxY)),
            Expanded(
              child: SingleChildScrollView(
                controller: _ctrl,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: contentWidth,
                  child: _buildChart(
                    context,
                    maxY: maxY,
                    showLeftTitles: false,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYAxis(BuildContext context, double maxY) {
    final c = context.appColors;
    final interval = maxY / 4;
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.start,
        gridData: const FlGridData(show: false),
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
              reservedSize: _yAxisWidth,
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
              reservedSize: _bottomReserved,
              getTitlesWidget: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        barGroups: const [],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context, {
    required double maxY,
    required bool showLeftTitles,
  }) {
    final c = context.appColors;
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
            left: showLeftTitles
                ? BorderSide(color: c.borderSoft, width: 1)
                : BorderSide.none,
            bottom: BorderSide(color: c.borderSoft, width: 1),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showLeftTitles,
              interval: interval,
              reservedSize: showLeftTitles ? _yAxisWidth : 0,
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
              reservedSize: _bottomReserved,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= widget.rows.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _label(widget.rows[i].bucket.start),
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
              widget.onTap(widget.rows[i].bucket.start);
            }
          },
        ),
        barGroups: [
          for (var i = 0; i < widget.rows.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: widget.rows[i].incomeCents.toDouble(),
                  color: widget.rows[i].bucket.start == widget.selected
                      ? c.income
                      : c.income.withValues(alpha: 0.4),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: widget.rows[i].expenseCents.toDouble(),
                  color: widget.rows[i].bucket.start == widget.selected
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
