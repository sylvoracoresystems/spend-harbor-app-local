import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

/// 环形图的一片：颜色 + 数值 + 可选徽标图标。
class DonutSlice {
  const DonutSlice({required this.color, required this.value, this.icon});

  final Color color;
  final double value;

  /// 切片旁徽标使用的图标；为 null 时改用小圆点（用于标签场景）。
  final IconData? icon;
}

/// 环形图组件：中心金额 + 多片切片 + 大片徽标。
class StatsDonut extends StatefulWidget {
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

  static const double _centerRadius = 56;
  static const double _ringRadius = 28;
  static const double _badgeOffset = 2.3;
  static const double _badgeThreshold = 0.03;
  static const Duration _revealDuration = Duration(milliseconds: 1900);
  static const Curve _revealCurve = Curves.easeOutCubic;

  @override
  State<StatsDonut> createState() => _StatsDonutState();
}

/// 持有首屏 sweep 动画控制器；后续数据变化交给 fl_chart 内置 lerp。
class _StatsDonutState extends State<StatsDonut>
    with SingleTickerProviderStateMixin {
  /// 首屏 sweep 控制器。完成后保持在 t=1；后续数据变化交给 fl_chart 内部的
  /// [PieChart.duration] 在新旧 section 之间 lerp，不再重新 sweep。
  late final AnimationController _ctrl;
  late final Animation<double> _t;

  static const Duration _morphDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: StatsDonut._revealDuration,
    );
    _t = CurvedAnimation(parent: _ctrl, curve: StatsDonut._revealCurve);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _revealed => _ctrl.status == AnimationStatus.completed;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final total = widget.slices.fold<double>(0, (a, s) => a + s.value);

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _t,
            builder: (ctx, _) {
              final t = _t.value;
              final fullyShown = _revealed;
              return Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 1.5,
                      centerSpaceRadius: StatsDonut._centerRadius,
                      sections:
                          total <= 0
                              ? [
                                PieChartSectionData(
                                  color: c.borderSoft,
                                  value: 1,
                                  radius: StatsDonut._ringRadius,
                                  showTitle: false,
                                ),
                              ]
                              : _buildSections(
                                context,
                                total,
                                fullyShown ? 1.0 : t,
                              ),
                    ),
                    // sweep 期间禁用 fl_chart 自带 lerp（由 t 接管）；
                    // sweep 完成后交回给 fl_chart 做新旧 section 平滑过渡。
                    duration: fullyShown ? _morphDuration : Duration.zero,
                  ),
                  if (total > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _LeaderLinesPainter(
                            entries: _leaderEntries(
                              total,
                              fullyShown ? 1.0 : t,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.centerLabel,
                style: AppTypography.xs.copyWith(
                  color: c.textMuted,
                  fontWeight: AppTypography.weightSemibold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              SizedBox(
                width: StatsDonut._centerRadius * 2 - 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.centerAmount,
                    maxLines: 1,
                    style: AppTypography.base.copyWith(
                      fontWeight: AppTypography.weightBold,
                      fontFamily: 'monospace',
                      color: widget.centerColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 按 sweep 进度 t 构建分段：从 12 点钟方向开始，按角度逐渐"画"出每个 slice。
  /// 已完成的 slice 用真实值，正在 sweep 的 slice 用部分值，剩余角度用透明 phantom 占位。
  List<PieChartSectionData> _buildSections(
    BuildContext context,
    double total,
    double t,
  ) {
    final c = context.appColors;
    final swept = total * t;
    final result = <PieChartSectionData>[];
    double cum = 0;
    for (final s in widget.slices) {
      final start = cum;
      final end = cum + s.value;
      final shown = math.max(0.0, math.min(end, swept) - start);
      final isComplete = swept >= end - 1e-9;
      if (shown > 0) {
        final pct = s.value / total;
        final midValue = start + s.value / 2;
        final degFromStart = (midValue / total) * 360;
        final degFromEast = -90 + degFromStart;
        final rad = degFromEast * math.pi / 180;
        final isRight = math.cos(rad) >= 0;
        result.add(
          PieChartSectionData(
            color: s.color,
            value: shown,
            radius: StatsDonut._ringRadius,
            showTitle: false,
            // 完整出现后再挂 badge，避免 sweep 中途 badge 在错误的中点抖动
            badgeWidget:
                isComplete && pct >= StatsDonut._badgeThreshold
                    ? _SliceBadge(
                      color: s.color,
                      icon: s.icon,
                      percent: (pct * 100).round(),
                      isRight: isRight,
                      textColor: c.textBody,
                    )
                    : null,
            badgePositionPercentageOffset: StatsDonut._badgeOffset,
          ),
        );
      }
      cum = end;
    }
    // 剩余未 sweep 的部分用透明 phantom 占位，保证圆周比例正确
    final remaining = total - swept;
    if (remaining > 1e-6) {
      result.add(
        PieChartSectionData(
          color: Colors.transparent,
          value: remaining,
          radius: StatsDonut._ringRadius,
          showTitle: false,
        ),
      );
    }
    // 起始一帧（t≈0）result 全部为 0 长 → fl_chart 需要至少一段
    if (result.isEmpty) {
      result.add(
        PieChartSectionData(
          color: Colors.transparent,
          value: 1,
          radius: StatsDonut._ringRadius,
          showTitle: false,
        ),
      );
    }
    return result;
  }

  /// 已经 sweep 完整的 slice 才出指引线；与 badge 同步显隐。
  List<_LeaderEntry> _leaderEntries(double total, double t) {
    final swept = total * t;
    final out = <_LeaderEntry>[];
    double cum = 0;
    for (final s in widget.slices) {
      final start = cum;
      final end = cum + s.value;
      final pct = s.value / total;
      final isComplete = swept >= end - 1e-9;
      if (isComplete && pct >= StatsDonut._badgeThreshold) {
        final midValue = start + s.value / 2;
        final degFromStart = (midValue / total) * 360;
        out.add(_LeaderEntry(degFromStart: degFromStart, color: s.color));
      }
      cum = end;
    }
    return out;
  }
}

/// 一根 leader line 的纯数据：从切片起点偏转角 + 颜色。
class _LeaderEntry {
  const _LeaderEntry({required this.degFromStart, required this.color});
  final double degFromStart;
  final Color color;
}

/// 从圆环外缘沿径向画一根短线指向对应 badge。
///
/// 几何：fl_chart 中心 = canvas 中心；环外缘 R = centerSpaceRadius + ringRadius；
/// badge 中心 R = centerSpaceRadius + ringRadius * badgePositionPercentageOffset。
/// 线段从 R_outer + 2px 拉到 R_badge - 8px，避免压到环本身和 badge 文字。
class _LeaderLinesPainter extends CustomPainter {
  _LeaderLinesPainter({required this.entries});
  final List<_LeaderEntry> entries;

  static const double _ringOuter =
      StatsDonut._centerRadius + StatsDonut._ringRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    // 短「tick」：从环外缘往外伸 2px ~ 12px，固定 10px 长度。
    // 不再以 badge center 反推终点，避免不同角度下被 badge 的横向 Row 占用挤掉。
    final r1 = _ringOuter + 2;
    final r2 = _ringOuter + 12;
    for (final e in entries) {
      final rad = (-90 + e.degFromStart) * math.pi / 180;
      final p1 = Offset(c.dx + r1 * math.cos(rad), c.dy + r1 * math.sin(rad));
      final p2 = Offset(c.dx + r2 * math.cos(rad), c.dy + r2 * math.sin(rad));
      final paint =
          Paint()
            ..color = e.color
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(_LeaderLinesPainter old) =>
      !_listEquals(entries, old.entries);

  static bool _listEquals(List<_LeaderEntry> a, List<_LeaderEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].degFromStart != b[i].degFromStart || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }
}

/// 切片旁的小徽标：色块 + （icon 或圆点）+ 占比文本。
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
    final pctText = Text(
      '$percent%',
      style: AppTypography.xs.copyWith(
        fontWeight: AppTypography.weightSemibold,
        color: textColor,
      ),
    );
    // 没有 icon（Tag distribution）→ 只显示百分比，去掉小圆点。
    if (icon == null) return pctText;
    final iconWidget = Icon(icon, size: 16, color: color);
    // icon 放在 Row 远离圆心的一侧、百分比靠近圆心：指引线落在两者之间，不被 icon 遮住。
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          isRight
              ? [pctText, const SizedBox(width: 4), iconWidget]
              : [iconWidget, const SizedBox(width: 4), pctText],
    );
  }
}
