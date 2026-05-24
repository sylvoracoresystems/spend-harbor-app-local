import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

/// Stats 三张卡（trend / distribution / top）共享的外壳。
///
/// - Card(margin:0) + Padding(x3) + Column(crossAxis.start)
/// - 头部 Row：[icon] + [title]（可省略截断） + 可选 [trailing]（如 TypePillToggle）
/// - [child] 自行控制头部之下的垂直间距与内容
///
/// [cardKey] 透传到内层 [Card]，供 Stats 页 GlobalKey 跳转使用。
class StatsSectionCard extends StatelessWidget {
  const StatsSectionCard({
    super.key,
    this.cardKey,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
  });

  final Key? cardKey;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Card(
      key: cardKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.base.copyWith(
                      fontWeight: AppTypography.weightSemibold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.x2),
                  trailing!,
                ],
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Stats 卡片正文区的"加载 / 错误 / 空态"占位。统一样式：
/// vertical 24 padding + center + sm 字号；颜色随种类切换（textMuted / expense）。
class StatsCardPlaceholder extends StatelessWidget {
  const StatsCardPlaceholder._(this._text, this._color);

  final String _text;
  final Color _color;

  factory StatsCardPlaceholder.loading(BuildContext context, AppL10n l) =>
      StatsCardPlaceholder._(l.statsLoading, context.appColors.textMuted);

  factory StatsCardPlaceholder.error(BuildContext context, AppL10n l) =>
      StatsCardPlaceholder._(l.statsError, context.appColors.expense);

  factory StatsCardPlaceholder.empty(BuildContext context, String text) =>
      StatsCardPlaceholder._(text, context.appColors.textMuted);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(_text, style: AppTypography.sm.copyWith(color: _color)),
      ),
    );
  }
}
