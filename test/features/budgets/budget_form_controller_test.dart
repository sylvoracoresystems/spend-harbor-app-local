import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_period.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_scope.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/budgets/application/budget_form_controller.dart';

ProviderContainer _container(AppDatabase db) {
  final c = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
  ]);
  addTearDown(c.dispose);
  addTearDown(db.close);
  return c;
}

void main() {
  test('amountInvalid', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final n = c.read(budgetFormControllerProvider(null).notifier);
    expect(n.validate(), BudgetFormError.amountInvalid);
    n.setAmount('0');
    expect(n.validate(), BudgetFormError.amountInvalid);
  });

  test('scope=category 但未选 → categoryRequired', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final n = c.read(budgetFormControllerProvider(null).notifier);
    n.setAmount('100');
    n.setScope(BudgetScope.category);
    expect(n.validate(), BudgetFormError.categoryRequired);
  });

  test('setPeriod 自动重新对齐 startsOn 到当前周期起点', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final n = c.read(budgetFormControllerProvider(null).notifier);
    final state0 = c.read(budgetFormControllerProvider(null));
    expect(state0.startsOn, isNull);

    n.setStartsOn(DateTime(2026, 5, 13)); // 周三
    n.setPeriod(BudgetPeriod.week);
    final state = c.read(budgetFormControllerProvider(null));
    expect(state.startsOn, DateTime(2026, 5, 11)); // 当周周一

    n.setPeriod(BudgetPeriod.month);
    final state2 = c.read(budgetFormControllerProvider(null));
    expect(state2.startsOn, DateTime(2026, 5, 1));
  });

  test('submit 写入预算（scope=total）+ 自动对齐 startsOn', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n = c.read(budgetFormControllerProvider(null).notifier);
    n.setAmount('500');
    n.setCurrency('CAD');
    n.setPeriod(BudgetPeriod.month);
    n.setStartsOn(DateTime(2026, 5, 13)); // 会在 submit 时对齐到 5/1

    expect(await n.submit(), isNull);
    final rows = await db.budgetDao.watchAll().first;
    expect(rows.length, 1);
    expect(rows.first.amountCents, 50000);
    expect(rows.first.scope, BudgetScope.total);
    expect(rows.first.period, BudgetPeriod.month);
    expect(rows.first.startsOn, '2026-05-01');
    expect(rows.first.categoryId, isNull);
  });

  test('submit 写入预算（scope=category）持久化 categoryId', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      id: 'c1',
      name: 'Food',
      type: TransactionType.expense,
      icon: 'utensils',
      color: '#f97316',
    ));
    final n = c.read(budgetFormControllerProvider(null).notifier);
    n.setAmount('200');
    n.setScope(BudgetScope.category);
    n.setCategory('c1');
    expect(await n.submit(), isNull);
    final rows = await db.budgetDao.watchAll().first;
    expect(rows.first.categoryId, 'c1');
  });

  test('切回 total 自动清空 categoryId', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final n = c.read(budgetFormControllerProvider(null).notifier);
    n.setScope(BudgetScope.category);
    n.setCategory('c1');
    n.setScope(BudgetScope.total);
    expect(c.read(budgetFormControllerProvider(null)).categoryId, isNull);
  });
}
