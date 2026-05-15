import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'taxonomy_xlsx.dart';

const _uuid = Uuid();

class TaxonomyImportSummary {
  const TaxonomyImportSummary({
    required this.categoriesAdded,
    required this.categoriesUpdated,
    required this.categoriesDeleted,
    required this.tagsAdded,
    required this.tagsUpdated,
    required this.tagsDeleted,
    required this.sourcesAdded,
    required this.sourcesUpdated,
    required this.sourcesDeleted,
    required this.invalidRows,
  });

  final int categoriesAdded;
  final int categoriesUpdated;
  final int categoriesDeleted;
  final int tagsAdded;
  final int tagsUpdated;
  final int tagsDeleted;
  final int sourcesAdded;
  final int sourcesUpdated;
  final int sourcesDeleted;
  final List<String> invalidRows;
}

Future<TaxonomyImportSummary?> importTaxonomyFromPicker({
  required WidgetRef ref,
  required AppL10n l,
}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
  );
  if (picked == null || picked.files.isEmpty) return null;
  final path = picked.files.single.path;
  if (path == null) return null;
  final bytes = await File(path).readAsBytes();
  return importTaxonomyFromBytes(ref: ref, l: l, bytes: bytes);
}

/// 「清空后重建」语义的安全实现（FK-safe）：
/// - 已存在 (按 name 大小写不敏感) 的项 → 更新 icon/color/sort/type/currency
/// - xlsx 里新增的 → 插入
/// - DB 有但 xlsx 没有的 → 软删除（保留外键引用，UI 不再展示）
Future<TaxonomyImportSummary> importTaxonomyFromBytes({
  required WidgetRef ref,
  required AppL10n l,
  required List<int> bytes,
}) async {
  final db = ref.read(appDatabaseProvider);
  final parsed = decodeTaxonomyXlsx(_asUint8(bytes));

  final existingCats = await db.categoryDao.watchAll().first;
  final existingTags = await db.tagDao.watchAll().first;
  final existingSrcs = await db.sourceDao.watchAll().first;

  String displayName(String name, String? key) =>
      resolveDefaultName(l, key) ?? name;

  final catByName = {
    for (final c in existingCats)
      displayName(c.name, c.nameKey).toLowerCase(): c,
  };
  final tagByName = {
    for (final t in existingTags)
      displayName(t.name, t.nameKey).toLowerCase(): t,
  };
  final srcByName = {
    for (final s in existingSrcs)
      displayName(s.name, s.nameKey).toLowerCase(): s,
  };

  final keptCatIds = <String>{};
  final keptTagIds = <String>{};
  final keptSrcIds = <String>{};
  var catsAdded = 0, catsUpdated = 0, catsDeleted = 0;
  var tagsAdded = 0, tagsUpdated = 0, tagsDeleted = 0;
  var srcsAdded = 0, srcsUpdated = 0, srcsDeleted = 0;

  await db.transaction(() async {
    for (final p in parsed.categories) {
      final existing = catByName[p.name.toLowerCase()];
      if (existing != null) {
        await db.categoryDao.updateCategory(CategoriesCompanion(
          id: Value(existing.id),
          name: Value(p.name),
          nameKey: const Value(null),
          type: Value(p.type),
          icon: Value(p.icon),
          color: Value(p.color),
          isDefault: Value(existing.isDefault),
          sortOrder: Value(p.sortOrder),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ));
        keptCatIds.add(existing.id);
        catsUpdated++;
      } else {
        await db.categoryDao.insertCategory(CategoriesCompanion.insert(
          id: _uuid.v4(),
          name: p.name,
          type: p.type,
          icon: p.icon,
          color: p.color,
          sortOrder: Value(p.sortOrder),
        ));
        catsAdded++;
      }
    }
    for (final p in parsed.tags) {
      final existing = tagByName[p.name.toLowerCase()];
      if (existing != null) {
        await db.tagDao.updateTag(TagsCompanion(
          id: Value(existing.id),
          name: Value(p.name),
          nameKey: const Value(null),
          color: Value(p.color),
          isDefault: Value(existing.isDefault),
          sortOrder: Value(p.sortOrder),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ));
        keptTagIds.add(existing.id);
        tagsUpdated++;
      } else {
        await db.tagDao.insertTag(TagsCompanion.insert(
          id: _uuid.v4(),
          name: p.name,
          color: p.color,
          sortOrder: Value(p.sortOrder),
        ));
        tagsAdded++;
      }
    }
    for (final p in parsed.sources) {
      final existing = srcByName[p.name.toLowerCase()];
      if (existing != null) {
        await db.sourceDao.updateSource(SourcesCompanion(
          id: Value(existing.id),
          name: Value(p.name),
          nameKey: const Value(null),
          icon: Value(p.icon),
          color: Value(p.color),
          currency: Value(p.currency),
          isDefault: Value(existing.isDefault),
          sortOrder: Value(p.sortOrder),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ));
        keptSrcIds.add(existing.id);
        srcsUpdated++;
      } else {
        await db.sourceDao.insertSource(SourcesCompanion.insert(
          id: _uuid.v4(),
          name: p.name,
          currency: p.currency,
          icon: p.icon,
          color: p.color,
          sortOrder: Value(p.sortOrder),
        ));
        srcsAdded++;
      }
    }

    for (final c in existingCats) {
      if (!keptCatIds.contains(c.id)) {
        await db.categoryDao.softDelete(c.id);
        catsDeleted++;
      }
    }
    for (final t in existingTags) {
      if (!keptTagIds.contains(t.id)) {
        await db.tagDao.softDelete(t.id);
        tagsDeleted++;
      }
    }
    for (final s in existingSrcs) {
      if (!keptSrcIds.contains(s.id)) {
        await db.sourceDao.softDelete(s.id);
        srcsDeleted++;
      }
    }
  });

  return TaxonomyImportSummary(
    categoriesAdded: catsAdded,
    categoriesUpdated: catsUpdated,
    categoriesDeleted: catsDeleted,
    tagsAdded: tagsAdded,
    tagsUpdated: tagsUpdated,
    tagsDeleted: tagsDeleted,
    sourcesAdded: srcsAdded,
    sourcesUpdated: srcsUpdated,
    sourcesDeleted: srcsDeleted,
    invalidRows: parsed.invalidRows,
  );
}

Uint8List _asUint8(List<int> b) =>
    b is Uint8List ? b : Uint8List.fromList(b);
