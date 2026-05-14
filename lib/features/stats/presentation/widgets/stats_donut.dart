import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

class DonutSlice {
  const DonutSlice({
    required this.color,
    required this.value,
    this.icon,
  });

  final Color color;
  final double value;

  /// 切片旁徽标使用的图标；为 null 时改用小圆点（用于标签场景）。
  final IconData? icon;
}

class StatsDonut extends StatelessWidget {
  const StatsDonut({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerAmount,
    required this.centerColor,
  });

  final List<DonutSlice> slices;
  final String centerLabel;
  final String centerAmount;
  final Color centerColor;

  static const double _centerRadius = 70;
  static const double _ringRadius = 26;
  static const double _badgeOffset = 1.7;
  static const double _badgeThreshold = 0.03;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final total = slices.fold<double>(0, (a, s) => a + s.value);

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 1.5,
              centerSpaceRadius: _centerRadius,
              sections: total <= 0
                  ? [
                      PieChartSectionData(
                        color: c.borderSoft,
                        value: 1,
                        radius: _ringRadius,
                        showTitle: false,
                      ),
                    ]
                  : _buildSections(context, total),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: AppTypography.xs.copyWith(
                  color: c.textMuted,
                  fontWeight: AppTypography.weightSemibold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                centerAmount,
                style: AppTypography.xl.copyWith(
                  fontWeight: AppTypography.weightBold,
                  fontFamily: 'monospace',
                  color: centerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context, double total) {
    final c = context.appColors;
    final result = <PieChartSectionData>[];
    double cum = 0;
    for (final s in slices) {
      final pct = s.value / total;
      final midValue = cum + s.value / 2;
      final degFromStart = (midValue / total) * 360;
      final degFromEast = -90 + degFromStart;
      final rad = degFromEast * math.pi / 180;
      final isRight = math.cos(rad) >= 0;
      result.add(
        PieChartSectionData(
          color: s.color,
          value: s.value,
          radius: _ringRadius,
          showTitle: false,
          badgeWidget: pct >= _badgeThreshold
              ? _SliceBadge(
                  color: s.color,
                  icon: s.icon,
                  percent: (pct * 100).round(),
                  isRight: isRight,
                  textColor: c.textBody,
                )
              : null,
          badgePositionPercentageOffset: _badgeOffset,
        ),
      );
      cum += s.value;
    }
    return result;
  }
}

class _SliceBadge extends StatelessWidget {
  const _SliceBadge({
    required this.color,
    required this.icon,
    required this.percent,
    required this.isRight,
    required this.textColor,
  });

  final Color color;
  final IconData? icon;
  final int percent;
  final bool isRight;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final iconWidget = icon != null
        ? Icon(icon, size: 16, color: color)
        : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          );
    final pctText = Text(
      '$percent%',
      style: AppTypography.xs.copyWith(
        fontWeight: AppTypography.weightSemibold,
        color: textColor,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isRight
          ? [iconWidget, const SizedBox(width: 4), pctText]
          : [pctText, const SizedBox(width: 4), iconWidget],
    );
  }
}
