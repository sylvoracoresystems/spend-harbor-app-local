import 'package:drift/drift.dart';

import '../../domain/enums/transaction_type.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 监听全部存活分类（按 sortOrder 升序）。
  Stream<List<Category>> watchAll() {
    return (select(categories)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// 监听某 type 的存活分类（用于交易表单的下拉）。
  Stream<List<Category>> watchByType(TransactionType type) {
    return (select(categories)
          ..where((t) =>
              t.deletedAt.isNull() & t.type.equalsValue(type))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Category?> findById(String id) {
    return (select(categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(entry);
  }

  /// 仅更新可编辑字段；保留 `createdAt` / `isDefault` / `nameKey`。
  /// 用户重命名默认项后清空 `nameKey`（脱离 i18n 默认名）。
  Future<int> updateName({
    required String id,
    required String name,
    required TransactionType type,
    required String icon,
    required String color,
  }) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        type: Value(type),
        icon: Value(icon),
        color: Value(color),
        nameKey: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 软删除（标记 deletedAt = now）。
  Future<int> softDelete(String id) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 检查同名是否已存在（大小写不敏感，排除已删项，可选排除某 id）。
  Future<bool> existsName(
    String name,
    TransactionType type, {
    String? excludeId,
  }) async {
    final q = select(categories)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.type.equalsValue(type) &
          t.name.lower().equals(name.toLowerCase()));
    if (excludeId != null) {
      q.where((t) => t.id.equals(excludeId).not());
    }
    final row = await q.getSingleOrNull();
    return row != null;
  }
}
