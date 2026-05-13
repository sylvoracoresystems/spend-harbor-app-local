import '../../../domain/enums/budget_period.dart';

/// 把任意日期 [date] 对齐到 [period] 当前所在周期的**起点**。
///
/// - `week`  → 当周周一（DateTime.weekday: Mon=1）
/// - `month` → 当月 1 日
/// - `year`  → 当年 1 月 1 日
///
/// 返回 [DateTime]（不含时分秒，本地时区解读）。
DateTime alignToPeriodStart(DateTime date, BudgetPeriod period) {
  switch (period) {
    case BudgetPeriod.week:
      final delta = date.weekday - DateTime.monday;
      final d = date.subtract(Duration(days: delta));
      return DateTime(d.year, d.month, d.day);
    case BudgetPeriod.month:
      return DateTime(date.year, date.month, 1);
    case BudgetPeriod.year:
      return DateTime(date.year, 1, 1);
  }
}

/// 把 [date] 序列化为 ISO 日期字符串（YYYY-MM-DD）。
String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// 返回 [date] 所在周期的 **结束日**（闭区间最后一天，含）。
DateTime periodEndOn(DateTime date, BudgetPeriod period) {
  final start = alignToPeriodStart(date, period);
  switch (period) {
    case BudgetPeriod.week:
      return start.add(const Duration(days: 6));
    case BudgetPeriod.month:
      final nextMonth =
          start.month == 12 ? DateTime(start.year + 1, 1, 1) : DateTime(start.year, start.month + 1, 1);
      return nextMonth.subtract(const Duration(days: 1));
    case BudgetPeriod.year:
      return DateTime(start.year, 12, 31);
  }
}
