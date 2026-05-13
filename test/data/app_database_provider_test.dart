import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/data/seed/default_data.dart';
import 'package:spend_harbor_app_local/data/seed/seed_locale_from_platform.dart';

void main() {
  group('seedLocaleFromPlatform', () {
    test('中文 locale → zhCN', () {
      expect(seedLocaleFromPlatform(const Locale('zh')), SeedLocale.zhCN);
      expect(seedLocaleFromPlatform(const Locale('zh', 'CN')), SeedLocale.zhCN);
    });
    test('其它 locale 落回 enUS', () {
      expect(seedLocaleFromPlatform(const Locale('en')), SeedLocale.enUS);
      expect(seedLocaleFromPlatform(const Locale('fr')), SeedLocale.enUS);
    });
  });

  test('appDatabaseProvider 通过 override 暴露 DAO + 流式更新', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    expect(container.read(categoryDaoProvider), same(db.categoryDao));
    expect(container.read(transactionDaoProvider), same(db.transactionDao));

    // seed 后通过 provider 取到 14 个默认分类
    await seedDefaultData(db, locale: SeedLocale.enUS);
    final snapshot = await container.read(allCategoriesProvider.future);
    expect(snapshot.length, 14);
  });
}
