import 'dart:typed_data';

import '../../../data/database/app_database.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'xlsx_codec.dart';

/// Categories / Tags / Sources 的 xlsx 编码（3-sheet schema）。
///
/// 与示例 `spend-harbor-taxonomy-*.xlsx` 完全对齐：
/// - Categories: Name | Type | Icon | Color | SortOrder
/// - Tags:       Name | Icon | Color | SortOrder（icon 列对 tags 是冗余，
///   导出固定写 'tag'，导入会忽略）
/// - Sources:    Name | Currency | Icon | Color | SortOrder
class TaxonomyExportInput {
  const TaxonomyExportInput({
    required this.categories,
    required this.tags,
    required this.sources,
  });
  final List<Category> categories;
  final List<Tag> tags;
  final List<Source> sources;
}

Uint8List encodeTaxonomyXlsx({
  required TaxonomyExportInput input,
  required AppL10n l,
}) {
  String resolved(String name, String? key) =>
      resolveDefaultName(l, key) ?? name;

  final catRows = <List<XlsxCell?>>[
    [
      XlsxCell.str('Name'),
      XlsxCell.str('Type'),
      XlsxCell.str('Icon'),
      XlsxCell.str('Color'),
      XlsxCell.str('SortOrder'),
    ],
    for (final c in input.categories)
      [
        XlsxCell.str(resolved(c.name, c.nameKey)),
        XlsxCell.str(c.type.value),
        XlsxCell.str(c.icon),
        XlsxCell.str(c.color),
        XlsxCell.num(c.sortOrder),
      ],
  ];
  final tagRows = <List<XlsxCell?>>[
    [
      XlsxCell.str('Name'),
      XlsxCell.str('Icon'),
      XlsxCell.str('Color'),
      XlsxCell.str('SortOrder'),
    ],
    for (final t in input.tags)
      [
        XlsxCell.str(resolved(t.name, t.nameKey)),
        const XlsxStr('tag'),
        XlsxCell.str(t.color),
        XlsxCell.num(t.sortOrder),
      ],
  ];
  final srcRows = <List<XlsxCell?>>[
    [
      XlsxCell.str('Name'),
      XlsxCell.str('Currency'),
      XlsxCell.str('Icon'),
      XlsxCell.str('Color'),
      XlsxCell.str('SortOrder'),
    ],
    for (final s in input.sources)
      [
        XlsxCell.str(resolved(s.name, s.nameKey)),
        XlsxCell.str(s.currency),
        XlsxCell.str(s.icon),
        XlsxCell.str(s.color),
        XlsxCell.num(s.sortOrder),
      ],
  ];

  return encodeXlsx([
    XlsxSheet(name: 'Categories', rows: catRows),
    XlsxSheet(name: 'Tags', rows: tagRows),
    XlsxSheet(name: 'Sources', rows: srcRows),
  ]);
}

/// 解析阶段产物。重名规则与默认值由调用方决定。
class ParsedTaxonomy {
  const ParsedTaxonomy({
    required this.categories,
    required this.tags,
    required this.sources,
    required this.invalidRows,
  });
  final List<ParsedCategory> categories;
  final List<ParsedTag> tags;
  final List<ParsedSource> sources;

  /// 跳过的非法行：sheet 名 + 行号 + 原因。
  final List<String> invalidRows;
}

/// xlsx 解析后的单条分类记录（待入库前的中间结构）。
class ParsedCategory {
  const ParsedCategory({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });
  final String name;
  final TransactionType type;
  final String icon;
  final String color;
  final int sortOrder;
}

/// xlsx 解析后的单条标签记录。
class ParsedTag {
  const ParsedTag({
    required this.name,
    required this.color,
    required this.sortOrder,
  });
  final String name;
  final String color;
  final int sortOrder;
}

/// xlsx 解析后的单条来源记录。
class ParsedSource {
  const ParsedSource({
    required this.name,
    required this.currency,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });
  final String name;
  final String currency;
  final String icon;
  final String color;
  final int sortOrder;
}

ParsedTaxonomy decodeTaxonomyXlsx(Uint8List bytes) {
  final sheets = decodeXlsx(bytes);
  final invalid = <String>[];

  final cats = <ParsedCategory>[];
  final tags = <ParsedTag>[];
  final srcs = <ParsedSource>[];

  for (final sheet in sheets) {
    switch (sheet.name.toLowerCase()) {
      case 'categories':
        _parseCategoriesSheet(sheet, cats, invalid);
      case 'tags':
        _parseTagsSheet(sheet, tags, invalid);
      case 'sources':
        _parseSourcesSheet(sheet, srcs, invalid);
    }
  }

  return ParsedTaxonomy(
    categories: cats,
    tags: tags,
    sources: srcs,
    invalidRows: invalid,
  );
}

void _parseCategoriesSheet(
  XlsxSheet sheet,
  List<ParsedCategory> out,
  List<String> invalid,
) {
  if (sheet.rows.length < 2) return;
  for (var i = 1; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    final name = _str(r, 0);
    final typeRaw = _str(r, 1);
    final icon = _str(r, 2);
    final color = _str(r, 3);
    final sortOrder = _int(r, 4) ?? 0;

    if (name.isEmpty) {
      continue; // 整行空白跳过，不计错误
    }
    TransactionType type;
    try {
      type = TransactionType.fromValue(typeRaw.toLowerCase());
    } catch (_) {
      invalid.add('Categories row ${i + 1}: invalid type "$typeRaw"');
      continue;
    }
    if (!_validHex(color)) {
      invalid.add('Categories row ${i + 1}: invalid color "$color"');
      continue;
    }
    out.add(ParsedCategory(
      name: name,
      type: type,
      icon: icon.isEmpty ? 'tag' : icon,
      color: _normalizeHex(color),
      sortOrder: sortOrder,
    ));
  }
}

void _parseTagsSheet(
  XlsxSheet sheet,
  List<ParsedTag> out,
  List<String> invalid,
) {
  if (sheet.rows.length < 2) return;
  // Tags 表头是 Name | Icon | Color | SortOrder（icon 列在 DB 中冗余）
  for (var i = 1; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    final name = _str(r, 0);
    final color = _str(r, 2);
    final sortOrder = _int(r, 3) ?? 0;

    if (name.isEmpty) continue;
    if (!_validHex(color)) {
      invalid.add('Tags row ${i + 1}: invalid color "$color"');
      continue;
    }
    out.add(ParsedTag(
      name: name,
      color: _normalizeHex(color),
      sortOrder: sortOrder,
    ));
  }
}

void _parseSourcesSheet(
  XlsxSheet sheet,
  List<ParsedSource> out,
  List<String> invalid,
) {
  if (sheet.rows.length < 2) return;
  for (var i = 1; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    final name = _str(r, 0);
    final currency = _str(r, 1).toUpperCase();
    final icon = _str(r, 2);
    final color = _str(r, 3);
    final sortOrder = _int(r, 4) ?? 0;

    if (name.isEmpty) continue;
    if (!Currency.isSupported(currency)) {
      invalid.add('Sources row ${i + 1}: unsupported currency "$currency"');
      continue;
    }
    if (!_validHex(color)) {
      invalid.add('Sources row ${i + 1}: invalid color "$color"');
      continue;
    }
    out.add(ParsedSource(
      name: name,
      currency: currency,
      icon: icon.isEmpty ? 'wallet' : icon,
      color: _normalizeHex(color),
      sortOrder: sortOrder,
    ));
  }
}

String _str(List<XlsxCell?> row, int col) {
  if (col >= row.length) return '';
  final c = row[col];
  return switch (c) {
    null => '',
    XlsxStr s => s.value.trim(),
    XlsxNum n => n.value.toString(),
  };
}

int? _int(List<XlsxCell?> row, int col) {
  if (col >= row.length) return null;
  final c = row[col];
  return switch (c) {
    null => null,
    XlsxStr s => int.tryParse(s.value.trim()),
    XlsxNum n => n.value.toInt(),
  };
}

bool _validHex(String s) =>
    RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(s);

String _normalizeHex(String s) {
  final v = s.startsWith('#') ? s : '#$s';
  return v.toLowerCase();
}
