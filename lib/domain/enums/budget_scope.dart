/// 预算范围：总额（不关联分类） / 单分类
enum BudgetScope {
  total('total'),
  category('category');

  const BudgetScope(this.value);

  final String value;

  static BudgetScope fromValue(String value) {
    return BudgetScope.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown BudgetScope value: $value'),
    );
  }
}
