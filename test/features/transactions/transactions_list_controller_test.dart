import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/transactions/application/transactions_list_controller.dart';

void main() {
  group('YearMonth', () {
    test('key 形如 YYYY-MM', () {
      expect(const YearMonth(2026, 5).key, '2026-05');
      expect(const YearMonth(2026, 12).key, '2026-12');
    });

    test('next 跨年', () {
      expect(const YearMonth(2026, 12).next(), const YearMonth(2027, 1));
    });

    test('prev 跨年', () {
      expect(const YearMonth(2026, 1).prev(), const YearMonth(2025, 12));
    });

    test('parse 还原', () {
      expect(YearMonth.parse('2026-05'), const YearMonth(2026, 5));
    });
  });

  group('groupByDay', () {
    Transaction tx(String id, String date) => Transaction(
          id: id,
          amountCents: 100,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('按日期降序分组', () {
      final groups = groupByDay([
        tx('a', '2026-05-10'),
        tx('b', '2026-05-12'),
        tx('c', '2026-05-10'),
        tx('d', '2026-05-13'),
      ]);
      expect(groups.map((g) => g.date.day).toList(), [13, 12, 10]);
      expect(groups[2].items.length, 2);
    });
  });

  group('SelectionController', () {
    test('toggle 切换 + clear 清空', () {
      final c = SelectionController();
      expect(c.isActive, isFalse);
      c.toggle('a');
      c.toggle('b');
      expect(c.state, {'a', 'b'});
      expect(c.isActive, isTrue);
      c.toggle('a');
      expect(c.state, {'b'});
      c.clear();
      expect(c.state, isEmpty);
      expect(c.isActive, isFalse);
    });
  });

  test('bulkSoftDelete 软删除多笔', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      id: 'c1',
      name: 'Food',
      type: TransactionType.expense,
      icon: 'utensils',
      color: '#f97316',
    ));
    await db.sourceDao.insertSource(SourcesCompanion.insert(
      id: 's1',
      name: 'Cash',
      icon: 'wallet',
      color: '#10b981',
      currency: 'CAD',
    ));
    for (final id in ['a', 'b', 'c']) {
      await db.transactionDao.insertWithTags(
        TransactionsCompanion.insert(
          id: id,
          amountCents: 100,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: '2026-05-13',
        ),
        const [],
      );
    }
    final affected = await db.transactionDao.bulkSoftDelete(['a', 'c']);
    expect(affected, 2);
    final remaining = await db.transactionDao.watchAll().first;
    expect(remaining.map((r) => r.id).toList(), ['b']);
  });

  test('transactionsOfMonthProvider 跟随 currentMonth 切换数据', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      id: 'c1',
      name: 'Food',
      type: TransactionType.expense,
      icon: 'utensils',
      color: '#f97316',
    ));
    await db.sourceDao.insertSource(SourcesCompanion.insert(
      id: 's1',
      name: 'Cash',
      icon: 'wallet',
      color: '#10b981',
      currency: 'CAD',
    ));

    Future<void> insertOn(String id, String date) {
      return db.transactionDao.insertWithTags(
        TransactionsCompanion.insert(
          id: id,
          amountCents: 100,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: date,
          note: const Value(null),
        ),
        const [],
      );
    }

    await insertOn('a', '2026-05-10');
    await insertOn('b', '2026-04-30');

    container
        .read(currentMonthProvider.notifier)
        .set(const YearMonth(2026, 5));
    var rows = await container.read(transactionsOfMonthProvider.future);
    expect(rows.map((r) => r.id).toList(), ['a']);

    container
        .read(currentMonthProvider.notifier)
        .set(const YearMonth(2026, 4));
    rows = await container.read(transactionsOfMonthProvider.future);
    expect(rows.map((r) => r.id).toList(), ['b']);
  });
}
