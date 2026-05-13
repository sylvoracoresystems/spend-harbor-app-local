import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/transactions/application/transactions_list_controller.dart';

Transaction _tx({
  required String id,
  String date = '2026-05-13',
  String categoryId = 'cFood',
}) =>
    Transaction(
      id: id,
      amountCents: 100,
      currency: 'CAD',
      type: TransactionType.expense,
      categoryId: categoryId,
      sourceId: 's1',
      transactedOn: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  group('TransactionsFilter.matches', () {
    test('空 filter 全部通过', () {
      const f = TransactionsFilter();
      expect(f.isEmpty, isTrue);
      expect(f.matches(_tx(id: 'a')), isTrue);
    });
    test('按日期', () {
      const f = TransactionsFilter(dayIso: '2026-05-13');
      expect(f.matches(_tx(id: 'a', date: '2026-05-13')), isTrue);
      expect(f.matches(_tx(id: 'b', date: '2026-05-14')), isFalse);
    });
    test('按分类', () {
      const f = TransactionsFilter(categoryId: 'cFood');
      expect(f.matches(_tx(id: 'a', categoryId: 'cFood')), isTrue);
      expect(f.matches(_tx(id: 'b', categoryId: 'cOther')), isFalse);
    });
    test('两者都设：必须都匹配', () {
      const f =
          TransactionsFilter(dayIso: '2026-05-13', categoryId: 'cFood');
      expect(
        f.matches(_tx(id: 'a', date: '2026-05-13', categoryId: 'cFood')),
        isTrue,
      );
      expect(
        f.matches(_tx(id: 'b', date: '2026-05-13', categoryId: 'cOther')),
        isFalse,
      );
    });
  });
}
