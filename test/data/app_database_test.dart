import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/seed/default_data.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao', () {
    test('insert + watchAll 过滤软删除', () async {
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        id: 'c1',
        name: 'Food',
        type: TransactionType.expense,
        icon: 'utensils',
        color: '#f97316',
      ));
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        id: 'c2',
        name: 'Salary',
        type: TransactionType.income,
        icon: 'briefcase',
        color: '#10b981',
      ));

      final all = await db.categoryDao.watchAll().first;
      expect(all.length, 2);

      await db.categoryDao.softDelete('c1');
      final remaining = await db.categoryDao.watchAll().first;
      expect(remaining.length, 1);
      expect(remaining.first.id, 'c2');
    });

    test('watchByType 按类型筛选', () async {
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        id: 'e1',
        name: 'Food',
        type: TransactionType.expense,
        icon: 'utensils',
        color: '#f97316',
      ));
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        id: 'i1',
        name: 'Salary',
        type: TransactionType.income,
        icon: 'briefcase',
        color: '#10b981',
      ));

      final expenses =
          await db.categoryDao.watchByType(TransactionType.expense).first;
      expect(expenses.length, 1);
      expect(expenses.first.id, 'e1');
    });

    test('existsName 大小写不敏感 + 排除自身', () async {
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        id: 'c1',
        name: 'Food',
        type: TransactionType.expense,
        icon: 'utensils',
        color: '#f97316',
      ));

      expect(
        await db.categoryDao
            .existsName('food', TransactionType.expense),
        isTrue,
      );
      expect(
        await db.categoryDao
            .existsName('FOOD', TransactionType.expense, excludeId: 'c1'),
        isFalse,
      );
      expect(
        await db.categoryDao
            .existsName('Food', TransactionType.income),
        isFalse,
      );
    });
  });

  group('seedDefaultData', () {
    test('注入默认分类/标签/来源（英文）', () async {
      await seedDefaultData(db, locale: SeedLocale.enUS);

      final cats = await db.select(db.categories).get();
      final tags = await db.select(db.tags).get();
      final sources = await db.select(db.sources).get();

      expect(cats.length, 14); // 10 expense + 4 income
      expect(tags.length, 5);
      expect(sources.length, 1);
      expect(cats.every((c) => c.isDefault), isTrue);
      expect(cats.firstWhere((c) => c.nameKey == 'cat.food').name, 'Food');
    });

    test('注入中文 seed', () async {
      await seedDefaultData(db, locale: SeedLocale.zhCN);
      final food = await (db.select(db.categories)
            ..where((t) => t.nameKey.equals('cat.food')))
          .getSingle();
      expect(food.name, '餐饮');
    });

    test('幂等：重复调用不重复插入', () async {
      await seedDefaultData(db, locale: SeedLocale.enUS);
      await seedDefaultData(db, locale: SeedLocale.enUS);
      final cats = await db.select(db.categories).get();
      expect(cats.length, 14);
    });
  });

  group('TransactionDao', () {
    test('插入交易 + 软删除流式更新', () async {
      // 准备依赖：category + source
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

      await db.transactionDao.insertWithTags(
        TransactionsCompanion.insert(
          id: 't1',
          amountCents: 1234,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: '2026-05-13',
        ),
        const [],
      );

      final rows = await (db.select(db.transactions)
            ..where((t) => t.deletedAt.isNull()))
          .get();
      expect(rows.length, 1);
      expect(rows.first.amountCents, 1234);
    });
  });
}
