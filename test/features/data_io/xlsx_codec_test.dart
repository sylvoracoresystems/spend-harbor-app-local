import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/features/data_io/application/xlsx_codec.dart';

void main() {
  test('encode → decode round-trip 保持单元格语义', () {
    final original = [
      XlsxSheet(name: 'Categories', rows: [
        [XlsxCell.str('Name'), XlsxCell.str('Type'), XlsxCell.str('SortOrder')],
        [XlsxCell.str('Food & Drink'), XlsxCell.str('expense'), XlsxCell.num(0)],
        [XlsxCell.str('Salary'), XlsxCell.str('income'), XlsxCell.num(1)],
      ]),
      XlsxSheet(name: 'Sources', rows: [
        [XlsxCell.str('Name'), XlsxCell.str('Currency')],
        [XlsxCell.str('Cash'), XlsxCell.str('CAD')],
      ]),
    ];

    final bytes = encodeXlsx(original);
    final decoded = decodeXlsx(bytes);

    expect(decoded.length, 2);
    expect(decoded[0].name, 'Categories');
    expect(decoded[1].name, 'Sources');

    // 表头
    expect((decoded[0].rows[0][0] as XlsxStr).value, 'Name');
    // 数据行字符串
    expect((decoded[0].rows[1][0] as XlsxStr).value, 'Food & Drink');
    // 数据行数字
    expect((decoded[0].rows[1][2] as XlsxNum).value, 0);
    expect((decoded[0].rows[2][2] as XlsxNum).value, 1);
    // 第二个 sheet
    expect((decoded[1].rows[1][1] as XlsxStr).value, 'CAD');
  });

  test('XML 转义：< > & " 字符正确还原', () {
    final original = [
      XlsxSheet(name: 'X', rows: [
        [XlsxCell.str('a < b & "c"')],
      ]),
    ];
    final decoded = decodeXlsx(encodeXlsx(original));
    expect((decoded[0].rows[0][0] as XlsxStr).value, 'a < b & "c"');
  });
}
