import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'csv_importer.dart';

const _uuid = Uuid();

/// 导入结果摘要：UI 展示给用户。
class ImportSummary {
  const ImportSummary({
    required this.parsed,
    required this.imported,
    required this.duplicates,
    required this.invalid,
    required this.invalidReasons,
  });

  final int parsed;
  final int imported;
  final int duplicates;
  final int invalid;
  final List<String> invalidReasons;
}

/// 用户取消选择文件时返回 null。
Future<ImportSummary?> importCsvFromPicker({
  required WidgetRef ref,
  required AppL10n l,
}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (picked == null || picked.files.isEmpty) return null;
  final path = picked.files.single.path;
  if (path == null) return null;
  final body = await File(path).readAsString();
  return importCsvFromString(ref: ref, l: l, body: body);
}

/// 把 CSV 文本导入到数据库。
///
/// 解析失败 / 行格式错误 / 找不到对应分类或来源 → 视为 invalid 并跳过。
/// 复合 key 命中已有数据 → 视为 duplicate 跳过。
Future<ImportSummary> importCsvFromString({
  required WidgetRef ref,
  required AppL10n l,
  required String body,
}) async {
  final db = ref.read(appDatabaseProvider);
  final txDao = ref.read(transactionDaoProvider);

  final cats = await db.categoryDao.watchAll().first;
  final sources = await db.sourceDao.watchAll().first;
  final tags = await db.tagDao.watchAll().first;

  String displayName(String name, String? key) =>
      resolveDefaultName(l, key) ?? name;

  Map<String, String> indexByName(List<({String id, String name})> rows) {
    final map = <String, String>{};
    for (final r in rows) {
      map[r.name.toLowerCase()] = r.id;
    }
    return map;
  }

  final catByName = indexByName([
    for (final c in cats) (id: c.id, name: displayName(c.name, c.nameKey)),
  ]);
  final srcByName = indexByName([
    for (final s in sources) (id: s.id, name: displayName(s.name, s.nameKey)),
  ]);
  final tagByName = indexByName([
    for (final t in tags) (id: t.id, name: displayName(t.name, t.nameKey)),
  ]);

  final existing = await txDao.watchAll().first;
  final existingKeys = existingDedupeKeys(existing);

  final outcomes = parseCsv(body);
  final invalidReasons = <String>[];
  var imported = 0;
  var duplicates = 0;
  var invalid = 0;

  await db.transaction(() async {
    for (final outcome in outcomes) {
      if (!outcome.isOk) {
        invalid++;
        if (outcome.error != null) invalidReasons.add(outcome.error!);
        continue;
      }
      final r = outcome.row!;
      final catId = catByName[r.categoryName.toLowerCase()];
      final srcId = srcByName[r.sourceName.toLowerCase()];
      if (catId == null || srcId == null) {
        invalid++;
        invalidReasons.add('unresolved name');
        continue;
      }
      final key = dedupeKey(
        transactedOn: r.transactedOn,
        type: r.type,
        categoryId: catId,
        sourceId: srcId,
        amountCents: r.amountCents,
        currency: r.currency,
        note: r.note,
      );
      if (existingKeys.contains(key)) {
        duplicates++;
        continue;
      }

      final tagIds = <String>[];
      for (final n in r.tagNames) {
        final id = tagByName[n.toLowerCase()];
        if (id != null) tagIds.add(id);
      }

      await txDao.insertWithTags(
        TransactionsCompanion.insert(
          id: _uuid.v4(),
          amountCents: r.amountCents,
          currency: r.currency,
          type: r.type,
          categoryId: catId,
          sourceId: srcId,
          transactedOn: r.transactedOn,
          note: Value(r.note),
        ),
        tagIds,
      );
      existingKeys.add(key);
      imported++;
    }
  });

  return ImportSummary(
    parsed: outcomes.length,
    imported: imported,
    duplicates: duplicates,
    invalid: invalid,
    invalidReasons: invalidReasons,
  );
}
