import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Stream<List<Tag>> watchAll() {
    return (select(tags)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Tag?> findById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTag(TagsCompanion entry) => into(tags).insert(entry);

  Future<bool> updateTag(TagsCompanion entry) => update(tags).replace(entry);

  /// 仅更新可编辑字段；保留 createdAt / isDefault；编辑后清空 nameKey。
  Future<int> updateName({
    required String id,
    required String name,
    required String color,
  }) {
    return (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(
        name: Value(name),
        color: Value(color),
        nameKey: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> softDelete(String id) {
    return (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> existsName(String name, {String? excludeId}) async {
    final q = select(tags)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.name.lower().equals(name.toLowerCase()));
    if (excludeId != null) {
      q.where((t) => t.id.equals(excludeId).not());
    }
    return (await q.getSingleOrNull()) != null;
  }
}
