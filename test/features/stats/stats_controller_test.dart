import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/stats/application/stats_controller.dart';

Transaction _tx({
  required String id,
  required int cents,
  required String date,
  TransactionType type = TransactionType.expense,
  String currency = 'CAD',
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
  group('aggregateDailyExpenses', () {
    test('按日累加，仅 expense', () {
      final bars = aggregateDailyExpenses(
        [
          _tx(id: 'a', cents: 1000, date: '2026-05-03'),
          _tx(id: 'b', cents: 500, date: '2026-05-03'),
          _tx(id: 'c', cents: 999, date: '2026-05-13',
              type: TransactionType.income),
        ],
        year: 2026,
        month: 5,
      );
      expect(bars.length, 31); // 5 月 31 天
      expect(bars[2].day, 3);
      expect(bars[2].totalCentsForCurrency('CAD'), 1500);
      expect(bars[12].totalCentsForCurrency('CAD'), 0);
    });

    test('多币种独立分桶', () {
      final bars = aggregateDailyExpenses(
        [
          _tx(id: 'a', cents: 1000, date: '2026-05-03'),
          _tx(id: 'b', cents: 200, date: '2026-05-03', currency: 'USD'),
        ],
        year: 2026,
        month: 5,
      );
      expect(bars[2].byCurrency, {'CAD': 1000, 'USD': 200});
    });

    test('2 月 28 天', () {
      final bars = aggregateDailyExpenses(const [], year: 2026, month: 2);
      expect(bars.length, 28);
    });

    test('12 月跨年边界', () {
      final bars = aggregateDailyExpenses(const [], year: 2026, month: 12);
      expect(bars.length, 31);
    });
  });

  group('aggregateByCategory', () {
    test('按分类降序，仅 expense + 匹配币种', () {
      final slices = aggregateByCategory(
        [
          _tx(id: 'a', cents: 1000, date: '2026-05-01'),
          _tx(id: 'b', cents: 500, date: '2026-05-02'),
          _tx(id: 'c', cents: 9999, date: '2026-05-03', currency: 'USD'),
          _tx(id: 'd', cents: 2000, date: '2026-05-04',
              type: TransactionType.income),
        ],
        currency: 'CAD',
      );
      expect(slices.length, 1);
      expect(slices.first.categoryId, 'c1');
      expect(slices.first.totalCents, 1500);
    });
  });

  group('aggregateByTag', () {
    test('多标签都累加同一笔金额', () {
      final slices = aggregateByTag(
        [_tx(id: 'a', cents: 1000, date: '2026-05-01')],
        currency: 'CAD',
        tagIdsByTx: const {
          'a': ['t1', 't2'],
        },
      );
      expect(slices.length, 2);
      expect(slices.every((s) => s.totalCents == 1000), isTrue);
    });
    test('忽略未挂标签的交易', () {
      final slices = aggregateByTag(
        [_tx(id: 'a', cents: 1000, date: '2026-05-01')],
        currency: 'CAD',
        tagIdsByTx: const {},
      );
      expect(slices, isEmpty);
    });
  });

  group('dominantCurrency', () {
    test('CAD 永远优先', () {
      final bars = [
        DailyExpenseBar(day: 1, byCurrency: const {'USD': 10000}),
        DailyExpenseBar(day: 2, byCurrency: const {'CAD': 100}),
      ];
      expect(dominantCurrency(bars), 'CAD');
    });
    test('无 CAD 时按总额降序', () {
      final bars = [
        DailyExpenseBar(day: 1, byCurrency: const {'USD': 100, 'EUR': 300}),
        DailyExpenseBar(day: 2, byCurrency: const {'EUR': 200}),
      ];
      expect(dominantCurrency(bars), 'EUR'); // EUR=500 > USD=100
    });
    test('空 → CAD 兜底', () {
      expect(dominantCurrency(const []), 'CAD');
    });
  });
}
