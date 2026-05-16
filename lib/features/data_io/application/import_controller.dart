import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'csv_importer.dart';
import 'transactions_xlsx.dart';

const _uuid = Uuid();

/// 默认 fallback 视觉（导入时新建的 category/tag/source 用）。
const _kDefaultCatColor = '#64748b';
const _kDefaultCatIcon = 'tag';
const _kDefaultTagColor = '#94a3b8';
const _kDefaultSrcColor = '#10b981';
const _kDefaultSrcIcon = 'wallet';

/// 导入结果摘要：UI 展示给用户。
class ImportSummary {
  const ImportSummary({
    required this.parsed,
    required this.imported,
    required this.duplicates,
    required this.invalid,
    required this.invalidReasons,
    required this.autoCreatedCategories,
    required this.autoCreatedTags,
    required this.autoCreatedSources,
  });

  final int parsed;
  final int imported;
  final int duplicates;
  final int invalid;
  final List<String> invalidReasons;
  final int autoCreatedCategories;
  final int autoCreatedTags;
  final int autoCreatedSources;
}

/// 用户取消选择文件时返回 null。支持 .csv 和 .xlsx（按扩展名分发）。
/// [allowDuplicates] 为 true 时跳过去重检查，所有行都会写入。
Future<ImportSummary?> importTransactionsFromPicker({
  required WidgetRef ref,
  required AppL10n l,
  bool allowDuplicates = false,
}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'xlsx'],
  );
  if (picked == null || picked.files.isEmpty) return null;
  final file = picked.files.single;
  final path = file.path;
  if (path == null) return null;

  final ext = (file.extension ?? '').toLowerCase();
  if (ext == 'xlsx') {
    final bytes = await File(path).readAsBytes();
    final outcomes = parseTransactionsXlsx(_asUint8(bytes));
    return _ingestOutcomes(
      ref: ref, l: l, outcomes: outcomes, allowDuplicates: allowDuplicates);
  } else {
    final body = await File(path).readAsString();
    final outcomes = parseCsv(body);
    return _ingestOutcomes(
      ref: ref, l: l, outcomes: outcomes, allowDuplicates: allowDuplicates);
  }
}

/// 仅 CSV 路径（保留旧签名，方便上层和测试沿用）。
Future<ImportSummary> importCsvFromString({
  required WidgetRef ref,
  required AppL10n l,
  required String body,
  bool allowDuplicates = false,
}) async {
  final outcomes = parseCsv(body);
  return _ingestOutcomes(
    ref: ref, l: l, outcomes: outcomes, allowDuplicates: allowDuplicates);
}

/// 直接从 xlsx 字节导入（UI 已自行 detect kind 后调用此函数）。
Future<ImportSummary> importTransactionsFromXlsx({
  required WidgetRef ref,
  required AppL10n l,
  required List<int> bytes,
  bool allowDuplicates = false,
}) async {
  final outcomes = parseTransactionsXlsx(_asUint8(bytes));
  return _ingestOutcomes(
    ref: ref, l: l, outcomes: outcomes, allowDuplicates: allowDuplicates);
}

/// 把解析结果写入数据库。
///
/// - 复合 key 命中已有数据 → 视为 duplicate 跳过。
/// - 引用的 category / source / tag 名字找不到时**自动创建**新条目（默认配色），
///   并继续导入这一行。
Future<ImportSummary> _ingestOutcomes({
  required WidgetRef ref,
  required AppL10n l,
  required List<CsvRowOutcome> outcomes,
  bool allowDuplicates = false,
}) async {
  final db = ref.read(appDatabaseProvider);
  final txDao = ref.read(transactionDaoProvider);

  final cats = await db.categoryDao.watchAll().first;
  final sources = await db.sourceDao.watchAll().first;
  final tags = await db.tagDao.watchAll().first;

  String displayName(String name, String? key) =>
      resolveDefaultName(l, key) ?? name;

  // 各 dictionary 的「name(lower) → row」可变索引：自动创建后会更新。
  final catByName = <String, Category>{
    for (final c in cats) displayName(c.name, c.nameKey).toLowerCase(): c,
  };
  final srcByName = <String, Source>{
    for (final s in sources) displayName(s.name, s.nameKey).toLowerCase(): s,
  };
  final tagByName = <String, Tag>{
    for (final t in tags) displayName(t.name, t.nameKey).toLowerCase(): t,
  };

  final existing = await txDao.watchAll().first;
  final existingKeys = existingDedupeKeys(existing);

  final invalidReasons = <String>[];
  var imported = 0;
  var duplicates = 0;
  var invalid = 0;
  var autoCats = 0;
  var autoTags = 0;
  var autoSrcs = 0;

  Future<String> ensureCategory(String name, TransactionType type) async {
    final existing = catByName[name.toLowerCase()];
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      id: id,
      name: name,
      type: type,
      icon: _kDefaultCatIcon,
      color: _kDefaultCatColor,
    ));
    final fresh = await db.categoryDao.findById(id);
    if (fresh != null) catByName[name.toLowerCase()] = fresh;
    autoCats++;
    return id;
  }

  Future<String> ensureSource(String name, String currency) async {
    final existing = srcByName[name.toLowerCase()];
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await db.sourceDao.insertSource(SourcesCompanion.insert(
      id: id,
      name: name,
      currency: currency,
      icon: _kDefaultSrcIcon,
      color: _kDefaultSrcColor,
    ));
    final fresh = await db.sourceDao.findById(id);
    if (fresh != null) srcByName[name.toLowerCase()] = fresh;
    autoSrcs++;
    return id;
  }

  Future<String> ensureTag(String name) async {
    final existing = tagByName[name.toLowerCase()];
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await db.tagDao.insertTag(TagsCompanion.insert(
      id: id,
      name: name,
      color: _kDefaultTagColor,
    ));
    final fresh = await db.tagDao.findById(id);
    if (fresh != null) tagByName[name.toLowerCase()] = fresh;
    autoTags++;
    return id;
  }

  await db.transaction(() async {
    for (final outcome in outcomes) {
      if (!outcome.isOk) {
        invalid++;
        if (outcome.error != null) invalidReasons.add(outcome.error!);
        continue;
      }
      final r = outcome.row!;
      final catId = await ensureCategory(r.categoryName, r.type);
      final srcId = await ensureSource(r.sourceName, r.currency);

      final key = dedupeKey(
        transactedOn: r.transactedOn,
        type: r.type,
        categoryId: catId,
        sourceId: srcId,
        amountCents: r.amountCents,
        currency: r.currency,
        note: r.note,
      );
      if (!allowDuplicates && existingKeys.contains(key)) {
        duplicates++;
        continue;
      }

      final tagIds = <String>[];
      for (final n in r.tagNames) {
        tagIds.add(await ensureTag(n));
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
    autoCreatedCategories: autoCats,
    autoCreatedTags: autoTags,
    autoCreatedSources: autoSrcs,
  );
}

Uint8List _asUint8(List<int> b) =>
    b is Uint8List ? b : Uint8List.fromList(b);
