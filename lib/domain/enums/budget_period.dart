/// 预算周期：周 / 月 / 年
enum BudgetPeriod {
  week('week'),
  month('month'),
  year('year');

  const BudgetPeriod(this.value);

  final String value;

  static BudgetPeriod fromValue(String value) {
    return BudgetPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown BudgetPeriod value: $value'),
    );
  }
}
