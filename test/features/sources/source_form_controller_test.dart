import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/features/sources/application/source_form_controller.dart';

ProviderContainer _container(AppDatabase db) {
  final c = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
  ]);
  addTearDown(c.dispose);
  addTearDown(db.close);
  return c;
}

void main() {
  test('空名 → nameRequired', () async {
    final c = _container(AppDatabase.forTesting(NativeDatabase.memory()));
    final n = c.read(sourceFormControllerProvider(null).notifier);
    expect(n.validateSync(), SourceFormError.nameRequired);
  });

  test('submit 新建 + 同名 duplicate；币种持久化', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n = c.read(sourceFormControllerProvider(null).notifier);
    n.setName('Visa');
    n.setIcon('credit-card');
    n.setColor('#0ea5e9');
    n.setCurrency('USD');
    expect(await n.submit(), isNull);
    final rows = await db.sourceDao.watchAll().first;
    expect(rows.length, 1);
    expect(rows.first.currency, 'USD');
    expect(rows.first.icon, 'credit-card');

    final n2 = c.read(sourceFormControllerProvider(null).notifier);
    n2.setName('visa');
    expect(await n2.submit(), SourceFormError.nameDuplicate);
  });

  test('updateName 改币种 + 保留 createdAt', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n0 = c.read(sourceFormControllerProvider(null).notifier);
    n0.setName('Cash');
    n0.setCurrency('CAD');
    await n0.submit();
    final src = (await db.sourceDao.watchAll().first).first;

    c.listen(sourceFormControllerProvider(src.id), (_, __) {});
    final n = c.read(sourceFormControllerProvider(src.id).notifier);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    n.setCurrency('JPY');
    n.setIcon('banknote');
    expect(await n.submit(), isNull);

    final updated = await db.sourceDao.findById(src.id);
    expect(updated!.currency, 'JPY');
    expect(updated.icon, 'banknote');
    expect(updated.createdAt, src.createdAt);
  });

  test('delete 软删', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n0 = c.read(sourceFormControllerProvider(null).notifier);
    n0.setName('Throwaway');
    await n0.submit();
    final src = (await db.sourceDao.watchAll().first).first;

    c.listen(sourceFormControllerProvider(src.id), (_, __) {});
    final n = c.read(sourceFormControllerProvider(src.id).notifier);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await n.delete();
    expect(await db.sourceDao.watchAll().first, isEmpty);
  });
}
