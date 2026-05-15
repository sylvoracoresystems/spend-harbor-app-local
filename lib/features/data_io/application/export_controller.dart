import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../transactions/application/transactions_list_controller.dart';
import 'csv_exporter.dart';
import 'taxonomy_xlsx.dart';
import 'transactions_xlsx.dart';

/// 导出范围：当前月 / 全部 / 自定义日期段。
enum ExportScope { currentMonth, all, range }

/// 导出格式：CSV vs XLSX。
enum ExportFormat { csv, xlsx }

/// 把交易导出为指定格式 + 范围的文件，通过系统分享面板分享。
///
/// 文件名规则：
/// - 当月 csv：`spendharbor_2026-04.csv`
/// - 当月 xlsx：`spend-harbor-transactions-2026-04-01-2026-04-30.xlsx`
/// - 全部 xlsx：`spend-harbor-transactions-{minDate}-{maxDate}.xlsx`
/// - range：`spend-harbor-transactions-{rangeStart}-{rangeEnd}.{ext}`
///
/// [rangeStart] / [rangeEnd] 仅在 [scope] 为 [ExportScope.range] 时使用，
/// 必传且 start ≤ end。格式 `YYYY-MM-DD`。
Future<String> exportTransactions({
  required WidgetRef ref,
  required AppL10n l,
  required ExportScope scope,
  required ExportFormat format,
  String? rangeStart,
  String? rangeEnd,
}) async {
  final dao = ref.read(transactionDaoProvider);
  final db = ref.read(appDatabaseProvider);

  final List<Transaction> rows;
  switch (scope) {
    case ExportScope.currentMonth:
      final ym = ref.read(currentMonthProvider);
      rows = await dao.watchByMonth(ym.key).first;
    case ExportScope.all:
      rows = await dao.watchAll().first;
    case ExportScope.range:
      assert(rangeStart != null && rangeEnd != null,
          'range scope requires rangeStart + rangeEnd');
      final all = await dao.watchAll().first;
      rows = all.where((t) {
        return t.transactedOn.compareTo(rangeStart!) >= 0 &&
            t.transactedOn.compareTo(rangeEnd!) <= 0;
      }).toList();
  }

  final cats = await db.categoryDao.watchAll().first;
  final sources = await db.sourceDao.watchAll().first;
  final tags = await db.tagDao.watchAll().first;
  final tagsByTx = await dao.tagIdsForMany(rows.map((r) => r.id).toList());

  String resolved(String name, String? key) =>
      resolveDefaultName(l, key) ?? name;

  // 导出按日期降序，与列表展示一致
  rows.sort((a, b) => b.transactedOn.compareTo(a.transactedOn));

  final csvRows = [
    for (final t in rows)
      toCsvRow(
        tx: t,
        categoryNames: {
          for (final c in cats) c.id: resolved(c.name, c.nameKey),
        },
        sourceNames: {
          for (final s in sources) s.id: resolved(s.name, s.nameKey),
        },
        tagNames: {
          for (final tag in tags) tag.id: resolved(tag.name, tag.nameKey),
        },
        tagIds: tagsByTx[t.id] ?? const [],
      ),
  ];

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_filename(
    rows,
    scope,
    format,
    ref,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
  )}');

  if (format == ExportFormat.csv) {
    await file.writeAsString(rowsToCsv(csvRows));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'text/csv', name: file.uri.pathSegments.last),
        ],
        subject: file.uri.pathSegments.last,
      ),
    );
  } else {
    await file.writeAsBytes(encodeTransactionsXlsx(csvRows));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: file.uri.pathSegments.last,
          ),
        ],
        subject: file.uri.pathSegments.last,
      ),
    );
  }

  return file.path;
}

String _filename(
  List<Transaction> rows,
  ExportScope scope,
  ExportFormat format,
  WidgetRef ref, {
  String? rangeStart,
  String? rangeEnd,
}) {
  final ext = format == ExportFormat.csv ? 'csv' : 'xlsx';
  switch (scope) {
    case ExportScope.currentMonth:
      final ym = ref.read(currentMonthProvider);
      if (format == ExportFormat.csv) {
        return 'spendharbor_${ym.key}.$ext';
      }
      final start = '${ym.key}-01';
      final lastDay = DateTime(ym.year, ym.month + 1, 0).day;
      final end = '${ym.key}-${lastDay.toString().padLeft(2, '0')}';
      return 'spend-harbor-transactions-$start-$end.$ext';
    case ExportScope.range:
      return 'spend-harbor-transactions-$rangeStart-$rangeEnd.$ext';
    case ExportScope.all:
      if (rows.isEmpty) {
        final today = DateTime.now();
        final stamp =
            '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
        return 'spend-harbor-transactions-empty-$stamp.$ext';
      }
      final dates = rows.map((r) => r.transactedOn).toList()..sort();
      return 'spend-harbor-transactions-${dates.first}-${dates.last}.$ext';
  }
}

/// 把所有 categories / tags / sources 导出为 3-sheet xlsx。
Future<String> exportTaxonomy({
  required WidgetRef ref,
  required AppL10n l,
}) async {
  final db = ref.read(appDatabaseProvider);
  final cats = await db.categoryDao.watchAll().first;
  final tags = await db.tagDao.watchAll().first;
  final sources = await db.sourceDao.watchAll().first;

  final bytes = encodeTaxonomyXlsx(
    input: TaxonomyExportInput(
      categories: cats,
      tags: tags,
      sources: sources,
    ),
    l: l,
  );

  final dir = await getTemporaryDirectory();
  final today = DateTime.now();
  final stamp =
      '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
  final filename = 'spend-harbor-taxonomy-$stamp.xlsx';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: filename,
        ),
      ],
      subject: filename,
    ),
  );

  return file.path;
}
