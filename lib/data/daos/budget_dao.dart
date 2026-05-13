import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<Budget>> watchAll() {
    return (select(budgets)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.startsOn)]))
        .watch();
  }

  Future<Budget?> findById(String id) {
    return (select(budgets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  Future<bool> updateBudget(BudgetsCompanion entry) =>
      update(budgets).replace(entry);

  Future<int> softDelete(String id) {
    return (update(budgets)..where((t) => t.id.equals(id))).write(
      BudgetsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 级联软删：删除某分类时，把所有 scope=category 且引用该分类的预算软删掉。
  Future<int> softDeleteByCategoryId(String categoryId) {
    return (update(budgets)
          ..where((t) =>
              t.categoryId.equals(categoryId) & t.deletedAt.isNull()))
        .write(
      BudgetsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
