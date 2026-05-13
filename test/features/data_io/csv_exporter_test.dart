import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/data_io/application/csv_exporter.dart';

void main() {
  group('rowsToCsv', () {
    test('空行也带表头', () {
      final out = rowsToCsv(const []);
      expect(out.startsWith('Date,Type,Category'), isTrue);
      expect(out.split('\r\n').length, 1); // 仅表头
    });
    test('单行：金额 / 类型字段照搬', () {
      final out = rowsToCsv(const [
        CsvRow(
          transactedOn: '2026-05-13',
          type: 'expense',
          category: 'Food',
          source: 'Cash',
          currency: 'CAD',
          amount: '12.34',
          tags: 'Work, Personal',
          note: 'Lunch',
        ),
      ]);
      final lines = out.split('\r\n');
      expect(lines[0],
          'Date,Type,Category,Source,Currency,Amount,Tags,Note');
      expect(lines[1].startsWith('2026-05-13,expense,Food,Cash,CAD,12.34,'), isTrue);
    });
    test('字段含逗号 / 引号会被引用', () {
      final out = rowsToCsv(const [
        CsvRow(
          transactedOn: '2026-05-13',
          type: 'expense',
          category: 'Food',
          source: 'Cash',
          currency: 'CAD',
          amount: '1.00',
          tags: '',
          note: 'a,b "c"',
        ),
      ]);
      // RFC 4180: 内部双引号需写成两次双引号
      expect(out.contains('"a,b ""c"""'), isTrue);
    });
  });

  group('toCsvRow', () {
    Transaction makeTx() => Transaction(
          id: 'a',
          amountCents: 5050,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: '2026-05-13',
          note: 'lunch',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('字典命中：用 display name，金额格式化为两位小数', () {
      final row = toCsvRow(
        tx: makeTx(),
        categoryNames: const {'c1': 'Food'},
        sourceNames: const {'s1': 'Cash'},
        tagNames: const {'t1': 'Work', 't2': 'Personal'},
        tagIds: const ['t1', 't2'],
      );
      expect(row.category, 'Food');
      expect(row.source, 'Cash');
      expect(row.amount, '50.50');
      expect(row.tags, 'Work, Personal');
      expect(row.note, 'lunch');
    });
    test('字典缺失：落回 id', () {
      final row = toCsvRow(
        tx: makeTx(),
        categoryNames: const {},
        sourceNames: const {},
        tagNames: const {},
        tagIds: const [],
      );
      expect(row.category, 'c1');
      expect(row.source, 's1');
      expect(row.tags, '');
    });
  });
}
