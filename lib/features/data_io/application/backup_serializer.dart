import 'dart:convert';

import '../../../data/database/app_database.dart';
import '../../../domain/enums/budget_period.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../../domain/enums/transaction_type.dart';

/// `.shbak` 文件 schema 版本。每次格式不兼容变更要 +1。
const int kBackupSchemaVersion = 1;

/// 全库快照（纯数据，不含 Drift 类型）。
class BackupSnapshot {
  const BackupSnapshot({
    required this.categories,
    required this.tags,
    required this.sources,
    required this.budgets,
    required this.transactions,
    required this.transactionTags,
  });

  final List<Category> categories;
  final List<Tag> tags;
  final List<Source> sources;
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final List<TransactionTag> transactionTags;
}

/// 序列化为 JSON 字符串（pretty 不开，节省空间）。
String encodeBackup(BackupSnapshot s) {
  final root = <String, dynamic>{
    'schemaVersion': kBackupSchemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'categories': [for (final c in s.categories) _category(c)],
    'tags': [for (final t in s.tags) _tag(t)],
    'sources': [for (final s in s.sources) _source(s)],
    'budgets': [for (final b in s.budgets) _budget(b)],
    'transactions': [for (final t in s.transactions) _transaction(t)],
    'transactionTags': [
      for (final t in s.transactionTags)
        {'transactionId': t.transactionId, 'tagId': t.tagId},
    ],
  };
  return jsonEncode(root);
}

/// 解码：版本不匹配抛 [BackupVersionException]，结构错误抛 [FormatException]。
BackupSnapshot decodeBackup(String body) {
  final dynamic raw = jsonDecode(body);
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('root is not an object');
  }
  final version = raw['schemaVersion'];
  if (version is! int) {
    throw const FormatException('missing schemaVersion');
  }
  if (version != kBackupSchemaVersion) {
    throw BackupVersionException(
      found: version,
      expected: kBackupSchemaVersion,
    );
  }
  return BackupSnapshot(
    categories: [
      for (final e in (raw['categories'] as List? ?? [])) _readCategory(e),
    ],
    tags: [for (final e in (raw['tags'] as List? ?? [])) _readTag(e)],
    sources: [
      for (final e in (raw['sources'] as List? ?? [])) _readSource(e),
    ],
    budgets: [
      for (final e in (raw['budgets'] as List? ?? [])) _readBudget(e),
    ],
    transactions: [
      for (final e in (raw['transactions'] as List? ?? []))
        _readTransaction(e),
    ],
    transactionTags: [
      for (final e in (raw['transactionTags'] as List? ?? []))
        TransactionTag(
          transactionId: e['transactionId'] as String,
          tagId: e['tagId'] as String,
        ),
    ],
  );
}

class BackupVersionException implements Exception {
  const BackupVersionException({required this.found, required this.expected});
  final int found;
  final int expected;
  @override
  String toString() =>
      'BackupVersionException(found=$found, expected=$expected)';
}

// ============ 序列化 ============

Map<String, dynamic> _category(Category c) => {
      'id': c.id,
      'name': c.name,
      'nameKey': c.nameKey,
      'type': c.type.value,
      'icon': c.icon,
      'color': c.color,
      'isDefault': c.isDefault,
      'sortOrder': c.sortOrder,
      'createdAt': c.createdAt.toIso8601String(),
      'updatedAt': c.updatedAt.toIso8601String(),
      'deletedAt': c.deletedAt?.toIso8601String(),
    };

Map<String, dynamic> _tag(Tag t) => {
      'id': t.id,
      'name': t.name,
      'nameKey': t.nameKey,
      'color': t.color,
      'isDefault': t.isDefault,
      'sortOrder': t.sortOrder,
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
      'deletedAt': t.deletedAt?.toIso8601String(),
    };

Map<String, dynamic> _source(Source s) => {
      'id': s.id,
      'name': s.name,
      'nameKey': s.nameKey,
      'icon': s.icon,
      'color': s.color,
      'currency': s.currency,
      'isDefault': s.isDefault,
      'sortOrder': s.sortOrder,
      'createdAt': s.createdAt.toIso8601String(),
      'updatedAt': s.updatedAt.toIso8601String(),
      'deletedAt': s.deletedAt?.toIso8601String(),
    };

Map<String, dynamic> _budget(Budget b) => {
      'id': b.id,
      'period': b.period.value,
      'scope': b.scope.value,
      'categoryId': b.categoryId,
      'amountCents': b.amountCents,
      'currency': b.currency,
      'startsOn': b.startsOn,
      'createdAt': b.createdAt.toIso8601String(),
      'updatedAt': b.updatedAt.toIso8601String(),
      'deletedAt': b.deletedAt?.toIso8601String(),
    };

Map<String, dynamic> _transaction(Transaction t) => {
      'id': t.id,
      'amountCents': t.amountCents,
      'currency': t.currency,
      'type': t.type.value,
      'categoryId': t.categoryId,
      'sourceId': t.sourceId,
      'transactedOn': t.transactedOn,
      'note': t.note,
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
      'deletedAt': t.deletedAt?.toIso8601String(),
    };

// ============ 反序列化 ============

DateTime _date(Object? v) {
  if (v is! String) throw const FormatException('missing datetime');
  return DateTime.parse(v);
}

DateTime? _dateN(Object? v) {
  if (v == null) return null;
  return _date(v);
}

Category _readCategory(dynamic e) => Category(
      id: e['id'] as String,
      name: e['name'] as String,
      nameKey: e['nameKey'] as String?,
      type: TransactionType.fromValue(e['type'] as String),
      icon: e['icon'] as String,
      color: e['color'] as String,
      isDefault: e['isDefault'] as bool? ?? false,
      sortOrder: e['sortOrder'] as int? ?? 0,
      createdAt: _date(e['createdAt']),
      updatedAt: _date(e['updatedAt']),
      deletedAt: _dateN(e['deletedAt']),
    );

Tag _readTag(dynamic e) => Tag(
      id: e['id'] as String,
      name: e['name'] as String,
      nameKey: e['nameKey'] as String?,
      color: e['color'] as String,
      isDefault: e['isDefault'] as bool? ?? false,
      sortOrder: e['sortOrder'] as int? ?? 0,
      createdAt: _date(e['createdAt']),
      updatedAt: _date(e['updatedAt']),
      deletedAt: _dateN(e['deletedAt']),
    );

Source _readSource(dynamic e) => Source(
      id: e['id'] as String,
      name: e['name'] as String,
      nameKey: e['nameKey'] as String?,
      icon: e['icon'] as String,
      color: e['color'] as String,
      currency: e['currency'] as String,
      isDefault: e['isDefault'] as bool? ?? false,
      sortOrder: e['sortOrder'] as int? ?? 0,
      createdAt: _date(e['createdAt']),
      updatedAt: _date(e['updatedAt']),
      deletedAt: _dateN(e['deletedAt']),
    );

Budget _readBudget(dynamic e) => Budget(
      id: e['id'] as String,
      period: BudgetPeriod.fromValue(e['period'] as String),
      scope: BudgetScope.fromValue(e['scope'] as String),
      categoryId: e['categoryId'] as String?,
      amountCents: e['amountCents'] as int,
      currency: e['currency'] as String,
      startsOn: e['startsOn'] as String,
      createdAt: _date(e['createdAt']),
      updatedAt: _date(e['updatedAt']),
      deletedAt: _dateN(e['deletedAt']),
    );

Transaction _readTransaction(dynamic e) => Transaction(
      id: e['id'] as String,
      amountCents: e['amountCents'] as int,
      currency: e['currency'] as String,
      type: TransactionType.fromValue(e['type'] as String),
      categoryId: e['categoryId'] as String,
      sourceId: e['sourceId'] as String,
      transactedOn: e['transactedOn'] as String,
      note: e['note'] as String?,
      createdAt: _date(e['createdAt']),
      updatedAt: _date(e['updatedAt']),
      deletedAt: _dateN(e['deletedAt']),
    );
