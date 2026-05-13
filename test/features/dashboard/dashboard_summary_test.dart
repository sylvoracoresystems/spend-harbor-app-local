import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/dashboard/application/dashboard_summary_controller.dart';

Transaction _tx({
  required String id,
  required int cents,
  required TransactionType type,
  String currency = 'CAD',
  String date = '2026-05-13',
}) =>
    Transaction(
      id: id,
      amountCents: cents,
      currency: currency,
      type: type,
      categoryId: 'c1',
      sourceId: 's1',
      transactedOn: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  test('单币种：收入 / 支出 / 净额 / 笔数', () {
    final s = aggregateSummary([
      _tx(id: 'a', cents: 1000, type: TransactionType.income),
      _tx(id: 'b', cents: 300, type: TransactionType.expense),
      _tx(id: 'c', cents: 200, type: TransactionType.expense),
    ]);
    expect(s.transactionCount, 3);
    expect(s.byCurrency.length, 1);
    expect(s.byCurrency.first.currency, 'CAD');
    expect(s.byCurrency.first.incomeCents, 1000);
    expect(s.byCurrency.first.expenseCents, 500);
    expect(s.byCurrency.first.netCents, 500);
  });

  test('多币种：分行不换算，CAD 优先 + 字母序', () {
    final s = aggregateSummary([
      _tx(id: 'a', cents: 100, type: TransactionType.income, currency: 'USD'),
      _tx(
        id: 'b',
        cents: 200,
        type: TransactionType.expense,
        currency: 'CAD',
      ),
      _tx(
        id: 'c',
        cents: 50,
        type: TransactionType.income,
        currency: 'EUR',
      ),
    ]);
    expect(
      s.byCurrency.map((e) => e.currency).toList(),
      ['CAD', 'EUR', 'USD'],
    );
  });

  test('空列表 → isEmpty', () {
    final s = aggregateSummary(const <Transaction>[]);
    expect(s.isEmpty, isTrue);
    expect(s.byCurrency, isEmpty);
  });
}
