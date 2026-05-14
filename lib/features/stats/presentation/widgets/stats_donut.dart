import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

class DonutSlice {
  const DonutSlice({required this.color, required this.value});
  final Color color;
  final double value;
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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: 50,
              sections: slices.isEmpty
                  ? [
                      PieChartSectionData(
                        color: c.borderSoft,
                        value: 1,
                        radius: 30,
                        showTitle: false,
                      ),
                    ]
                  : [
                      for (final s in slices)
                        PieChartSectionData(
                          color: s.color,
                          value: s.value,
                          radius: 30,
                          showTitle: false,
                        ),
                    ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: AppTypography.xs.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                centerAmount,
                style: AppTypography.sm.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: AppTypography.weightSemibold,
                  color: centerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
