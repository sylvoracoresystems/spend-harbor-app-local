import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/data_io/application/csv_importer.dart';

const _header =
    'Date,Type,Category,Source,Currency,Amount,Tags,Note\r\n';

void main() {
  group('parseCsv', () {
    test('合法单行', () {
      final out = parseCsv(
        '${_header}2026-05-13,expense,Food,Cash,CAD,12.34,"Work, Personal",lunch\r\n',
      );
      expect(out.length, 1);
      expect(out.first.isOk, isTrue);
      final r = out.first.row!;
      expect(r.transactedOn, '2026-05-13');
      expect(r.type, TransactionType.expense);
      expect(r.amountCents, 1234);
      expect(r.tagNames, ['Work', 'Personal']);
      expect(r.note, 'lunch');
    });

    test('日期非法 → invalid', () {
      final out = parseCsv(
        '${_header}2026/05/13,expense,Food,Cash,CAD,1,,\r\n',
      );
      expect(out.first.isOk, isFalse);
    });

    test('金额为 0 或负 → invalid', () {
      final out = parseCsv(
        '${_header}2026-05-13,expense,Food,Cash,CAD,0,,\r\n'
        '2026-05-13,expense,Food,Cash,CAD,-1,,\r\n',
      );
      expect(out.every((o) => !o.isOk), isTrue);
    });

    test('未知币种 → invalid', () {
      final out = parseCsv(
        '${_header}2026-05-13,expense,Food,Cash,XXX,1.00,,\r\n',
      );
      expect(out.first.isOk, isFalse);
    });

    test('表头不匹配 → 抛 FormatException', () {
      expect(
        () => parseCsv('Foo,Bar\r\n1,2\r\n'),
        throwsFormatException,
      );
    });
  });

  group('dedupe', () {
    Transaction _tx(String id, {String? note, int cents = 1000}) =>
        Transaction(
          id: id,
          amountCents: cents,
          currency: 'CAD',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          transactedOn: '2026-05-13',
          note: note,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('相同 6 字段 + note → 同 key', () {
      expect(
        dedupeKey(
          transactedOn: '2026-05-13',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          amountCents: 1000,
          currency: 'CAD',
          note: 'lunch',
        ),
        dedupeKey(
          transactedOn: '2026-05-13',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          amountCents: 1000,
          currency: 'CAD',
          note: 'lunch',
        ),
      );
    });

    test('note 不同 → 不同 key', () {
      expect(
        dedupeKey(
          transactedOn: '2026-05-13',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          amountCents: 1000,
          currency: 'CAD',
          note: 'a',
        ),
        isNot(equals(dedupeKey(
          transactedOn: '2026-05-13',
          type: TransactionType.expense,
          categoryId: 'c1',
          sourceId: 's1',
          amountCents: 1000,
          currency: 'CAD',
          note: 'b',
        ))),
      );
    });

    test('existingDedupeKeys 反映现有库', () {
      final keys = existingDedupeKeys([_tx('a'), _tx('b', cents: 2000)]);
      expect(keys.length, 2);
    });
  });
}
