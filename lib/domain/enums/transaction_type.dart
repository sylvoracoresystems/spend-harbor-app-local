/// 交易类型：收入 / 支出
enum TransactionType {
  income('income'),
  expense('expense');

  const TransactionType(this.value);

  final String value;

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () =>
          throw ArgumentError('Unknown TransactionType value: $value'),
    );
  }
}
