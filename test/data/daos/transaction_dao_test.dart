import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // 辅助：插入最小依赖（category + source）
  Future<void> insertDeps() async {
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
  }

  group('findByDateRange', () {
    test('返回区间内未删除的交易，排除软删除行和区间外行', () async {
      await insertDeps();

      // 插入 4 笔交易
      for (final entry in [
        ('t1', '2026-03-01'),
        ('t2', '2026-03-15'),
        ('t3', '2026-04-01'),
        ('t4', '2026-03-05'),
      ]) {
        await db.transactionDao.insertWithTags(
          TransactionsCompanion.insert(
            id: entry.$1,
            amountCents: 100,
            currency: 'CAD',
            type: TransactionType.expense,
            categoryId: 'c1',
            sourceId: 's1',
            transactedOn: entry.$2,
          ),
          const [],
        );
      }

      // 软删除 2026-03-05 那笔（t4）
      await db.transactionDao.softDelete('t4');

      // 查询 3 月区间
      final results =
          await db.transactionDao.findByDateRange('2026-03-01', '2026-03-31');

      final dates = results.map((r) => r.transactedOn).toSet();
      expect(dates, equals({'2026-03-15', '2026-03-01'}));
    });

    test('结果按 transactedOn 降序排列', () async {
      await insertDeps();

      for (final entry in [
        ('r1', '2026-03-01'),
        ('r2', '2026-03-15'),
        ('r3', '2026-03-08'),
      ]) {
        await db.transactionDao.insertWithTags(
          TransactionsCompanion.insert(
            id: entry.$1,
            amountCents: 100,
            currency: 'CAD',
            type: TransactionType.expense,
            categoryId: 'c1',
            sourceId: 's1',
            transactedOn: entry.$2,
          ),
          const [],
        );
      }

      final results =
          await db.transactionDao.findByDateRange('2026-03-01', '2026-03-31');

      expect(
        results.map((r) => r.transactedOn).toList(),
        equals(['2026-03-15', '2026-03-08', '2026-03-01']),
      );
    });

    test('区间外无结果时返回空列表', () async {
      await insertDeps();

      await db.transactionDao.insertWithTags(
        TransactionsCompanion.insert(
          id: 'x1',
          amountCents: 100,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: '2026-05-01',
        ),
        const [],
      );

      final results =
          await db.transactionDao.findByDateRange('2026-03-01', '2026-03-31');

      expect(results, isEmpty);
    });
  });
}
