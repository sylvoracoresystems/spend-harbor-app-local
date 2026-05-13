import 'package:csv/csv.dart';

import '../../../data/database/app_database.dart';

/// 单笔交易在导出 CSV 中的视图。
class CsvRow {
  const CsvRow({
    required this.transactedOn,
    required this.type,
    required this.category,
    required this.source,
    required this.currency,
    required this.amount,
    required this.tags,
    required this.note,
  });

  final String transactedOn;
  final String type;
  final String category;
  final String source;
  final String currency;
  final String amount; // 已格式化为两位小数字符串
  final String tags; // 逗号分隔
  final String note;
}

const _kCsvHeader = <String>[
  'Date',
  'Type',
  'Category',
  'Source',
  'Currency',
  'Amount',
  'Tags',
  'Note',
];

/// 把行序列化为 CSV 字符串（RFC 4180，逗号分隔，CRLF 换行，必要时加引号）。
String rowsToCsv(List<CsvRow> rows) {
  final out = <List<String>>[
    _kCsvHeader,
    for (final r in rows)
      [
        r.transactedOn,
        r.type,
        r.category,
        r.source,
        r.currency,
        r.amount,
        r.tags,
        r.note,
      ],
  ];
  return const ListToCsvConverter(eol: '\r\n').convert(out);
}

/// 把数据库行 + 字典联表转换为 [CsvRow]，分类/来源/标签按名字解析，找不到落回 id。
CsvRow toCsvRow({
  required Transaction tx,
  required Map<String, String> categoryNames, // id → display name
  required Map<String, String> sourceNames,
  required Map<String, String> tagNames,
  required List<String> tagIds,
}) {
  final amount = (tx.amountCents / 100).toStringAsFixed(2);
  final tags = tagIds
      .map((id) => tagNames[id] ?? id)
      .join(', ');
  return CsvRow(
    transactedOn: tx.transactedOn,
    type: tx.type.value,
    category: categoryNames[tx.categoryId] ?? tx.categoryId,
    source: sourceNames[tx.sourceId] ?? tx.sourceId,
    currency: tx.currency,
    amount: amount,
    tags: tags,
    note: tx.note ?? '',
  );
}
