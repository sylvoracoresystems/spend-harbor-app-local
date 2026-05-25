part of '../dashboard_page.dart';

/// 指标卡网格：收入/支出/净额/笔数 4 张卡，宽屏排 4 列、窄屏 2 列。
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    // Net 金额按符号上色保留语义；卡片底色统一走 mint 与 income/expense 区分。
    final netColor = metrics.netCents >= 0 ? c.income : c.expense;

    final cards = <Widget>[
      _TileMetricCard(
        label: l.dashIncome,
        icon: LucideIcons.coins,
        accentColor: c.income,
        bgStart: c.incomeSoft,
        bgEnd: Color.lerp(c.incomeSoft, c.income, 0.18)!,
        amount: _formatAmount(
          metrics.incomeCents,
          metrics.dominantCurrency,
          signed: true,
        ),
        currencyBadge: metrics.dominantCurrency,
        otherCurrencyCount: metrics.otherCurrencyCount,
      ),
      _TileMetricCard(
        label: l.dashExpense,
        icon: LucideIcons.shoppingBag,
        accentColor: c.expense,
        bgStart: c.expenseSoft,
        bgEnd: Color.lerp(c.expenseSoft, c.expense, 0.18)!,
        amount: _formatAmount(
          metrics.expenseCents,
          metrics.dominantCurrency,
          signed: true,
          forceNegative: true,
        ),
        currencyBadge: metrics.dominantCurrency,
        otherCurrencyCount: metrics.otherCurrencyCount,
      ),
      // Net：左上始终走品牌 mint（与 income/expense 卡形成可识别差异），
      // 右下走符号色（≥0 → income 绿，<0 → expense 红），背景对角渐变即「品牌→符号」。
      _TileMetricCard(
        label: l.dashNet,
        icon: LucideIcons.scale,
        accentColor: netColor,
        bgStart: c.mintTint,
        bgEnd: Color.lerp(c.mintTint, netColor, 0.35)!,
        amount: _formatAmount(
          metrics.netCents,
          metrics.dominantCurrency,
          signed: true,
        ),
        currencyBadge: metrics.dominantCurrency,
        otherCurrencyCount: metrics.otherCurrencyCount,
      ),
      _TileMetricCard(
        label: l.dashCount,
        icon: LucideIcons.listChecks,
        accentColor: c.info,
        bgStart: c.infoSoft,
        bgEnd: Color.lerp(c.infoSoft, c.info, 0.18)!,
        amount: '${metrics.transactionCount}',
        currencyBadge: null,
        otherCurrencyCount: 0,
      ),
    ];
    // 宽屏（iPad 竖/横屏、大屏横屏）改 4 列 1 行，避免 2 列布局下卡片被撑得过大。
    // 高度由内容决定（IntrinsicHeight），同行卡片自动等高，避免 aspect ratio 写死导致的溢出。
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final cols = isWide ? 4 : 2;
    const gap = AppSpacing.x3;
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += cols) {
      final rowCards = cards.sublist(i, (i + cols).clamp(0, cards.length));
      final children = <Widget>[];
      for (var j = 0; j < rowCards.length; j++) {
        if (j > 0) children.add(const SizedBox(width: gap));
        children.add(Expanded(child: rowCards[j]));
      }
      for (var j = rowCards.length; j < cols; j++) {
        children.add(const SizedBox(width: gap));
        children.add(const Expanded(child: SizedBox.shrink()));
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// 单张指标卡：图标 + 标题 + 金额，支持多币种角标提示。
class _TileMetricCard extends StatelessWidget {
  const _TileMetricCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.bgStart,
    required this.bgEnd,
    required this.amount,
    required this.currencyBadge,
    required this.otherCurrencyCount,
  });
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color bgStart;
  final Color bgEnd;
  final String amount;
  final String? currencyBadge;
  final int otherCurrencyCount;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tile icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: AppRadius.brLg,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              if (currencyBadge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    otherCurrencyCount > 0
                        ? '$currencyBadge  ${l.dashOthersBadge(otherCurrencyCount)}'
                        : currencyBadge!,
                    style: AppTypography.xs.copyWith(
                      color: accentColor,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: AppTypography.sm.copyWith(
              color: c.textBody,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                maxLines: 1,
                softWrap: false,
                style: AppTypography.xl.merge(AppTypography.mono).copyWith(
                  color: accentColor,
                  fontWeight: AppTypography.weightBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAmount(
  int cents,
  String? code, {
  bool signed = false,
  bool forceNegative = false,
}) {
  // 无数据：占位 0.00（不带符号），统一对齐视觉。
  if (code == null) return '0.00';
  final abs = cents.abs();
  final body = (abs / 100).toStringAsFixed(2);
  if (forceNegative && cents > 0) return '-$body';
  if (!signed || cents == 0) return body;
  return cents < 0 ? '-$body' : '+$body';
}
