import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../transactions/application/transactions_list_controller.dart';
import 'csv_exporter.dart';

/// 把当前选定月份的交易导出为 CSV 文件，通过系统分享面板分享。
///
/// 返回写入的临时文件路径；调用方通常无需关心。
Future<String> exportCurrentMonthToCsv({
  required WidgetRef ref,
  required AppL10n l,
}) async {
  final ym = ref.read(currentMonthProvider);
  final dao = ref.read(transactionDaoProvider);
  final db = ref.read(appDatabaseProvider);
  final rows = await dao.watchByMonth(ym.key).first;

  final cats = await db.categoryDao.watchAll().first;
  final sources = await db.sourceDao.watchAll().first;
  final tags = await db.tagDao.watchAll().first;
  final tagsByTx = await dao.tagIdsForMany(rows.map((r) => r.id).toList());

  String resolved(String name, String? key) =>
      resolveDefaultName(l, key) ?? name;

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
  final body = rowsToCsv(csvRows);

  final dir = await getTemporaryDirectory();
  final filename = 'spendharbor_${ym.key}.csv';
  final file = File('${dir.path}/$filename');
  await file.writeAsString(body);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
      subject: filename,
    ),
  );

  return file.path;
}
