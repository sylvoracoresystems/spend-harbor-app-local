part of '../transactions_page.dart';

class _DayGroupView extends ConsumerWidget {
  const _DayGroupView({required this.group, this.cardStyle = false});
  final DayGroup group;
  final bool cardStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeader(group: group),
        Container(
          color: c.surface,
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                TransactionListRow(
                  tx: group.items[i],
                  enableSelection: true,
                ),
                if (i < group.items.length - 1)
                  Divider(height: 1, color: c.border),
              ],
            ],
          ),
        ),
      ],
    );
    if (!cardStyle) return inner;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.brXl,
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: inner,
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group});
  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      color: c.mintTint,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDayLabel(context, group.date),
              style: AppTypography.sm.copyWith(
                color: c.actionInk,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
          ),
          Text(
            _formatDayNet(group),
            style: AppTypography.sm.merge(AppTypography.mono).copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDayLabel(BuildContext context, DateTime date) {
  final l = AppL10n.of(context);
  final today = DateTime.now();
  final isToday = today.year == date.year &&
      today.month == date.month &&
      today.day == date.day;
  final y = today.subtract(const Duration(days: 1));
  final isYesterday =
      y.year == date.year && y.month == date.month && y.day == date.day;
  if (isToday) return l.dayToday;
  if (isYesterday) return l.dayYesterday;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// 多币种不换算：取该日组内出现次数最多的货币，签名汇总（income +, expense -）。
/// 若组内有其他币种则附加 " +N"。
String _formatDayNet(DayGroup group) {
  final byCcy = <String, int>{};
  final counts = <String, int>{};
  for (final t in group.items) {
    final sign = t.type == TransactionType.income ? 1 : -1;
    byCcy[t.currency] = (byCcy[t.currency] ?? 0) + sign * t.amountCents;
    counts[t.currency] = (counts[t.currency] ?? 0) + 1;
  }
  if (byCcy.isEmpty) return '';
  final dominant =
      counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  final cents = byCcy[dominant]!;
  final symbol = Currency.byCode(dominant).symbol;
  final body = '$symbol${(cents.abs() / 100).toStringAsFixed(2)}';
  final signed = cents < 0 ? '-$body' : body;
  final others = byCcy.length - 1;
  return others > 0 ? '$signed  +$others' : signed;
}
