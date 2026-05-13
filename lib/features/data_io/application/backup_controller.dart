import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../shared/providers/preferences_provider.dart';
import 'backup_reminder.dart';
import 'backup_serializer.dart';

/// 把整个数据库写成 `.shbak` 文件并调起系统分享。
Future<String> exportBackup({required WidgetRef ref}) async {
  final db = ref.read(appDatabaseProvider);
  final snapshot = await _readAll(db);
  final body = encodeBackup(snapshot);

  final dir = await getTemporaryDirectory();
  final ts = DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
  final filename = 'spendharbor_$ts.shbak';
  final file = File('${dir.path}/$filename');
  await file.writeAsString(body);

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(file.path, mimeType: 'application/json', name: filename),
      ],
      subject: filename,
    ),
  );
  // 备份提醒：记录最近一次备份时间
  await markBackupCompleted(ref.read(sharedPreferencesProvider));
  ref.invalidate(backupStatusProvider);
  return file.path;
}

/// 选文件 → 全库替换。用户取消时返回 false；成功时 true。
/// 失败抛 [BackupVersionException] 或 [FormatException]。
Future<bool> restoreBackup({required WidgetRef ref}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['shbak', 'json'],
  );
  if (picked == null || picked.files.isEmpty) return false;
  final path = picked.files.single.path;
  if (path == null) return false;
  final body = await File(path).readAsString();
  final snapshot = decodeBackup(body);
  await _applySnapshot(ref.read(appDatabaseProvider), snapshot);
  return true;
}

Future<BackupSnapshot> _readAll(AppDatabase db) async {
  final categories = await db.select(db.categories).get();
  final tags = await db.select(db.tags).get();
  final sources = await db.select(db.sources).get();
  final budgets = await db.select(db.budgets).get();
  final transactions = await db.select(db.transactions).get();
  final transactionTags = await db.select(db.transactionTags).get();
  return BackupSnapshot(
    categories: categories,
    tags: tags,
    sources: sources,
    budgets: budgets,
    transactions: transactions,
    transactionTags: transactionTags,
  );
}

/// 「替换」语义：先清空所有表，再写入快照。
/// 整段在事务内执行，失败回滚。
Future<void> _applySnapshot(AppDatabase db, BackupSnapshot s) async {
  await db.transaction(() async {
    // 顺序：先删 m:n，再删主表（外键依赖）
    await db.delete(db.transactionTags).go();
    await db.delete(db.transactions).go();
    await db.delete(db.budgets).go();
    await db.delete(db.sources).go();
    await db.delete(db.tags).go();
    await db.delete(db.categories).go();

    // 主表 → 关联表
    await db.batch((b) {
      b.insertAll(db.categories, [
        for (final c in s.categories)
          CategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            nameKey: Value(c.nameKey),
            type: c.type,
            icon: c.icon,
            color: c.color,
            isDefault: Value(c.isDefault),
            sortOrder: Value(c.sortOrder),
            createdAt: Value(c.createdAt),
            updatedAt: Value(c.updatedAt),
            deletedAt: Value(c.deletedAt),
          ),
      ]);
      b.insertAll(db.tags, [
        for (final t in s.tags)
          TagsCompanion.insert(
            id: t.id,
            name: t.name,
            nameKey: Value(t.nameKey),
            color: t.color,
            isDefault: Value(t.isDefault),
            sortOrder: Value(t.sortOrder),
            createdAt: Value(t.createdAt),
            updatedAt: Value(t.updatedAt),
            deletedAt: Value(t.deletedAt),
          ),
      ]);
      b.insertAll(db.sources, [
        for (final s0 in s.sources)
          SourcesCompanion.insert(
            id: s0.id,
            name: s0.name,
            nameKey: Value(s0.nameKey),
            icon: s0.icon,
            color: s0.color,
            currency: s0.currency,
            isDefault: Value(s0.isDefault),
            sortOrder: Value(s0.sortOrder),
            createdAt: Value(s0.createdAt),
            updatedAt: Value(s0.updatedAt),
            deletedAt: Value(s0.deletedAt),
          ),
      ]);
      b.insertAll(db.budgets, [
        for (final bud in s.budgets)
          BudgetsCompanion.insert(
            id: bud.id,
            period: bud.period,
            scope: bud.scope,
            categoryId: Value(bud.categoryId),
            amountCents: bud.amountCents,
            currency: bud.currency,
            startsOn: bud.startsOn,
            createdAt: Value(bud.createdAt),
            updatedAt: Value(bud.updatedAt),
            deletedAt: Value(bud.deletedAt),
          ),
      ]);
      b.insertAll(db.transactions, [
        for (final t in s.transactions)
          TransactionsCompanion.insert(
            id: t.id,
            amountCents: t.amountCents,
            currency: t.currency,
            type: t.type,
            categoryId: t.categoryId,
            sourceId: t.sourceId,
            transactedOn: t.transactedOn,
            note: Value(t.note),
            createdAt: Value(t.createdAt),
            updatedAt: Value(t.updatedAt),
            deletedAt: Value(t.deletedAt),
          ),
      ]);
      b.insertAll(db.transactionTags, [
        for (final tt in s.transactionTags)
          TransactionTagsCompanion.insert(
            transactionId: tt.transactionId,
            tagId: tt.tagId,
          ),
      ]);
    });
  });
}
