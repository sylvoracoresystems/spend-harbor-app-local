import 'dart:typed_data';

import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import 'csv_exporter.dart';
import 'csv_importer.dart';
import 'xlsx_codec.dart';

/// Transactions 单页 xlsx 编码（对齐示例 `spend-harbor-transactions-*.xlsx`）：
/// Amount | Type | Currency | Date | Category | Tags | Source | Notes
///
/// Type 列首字母大写（Income / Expense），与示例文件一致。
Uint8List encodeTransactionsXlsx(List<CsvRow> rows) {
  final data = <List<XlsxCell?>>[
    [
      XlsxCell.str('Amount'),
      XlsxCell.str('Type'),
      XlsxCell.str('Currency'),
      XlsxCell.str('Date'),
      XlsxCell.str('Category'),
      XlsxCell.str('Tags'),
      XlsxCell.str('Source'),
      XlsxCell.str('Notes'),
    ],
    for (final r in rows)
      [
        XlsxCell.num(num.tryParse(r.amount) ?? 0),
        XlsxCell.str(_capitalize(r.type)),
        XlsxCell.str(r.currency),
        XlsxCell.str(r.transactedOn),
        XlsxCell.str(r.category),
        XlsxCell.str(r.tags),
        XlsxCell.str(r.source),
        XlsxCell.str(r.note),
      ],
  ];
  return encodeXlsx([XlsxSheet(name: 'transactions', rows: data)]);
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

/// 解析 xlsx 字节为 [CsvRowOutcome] 列表，复用 csv_importer 的下游逻辑。
List<CsvRowOutcome> parseTransactionsXlsx(Uint8List bytes) {
  final sheets = decodeXlsx(bytes);
  if (sheets.isEmpty) return const [];
  // 选第一个 sheet 名匹配 transactions 的；找不到就用 sheets.first
  final sheet = sheets.firstWhere(
    (s) => s.name.toLowerCase() == 'transactions',
    orElse: () => sheets.first,
  );
  if (sheet.rows.length < 2) return const [];

  final header = sheet.rows.first
      .map((c) => c == null ? '' : _cellString(c).toLowerCase())
      .toList();

  // 期望表头集合（顺序无关，按列名定位）
  int findCol(String name) => header.indexOf(name.toLowerCase());
  final cAmount = findCol('Amount');
  final cType = findCol('Type');
  final cCurrency = findCol('Currency');
  final cDate = findCol('Date');
  final cCategory = findCol('Category');
  final cTags = findCol('Tags');
  final cSource = findCol('Source');
  final cNotes = findCol('Notes');

  if ([cAmount, cType, cCurrency, cDate, cCategory, cSource]
      .any((i) => i < 0)) {
    throw const FormatException('xlsx transactions: header mismatch');
  }

  final out = <CsvRowOutcome>[];
  for (var i = 1; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    String s(int col) => col >= 0 && col < r.length && r[col] != null
        ? _cellString(r[col]!)
        : '';
    num? n(int col) {
      if (col < 0 || col >= r.length) return null;
      final c = r[col];
      return switch (c) {
        null => null,
        XlsxNum v => v.value,
        XlsxStr v => num.tryParse(v.value.trim()),
      };
    }

    final date = s(cDate).trim();
    if (date.isEmpty) continue; // 整行空白
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      out.add(const CsvRowOutcome.err('invalid date'));
      continue;
    }

    TransactionType type;
    try {
      type = TransactionType.fromValue(s(cType).trim().toLowerCase());
    } catch (_) {
      out.add(const CsvRowOutcome.err('invalid type'));
      continue;
    }

    final categoryName = s(cCategory).trim();
    final sourceName = s(cSource).trim();
    if (categoryName.isEmpty || sourceName.isEmpty) {
      out.add(const CsvRowOutcome.err('missing category or source'));
      continue;
    }

    final currency = s(cCurrency).trim().toUpperCase();
    if (!Currency.isSupported(currency)) {
      out.add(const CsvRowOutcome.err('unsupported currency'));
      continue;
    }

    final amount = n(cAmount);
    if (amount == null || amount <= 0) {
      out.add(const CsvRowOutcome.err('invalid amount'));
      continue;
    }

    final tagsField = cTags >= 0 ? s(cTags) : '';
    final tagNames = tagsField
        .split(RegExp(r',\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final noteRaw = cNotes >= 0 ? s(cNotes).trim() : '';
    final note = noteRaw.isEmpty ? null : noteRaw;

    out.add(CsvRowOutcome.ok(ParsedCsvRow(
      transactedOn: date,
      type: type,
      categoryName: categoryName,
      sourceName: sourceName,
      currency: currency,
      amountCents: (amount * 100).round(),
      tagNames: tagNames,
      note: note,
    )));
  }
  return out;
}

String _cellString(XlsxCell c) => switch (c) {
      XlsxStr s => s.value,
      XlsxNum n =>
        n.value is int ? n.value.toInt().toString() : n.value.toString(),
    };
