import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// 单元格值：仅区分 string / number。所有其他类型（日期、bool 等）
/// 序列化前需转换为这两种之一。
sealed class XlsxCell {
  const XlsxCell();
  factory XlsxCell.str(String v) = XlsxStr;
  factory XlsxCell.num(num v) = XlsxNum;
}

class XlsxStr extends XlsxCell {
  const XlsxStr(this.value);
  final String value;
}

class XlsxNum extends XlsxCell {
  const XlsxNum(this.value);
  final num value;
}

/// 单页：name + 多行（每行多个单元格，长度可不一致）。
class XlsxSheet {
  const XlsxSheet({required this.name, required this.rows});
  final String name;
  final List<List<XlsxCell?>> rows;
}

/// 把若干 [XlsxSheet] 编码成 .xlsx 文件字节（OOXML SpreadsheetML 最小子集）。
Uint8List encodeXlsx(List<XlsxSheet> sheets) {
  // 1. 收集所有字符串到 sharedStrings 表（去重）
  final sharedStrings = <String>[];
  final stringIndex = <String, int>{};
  int internStr(String v) {
    final existing = stringIndex[v];
    if (existing != null) return existing;
    final idx = sharedStrings.length;
    sharedStrings.add(v);
    stringIndex[v] = idx;
    return idx;
  }

  // 2. 为每个 sheet 生成 xml 字符串
  final sheetXmls = <String>[];
  for (final sheet in sheets) {
    final buf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<worksheet xmlns="http://schemas.openxmlformats.org/'
          'spreadsheetml/2006/main"><sheetData>');
    for (var rowIdx = 0; rowIdx < sheet.rows.length; rowIdx++) {
      final row = sheet.rows[rowIdx];
      buf.write('<row r="${rowIdx + 1}">');
      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        final cell = row[colIdx];
        if (cell == null) continue;
        final ref = '${_colLetter(colIdx)}${rowIdx + 1}';
        switch (cell) {
          case XlsxStr s:
            final i = internStr(s.value);
            buf.write('<c r="$ref" t="s"><v>$i</v></c>');
          case XlsxNum n:
            buf.write('<c r="$ref"><v>${n.value}</v></c>');
        }
      }
      buf.write('</row>');
    }
    buf.write('</sheetData></worksheet>');
    sheetXmls.add(buf.toString());
  }

  // 3. sharedStrings.xml
  final ssBuf = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write('<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/'
        '2006/main" count="${sharedStrings.length}" '
        'uniqueCount="${sharedStrings.length}">');
  for (final s in sharedStrings) {
    ssBuf.write('<si><t xml:space="preserve">${_xmlEscape(s)}</t></si>');
  }
  ssBuf.write('</sst>');

  // 4. workbook.xml + workbook.rels + content types + root rels
  final workbookBuf = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/'
        '2006/main" xmlns:r="http://schemas.openxmlformats.org/'
        'officeDocument/2006/relationships"><sheets>');
  for (var i = 0; i < sheets.length; i++) {
    workbookBuf.write('<sheet name="${_xmlEscape(sheets[i].name)}" '
        'sheetId="${i + 1}" r:id="rId${i + 1}"/>');
  }
  workbookBuf.write('</sheets></workbook>');

  final workbookRelsBuf = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write('<Relationships xmlns="http://schemas.openxmlformats.org/package/'
        '2006/relationships">');
  for (var i = 0; i < sheets.length; i++) {
    workbookRelsBuf.write('<Relationship Id="rId${i + 1}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
        'relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>');
  }
  workbookRelsBuf.write('<Relationship Id="rId${sheets.length + 1}" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
      'relationships/sharedStrings" Target="sharedStrings.xml"/>');
  workbookRelsBuf.write('</Relationships>');

  final contentTypesBuf = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write('<Types xmlns="http://schemas.openxmlformats.org/package/'
        '2006/content-types">')
    ..write('<Default Extension="rels" ContentType="application/vnd.'
        'openxmlformats-package.relationships+xml"/>')
    ..write('<Default Extension="xml" ContentType="application/xml"/>')
    ..write('<Override PartName="/xl/workbook.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'spreadsheetml.sheet.main+xml"/>')
    ..write('<Override PartName="/xl/sharedStrings.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'spreadsheetml.sharedStrings+xml"/>');
  for (var i = 0; i < sheets.length; i++) {
    contentTypesBuf.write('<Override PartName="/xl/worksheets/sheet${i + 1}'
        '.xml" ContentType="application/vnd.openxmlformats-officedocument.'
        'spreadsheetml.worksheet+xml"/>');
  }
  contentTypesBuf.write('</Types>');

  const rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/'
      '2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/'
      'officeDocument/2006/relationships/officeDocument" '
      'Target="xl/workbook.xml"/>'
      '</Relationships>';

  // 5. 打包成 zip
  final archive = Archive()
    ..addFile(_file('[Content_Types].xml', contentTypesBuf.toString()))
    ..addFile(_file('_rels/.rels', rootRels))
    ..addFile(_file('xl/workbook.xml', workbookBuf.toString()))
    ..addFile(_file('xl/_rels/workbook.xml.rels', workbookRelsBuf.toString()))
    ..addFile(_file('xl/sharedStrings.xml', ssBuf.toString()));
  for (var i = 0; i < sheetXmls.length; i++) {
    archive.addFile(_file('xl/worksheets/sheet${i + 1}.xml', sheetXmls[i]));
  }
  final out = ZipEncoder().encode(archive);
  return Uint8List.fromList(out);
}

ArchiveFile _file(String name, String body) {
  final bytes = utf8.encode(body);
  return ArchiveFile(name, bytes.length, bytes);
}

/// 解码 .xlsx 字节为 sheets 列表。表头行就是普通行，由调用方处理。
List<XlsxSheet> decodeXlsx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);

  // 1. workbook.xml → sheet name + rId 对照
  final workbook = _readUtf8(archive, 'xl/workbook.xml');
  if (workbook == null) {
    throw const FormatException('xlsx: missing xl/workbook.xml');
  }
  final wbDoc = XmlDocument.parse(workbook);
  final sheetEntries = <({String name, String rid})>[
    for (final s in wbDoc.findAllElements('sheet'))
      (
        name: s.getAttribute('name') ?? '',
        rid: s.getAttribute('r:id') ?? s.getAttribute('id') ?? '',
      ),
  ];

  // 2. workbook rels → rId → target path
  final wbRels = _readUtf8(archive, 'xl/_rels/workbook.xml.rels');
  final ridToTarget = <String, String>{};
  if (wbRels != null) {
    final relDoc = XmlDocument.parse(wbRels);
    for (final r in relDoc.findAllElements('Relationship')) {
      final id = r.getAttribute('Id');
      final target = r.getAttribute('Target');
      if (id != null && target != null) ridToTarget[id] = target;
    }
  }

  // 3. sharedStrings.xml
  final sharedStrings = <String>[];
  final ss = _readUtf8(archive, 'xl/sharedStrings.xml');
  if (ss != null) {
    final ssDoc = XmlDocument.parse(ss);
    for (final si in ssDoc.findAllElements('si')) {
      // 拼接所有 t 节点（rich text 也走这里）
      final buf = StringBuffer();
      for (final t in si.findAllElements('t')) {
        buf.write(t.innerText);
      }
      sharedStrings.add(buf.toString());
    }
  }

  // 4. 解析每个 sheet
  final result = <XlsxSheet>[];
  for (final entry in sheetEntries) {
    final target = ridToTarget[entry.rid];
    if (target == null) continue;
    final sheetPath = target.startsWith('/')
        ? target.substring(1)
        : 'xl/$target';
    final sheetXml = _readUtf8(archive, sheetPath);
    if (sheetXml == null) continue;
    final sheetDoc = XmlDocument.parse(sheetXml);
    final rows = <List<XlsxCell?>>[];
    for (final row in sheetDoc.findAllElements('row')) {
      final cells = <XlsxCell?>[];
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        final colIdx = ref == null ? cells.length : _colIndex(ref);
        while (cells.length < colIdx) {
          cells.add(null);
        }
        final t = c.getAttribute('t');
        // <v> 可能在内联 <is><t> 形式（t="inlineStr"）或 <v>
        XlsxCell? value;
        if (t == 'inlineStr') {
          final s = c.findAllElements('t').map((e) => e.innerText).join();
          value = XlsxStr(s);
        } else {
          final vText = c.findElements('v').firstOrNull?.innerText;
          if (vText == null || vText.isEmpty) {
            value = null;
          } else if (t == 's') {
            final idx = int.tryParse(vText);
            value = idx == null || idx >= sharedStrings.length
                ? XlsxStr(vText)
                : XlsxStr(sharedStrings[idx]);
          } else if (t == 'b') {
            value = XlsxStr(vText == '1' ? 'true' : 'false');
          } else {
            // 缺省按数字处理，失败则按字符串
            final n = num.tryParse(vText);
            value = n == null ? XlsxStr(vText) : XlsxNum(n);
          }
        }
        cells.add(value);
      }
      rows.add(cells);
    }
    result.add(XlsxSheet(name: entry.name, rows: rows));
  }
  return result;
}

String? _readUtf8(Archive archive, String path) {
  final f = archive.findFile(path);
  if (f == null) return null;
  return utf8.decode(f.content as List<int>);
}

/// 把 0-based 列号转成 Excel 字母（0→A, 25→Z, 26→AA, ...）。
String _colLetter(int idx) {
  var n = idx;
  final buf = StringBuffer();
  while (true) {
    buf.writeCharCode('A'.codeUnitAt(0) + (n % 26));
    n = n ~/ 26 - 1;
    if (n < 0) break;
  }
  return String.fromCharCodes(buf.toString().codeUnits.reversed);
}

/// "A1" / "AB12" → 0-based 列号。
int _colIndex(String ref) {
  var i = 0;
  while (i < ref.length && _isLetter(ref.codeUnitAt(i))) {
    i++;
  }
  if (i == 0) return 0;
  var col = 0;
  for (var j = 0; j < i; j++) {
    col = col * 26 + (ref.codeUnitAt(j) - 'A'.codeUnitAt(0) + 1);
  }
  return col - 1;
}

bool _isLetter(int code) =>
    (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) ||
    (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0));

String _xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
