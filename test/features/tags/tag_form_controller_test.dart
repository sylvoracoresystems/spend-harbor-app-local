import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/features/tags/application/tag_form_controller.dart';

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
    final n = c.read(tagFormControllerProvider(null).notifier);
    expect(n.validateSync(), TagFormError.nameRequired);
  });

  test('submit 新建 + 同名 duplicate', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n = c.read(tagFormControllerProvider(null).notifier);
    n.setName('Work');
    n.setColor('#0ea5e9');
    expect(await n.submit(), isNull);
    expect((await db.tagDao.watchAll().first).length, 1);

    final n2 = c.read(tagFormControllerProvider(null).notifier);
    n2.setName('work');
    expect(await n2.submit(), TagFormError.nameDuplicate);
  });

  test('updateName 保留 createdAt', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n0 = c.read(tagFormControllerProvider(null).notifier);
    n0.setName('Misc');
    n0.setColor('#10b981');
    await n0.submit();
    final tag = (await db.tagDao.watchAll().first).first;

    c.listen(tagFormControllerProvider(tag.id), (_, __) {});
    final n = c.read(tagFormControllerProvider(tag.id).notifier);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    n.setName('Personal');
    n.setColor('#ef4444');
    expect(await n.submit(), isNull);

    final updated = await db.tagDao.findById(tag.id);
    expect(updated!.name, 'Personal');
    expect(updated.color, '#ef4444');
    expect(updated.createdAt, tag.createdAt);
  });

  test('delete 软删', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = _container(db);
    final n0 = c.read(tagFormControllerProvider(null).notifier);
    n0.setName('Throwaway');
    await n0.submit();
    final tag = (await db.tagDao.watchAll().first).first;

    c.listen(tagFormControllerProvider(tag.id), (_, __) {});
    final n = c.read(tagFormControllerProvider(tag.id).notifier);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await n.delete();
    expect(await db.tagDao.watchAll().first, isEmpty);
  });
}
