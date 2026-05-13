import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daos/budget_dao.dart';
import '../daos/category_dao.dart';
import '../daos/source_dao.dart';
import '../daos/tag_dao.dart';
import '../daos/transaction_dao.dart';
import 'app_database.dart';

/// 全局 [AppDatabase] 实例。
/// 在 `main()` 启动时通过 `overrideWithValue` 注入已就绪（含 seed）的实例；
/// 测试中可注入 `AppDatabase.forTesting(NativeDatabase.memory())`。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in ProviderScope',
  );
});

final categoryDaoProvider =
    Provider<CategoryDao>((ref) => ref.watch(appDatabaseProvider).categoryDao);

final tagDaoProvider =
    Provider<TagDao>((ref) => ref.watch(appDatabaseProvider).tagDao);

final sourceDaoProvider =
    Provider<SourceDao>((ref) => ref.watch(appDatabaseProvider).sourceDao);

final budgetDaoProvider =
    Provider<BudgetDao>((ref) => ref.watch(appDatabaseProvider).budgetDao);

final transactionDaoProvider = Provider<TransactionDao>(
  (ref) => ref.watch(appDatabaseProvider).transactionDao,
);

/// 监听全部存活分类。
final allCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryDaoProvider).watchAll(),
);

/// 监听全部存活标签。
final allTagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagDaoProvider).watchAll(),
);

/// 监听全部存活来源。
final allSourcesProvider = StreamProvider<List<Source>>(
  (ref) => ref.watch(sourceDaoProvider).watchAll(),
);
