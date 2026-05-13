import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/transactions/application/transaction_form_controller.dart';

Future<({AppDatabase db, ProviderContainer container})> _setup() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.categoryDao.insertCategory(CategoriesCompanion.insert(
    id: 'c-expense',
    name: 'Food',
    type: TransactionType.expense,
    icon: 'utensils',
    color: '#f97316',
  ));
  await db.categoryDao.insertCategory(CategoriesCompanion.insert(
    id: 'c-income',
    name: 'Salary',
    type: TransactionType.income,
    icon: 'briefcase',
    color: '#10b981',
  ));
  await db.sourceDao.insertSource(SourcesCompanion.insert(
    id: 's-cash',
    name: 'Cash',
    icon: 'wallet',
    color: '#10b981',
    currency: 'CAD',
  ));
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
  ]);
  addTearDown(container.dispose);
  addTearDown(db.close);
  return (db: db, container: container);
}

void main() {
  group('validate', () {
    test('空金额', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      expect(n.validate(), TransactionFormError.amountRequired);
    });

    test('金额非法（0 / 负数）', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      n.setAmount('0');
      expect(n.validate(), TransactionFormError.amountInvalid);
      n.setAmount('-5');
      expect(n.validate(), TransactionFormError.amountInvalid);
    });

    test('未选分类 → categoryRequired', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      n.setAmount('12.34');
      expect(n.validate(), TransactionFormError.categoryRequired);
    });

    test('未选来源 → sourceRequired', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      n.setAmount('12.34');
      n.setCategory('c-expense');
      expect(n.validate(), TransactionFormError.sourceRequired);
    });

    test('全部齐备 → null', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      n.setAmount('12.34');
      n.setCategory('c-expense');
      n.setSource('s-cash');
      expect(n.validate(), isNull);
    });
  });

  group('amountCents', () {
    test('12.34 → 1234', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      n.setAmount('12.34');
      expect(s.container.read(transactionFormControllerProvider(null)).amountCents, 1234);
    });
    test('整数也接受', () async {
      final s = await _setup();
      final n = s.container
          .read(transactionFormControllerProvider(null).notifier);
      n.setAmount('100');
      expect(
        s.container.read(transactionFormControllerProvider(null)).amountCents,
        10000,
      );
    });
  });

  test('submit 写入交易 + 标签关联，币种来自 source', () async {
    final s = await _setup();
    // 准备一个标签
    await s.db.tagDao.insertTag(TagsCompanion.insert(
      id: 't1',
      name: 'Work',
      color: '#0ea5e9',
    ));
    final n = s.container
        .read(transactionFormControllerProvider(null).notifier);
    n.setAmount('25.50');
    n.setCategory('c-expense');
    n.setSource('s-cash');
    n.toggleTag('t1');
    n.setDate(DateTime(2026, 5, 13));

    final ok = await n.submit();
    expect(ok, isTrue);

    final rows = await s.db.transactionDao.watchAll().first;
    expect(rows.length, 1);
    expect(rows.first.amountCents, 2550);
    expect(rows.first.currency, 'CAD');
    expect(rows.first.transactedOn, '2026-05-13');

    final tagIds = await s.db.transactionDao.tagIdsOf(rows.first.id);
    expect(tagIds, ['t1']);
  });

  test('toggleTag 是开关', () async {
    final s = await _setup();
    final n = s.container
        .read(transactionFormControllerProvider(null).notifier);
    n.toggleTag('t1');
    expect(
      s.container.read(transactionFormControllerProvider(null)).tagIds,
      {'t1'},
    );
    n.toggleTag('t1');
    expect(
      s.container.read(transactionFormControllerProvider(null)).tagIds,
      isEmpty,
    );
  });

  test('编辑模式：加载已有交易字段', () async {
    final s = await _setup();
    await s.db.transactionDao.insertWithTags(
      TransactionsCompanion.insert(
        id: 'tx1',
        amountCents: 5000,
        currency: 'CAD',
        type: TransactionType.expense,
        categoryId: 'c-expense',
        sourceId: 's-cash',
        transactedOn: '2026-05-12',
        note: const Value('lunch'),
      ),
      const [],
    );
    // 维持一个 listener，避免 autoDispose 在异步加载完成前回收
    s.container
        .listen(transactionFormControllerProvider('tx1'), (_, __) {});
    // 等异步加载完成（drift IO + state update）
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = s.container.read(transactionFormControllerProvider('tx1'));
    expect(state.amountInput, '50.00');
    expect(state.categoryId, 'c-expense');
    expect(state.sourceId, 's-cash');
    expect(state.note, 'lunch');
    expect(state.isEditing, isTrue);
  });
}
