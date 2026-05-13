import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'source_dao.g.dart';

@DriftAccessor(tables: [Sources])
class SourceDao extends DatabaseAccessor<AppDatabase> with _$SourceDaoMixin {
  SourceDao(super.db);

  Stream<List<Source>> watchAll() {
    return (select(sources)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Source?> findById(String id) {
    return (select(sources)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSource(SourcesCompanion entry) =>
      into(sources).insert(entry);

  Future<bool> updateSource(SourcesCompanion entry) =>
      update(sources).replace(entry);

  Future<int> softDelete(String id) {
    return (update(sources)..where((t) => t.id.equals(id))).write(
      SourcesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> existsName(String name, {String? excludeId}) async {
    final q = select(sources)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.name.lower().equals(name.toLowerCase()));
    if (excludeId != null) {
      q.where((t) => t.id.equals(excludeId).not());
    }
    return (await q.getSingleOrNull()) != null;
  }
}
