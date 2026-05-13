import 'package:csv/csv.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';

/// 解析阶段产物：尚未解析 category/source 等外键，仅校验字段格式。
class ParsedCsvRow {
  const ParsedCsvRow({
    required this.transactedOn,
    required this.type,
    required this.categoryName,
    required this.sourceName,
    required this.currency,
    required this.amountCents,
    required this.tagNames,
    required this.note,
  });

  final String transactedOn; // YYYY-MM-DD
  final TransactionType type;
  final String categoryName;
  final String sourceName;
  final String currency;
  final int amountCents;
  final List<String> tagNames;
  final String? note;
}

/// 单行解析结果：成功带 [row]，失败带 [error]。
class CsvRowOutcome {
  const CsvRowOutcome.ok(this.row) : error = null;
  const CsvRowOutcome.err(this.error) : row = null;
  final ParsedCsvRow? row;
  final String? error;
  bool get isOk => row != null;
}

/// 期望表头（与导出 [`rowsToCsv`] 对齐）。
const _kExpectedHeader = <String>[
  'Date',
  'Type',
  'Category',
  'Source',
  'Currency',
  'Amount',
  'Tags',
  'Note',
];

/// 解析 CSV 文本 → 行结果。表头不匹配时整体抛 [FormatException]。
List<CsvRowOutcome> parseCsv(String body) {
  final table = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(body.replaceAll('\r\n', '\n'));
  if (table.isEmpty) return const [];

  final header = table.first.map((e) => '$e').toList();
  if (header.length != _kExpectedHeader.length ||
      !List.generate(header.length, (i) => header[i] == _kExpectedHeader[i])
          .every((b) => b)) {
    throw const FormatException('CSV header mismatch');
  }

  return [
    for (final raw in table.skip(1))
      _parseRow(raw.map((e) => '$e').toList()),
  ];
}

CsvRowOutcome _parseRow(List<String> cells) {
  if (cells.length != _kExpectedHeader.length) {
    return CsvRowOutcome.err('column count');
  }
  final date = cells[0].trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    return CsvRowOutcome.err('invalid date');
  }

  TransactionType type;
  try {
    type = TransactionType.fromValue(cells[1].trim());
  } catch (_) {
    return CsvRowOutcome.err('invalid type');
  }

  final categoryName = cells[2].trim();
  final sourceName = cells[3].trim();
  if (categoryName.isEmpty || sourceName.isEmpty) {
    return CsvRowOutcome.err('missing category or source');
  }

  final currency = cells[4].trim().toUpperCase();
  if (!Currency.isSupported(currency)) {
    return CsvRowOutcome.err('unsupported currency');
  }

  final amount = double.tryParse(cells[5].trim());
  if (amount == null || amount <= 0) {
    return CsvRowOutcome.err('invalid amount');
  }

  final tags = cells[6]
      .split(RegExp(r',\s*'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final note = cells[7].trim().isEmpty ? null : cells[7].trim();

  return CsvRowOutcome.ok(ParsedCsvRow(
    transactedOn: date,
    type: type,
    categoryName: categoryName,
    sourceName: sourceName,
    currency: currency,
    amountCents: (amount * 100).round(),
    tagNames: tags,
    note: note,
  ));
}

/// 合并去重 key：避免重复导入。
String dedupeKey({
  required String transactedOn,
  required TransactionType type,
  required String categoryId,
  required String sourceId,
  required int amountCents,
  required String currency,
  required String? note,
}) =>
    '$transactedOn|${type.value}|$categoryId|$sourceId|$amountCents|$currency|${note ?? ''}';

/// 现有库内交易 → 去重 key 集合。
Set<String> existingDedupeKeys(List<Transaction> rows) {
  return rows
      .map((t) => dedupeKey(
            transactedOn: t.transactedOn,
            type: t.type,
            categoryId: t.categoryId,
            sourceId: t.sourceId,
            amountCents: t.amountCents,
            currency: t.currency,
            note: t.note,
          ))
      .toSet();
}
