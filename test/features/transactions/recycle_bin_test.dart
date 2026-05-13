import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/transactions/application/recycle_bin_controller.dart';

Future<AppDatabase> _seedDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
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
  return db;
}

Future<void> _insert(AppDatabase db, String id) {
  return db.transactionDao.insertWithTags(
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

void main() {
  group('daysLeft', () {
    test('刚删除 → 接近 30 天', () {
      final now = DateTime(2026, 5, 13, 12);
      expect(daysLeft(now, now: now), 30);
    });
    test('删除 10 天前 → 剩 20 天', () {
      final now = DateTime(2026, 5, 13, 12);
      final deleted = now.subtract(const Duration(days: 10));
      expect(daysLeft(deleted, now: now), 20);
    });
    test('超过 30 天 → 0', () {
      final now = DateTime(2026, 5, 13, 12);
      final deleted = now.subtract(const Duration(days: 40));
      expect(daysLeft(deleted, now: now), 0);
    });
  });

  test('restore 清空 deletedAt', () async {
    final db = await _seedDb();
    addTearDown(db.close);
    await _insert(db, 'a');
    await db.transactionDao.softDelete('a');

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    var trashed = await db.transactionDao.watchTrashed(cutoff).first;
    expect(trashed.length, 1);

    await db.transactionDao.restore('a');
    trashed = await db.transactionDao.watchTrashed(cutoff).first;
    expect(trashed, isEmpty);

    final live = await db.transactionDao.watchAll().first;
    expect(live.length, 1);
  });

  test('purge 物理删除 + 清理标签', () async {
    final db = await _seedDb();
    addTearDown(db.close);
    await db.tagDao.insertTag(TagsCompanion.insert(
      id: 't1',
      name: 'Work',
      color: '#0ea5e9',
    ));
    await db.transactionDao.insertWithTags(
      TransactionsCompanion.insert(
        id: 'a',
        amountCents: 100,
        currency: 'CAD',
        type: TransactionType.expense,
        categoryId: 'c1',
        sourceId: 's1',
        transactedOn: '2026-05-13',
      ),
      ['t1'],
    );
    await db.transactionDao.softDelete('a');
    await db.transactionDao.purge('a');

    final rows = await db.select(db.transactions).get();
    expect(rows, isEmpty);
    final tagLinks = await db.select(db.transactionTags).get();
    expect(tagLinks, isEmpty);
  });

  test('purgeOlderThan 仅清理超期项', () async {
    final db = await _seedDb();
    addTearDown(db.close);
    for (final id in ['a', 'b', 'c']) {
      await _insert(db, id);
    }
    // 手动设置 deletedAt：a 40 天前，b 10 天前，c 未删
    final now = DateTime.now();
    Future<void> setDeletedAt(String id, DateTime when) async {
      await (db.update(db.transactions)..where((t) => t.id.equals(id)))
          .write(TransactionsCompanion(
        deletedAt: Value(when),
      ));
    }

    await setDeletedAt('a', now.subtract(const Duration(days: 40)));
    await setDeletedAt('b', now.subtract(const Duration(days: 10)));

    final affected = await db.transactionDao.purgeOlderThan(
      now.subtract(const Duration(days: 30)),
    );
    expect(affected, 1); // 只清掉 a

    final all = await db.select(db.transactions).get();
    expect(all.map((r) => r.id).toSet(), {'b', 'c'});
  });
}
