part of '../transactions_page.dart';

/// 列表顶部汇总：左侧笔数，右侧各币种 income/expense 合计。
/// 单币种 → 单行；多币种 → 笔数占第一行，多币种行右对齐堆叠。
class _ListSummary extends StatelessWidget {
  const _ListSummary({required this.rows});
  final List<Transaction> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final income = <String, int>{};
    final expense = <String, int>{};
    for (final t in rows) {
      if (t.type == TransactionType.income) {
        income[t.currency] = (income[t.currency] ?? 0) + t.amountCents;
      } else {
        expense[t.currency] = (expense[t.currency] ?? 0) + t.amountCents;
      }
    }
    final currencies = <String>{...income.keys, ...expense.keys}.toList()
      ..sort();
    final showCcy = currencies.length > 1;
    final countText = Text(
      l.txListCount(rows.length),
      style: AppTypography.xs.copyWith(
        color: c.textMuted,
        fontWeight: AppTypography.weightSemibold,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x1,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          countText,
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final ccy in currencies)
                _SummaryAmounts(
                  currency: ccy,
                  incomeCents: income[ccy] ?? 0,
                  expenseCents: expense[ccy] ?? 0,
                  showCurrencyLabel: showCcy,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 汇总条单币种行：收入/支出小计 + 币种标签。
class _SummaryAmounts extends StatelessWidget {
  const _SummaryAmounts({
    required this.currency,
    required this.incomeCents,
    required this.expenseCents,
    required this.showCurrencyLabel,
  });
  final String currency;
  final int incomeCents;
  final int expenseCents;
  final bool showCurrencyLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final symbol = Currency.byCode(currency).symbol;
    final numStyle = AppTypography.xs.merge(AppTypography.mono).copyWith(
          fontWeight: AppTypography.weightSemibold,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCurrencyLabel) ...[
            Text(
              currency,
              style: AppTypography.xs.copyWith(color: c.textMuted),
            ),
            const SizedBox(width: AppSpacing.x2),
          ],
          Text(
            '$symbol${(incomeCents / 100).toStringAsFixed(2)}',
            style: numStyle.copyWith(color: c.income),
          ),
          const SizedBox(width: AppSpacing.x3),
          Text(
            '-$symbol${(expenseCents / 100).toStringAsFixed(2)}',
            style: numStyle.copyWith(color: c.expense),
          ),
        ],
      ),
    );
  }
}
