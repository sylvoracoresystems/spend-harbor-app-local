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

/// id → 实体 的索引视图。
///
/// 列表行（TransactionListRow 等）每行都要按 id 反查分类/标签/来源，
/// 用线性 `byId` 是 O(M·N)；走 provider-level Map 后整体退到 O(M+N)，
/// 滚动时每行只做一次哈希查询。
final categoriesByIdProvider = Provider<Map<String, Category>>((ref) {
  final list = ref.watch(allCategoriesProvider).valueOrNull ?? const <Category>[];
  return {for (final c in list) c.id: c};
});

final tagsByIdProvider = Provider<Map<String, Tag>>((ref) {
  final list = ref.watch(allTagsProvider).valueOrNull ?? const <Tag>[];
  return {for (final t in list) t.id: t};
});

final sourcesByIdProvider = Provider<Map<String, Source>>((ref) {
  final list = ref.watch(allSourcesProvider).valueOrNull ?? const <Source>[];
  return {for (final s in list) s.id: s};
});
