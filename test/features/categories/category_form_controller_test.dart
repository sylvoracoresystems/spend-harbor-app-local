import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/categories/application/category_form_controller.dart';

ProviderContainer _container(AppDatabase db) {
  final c = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(c.dispose);
  addTearDown(db.close);
  return c;
}

void main() {
  test('validateSync: 空名 → nameRequired', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final n = c.read(categoryFormControllerProvider((null, null)).notifier);
    expect(n.validateSync(), CategoryFormError.nameRequired);
  });

  test('new form respects initialType', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final state = c.read(
      categoryFormControllerProvider((null, TransactionType.income)),
    );
    expect(state.type, TransactionType.income);
  });

  test('submit 新建：写入 DB；同名再 submit → nameDuplicate', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n = c.read(categoryFormControllerProvider((null, null)).notifier);
    n.setName('Coffee');
    n.setType(TransactionType.expense);
    n.setIcon('coffee');
    n.setColor('#f97316');

    final err1 = await n.submit();
    expect(err1, isNull);
    var rows = await db.categoryDao.watchAll().first;
    expect(rows.length, 1);
    expect(rows.first.name, 'Coffee');
    expect(rows.first.icon, 'coffee');

    // 第二次同名（不同 id）→ duplicate
    final n2 = c.read(categoryFormControllerProvider((null, null)).notifier);
    n2.setName('coffee'); // 大小写不敏感
    n2.setType(TransactionType.expense);
    final err2 = await n2.submit();
    expect(err2, CategoryFormError.nameDuplicate);
  });

  test('submit 编辑：updateName 保留 createdAt 但更新字段', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    // 先建一个
    final n0 = c.read(categoryFormControllerProvider((null, null)).notifier);
    n0.setName('Food');
    n0.setIcon('utensils');
    n0.setColor('#10b981');
    await n0.submit();
    final cat = (await db.categoryDao.watchAll().first).first;

    // 改名
    c.listen(categoryFormControllerProvider((cat.id, null)), (_, __) {});
    final notifier = c.read(
      categoryFormControllerProvider((cat.id, null)).notifier,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    notifier.setName('Restaurants');
    notifier.setColor('#ef4444');
    final err = await notifier.submit();
    expect(err, isNull);

    final updated = await db.categoryDao.findById(cat.id);
    expect(updated!.name, 'Restaurants');
    expect(updated.color, '#ef4444');
    expect(updated.createdAt, cat.createdAt); // 不变
  });

  test('delete 软删', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n0 = c.read(categoryFormControllerProvider((null, null)).notifier);
    n0.setName('Misc');
    await n0.submit();
    final cat = (await db.categoryDao.watchAll().first).first;

    c.listen(categoryFormControllerProvider((cat.id, null)), (_, __) {});
    final notifier = c.read(
      categoryFormControllerProvider((cat.id, null)).notifier,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await notifier.delete();

    final live = await db.categoryDao.watchAll().first;
    expect(live, isEmpty);
  });
}
