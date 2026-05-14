import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/transactions/application/transactions_list_controller.dart';

Transaction _tx({
  required String id,
  String date = '2026-05-13',
  String categoryId = 'cFood',
  String sourceId = 's1',
}) =>
    Transaction(
      id: id,
      amountCents: 100,
      currency: 'CAD',
      type: TransactionType.expense,
      categoryId: categoryId,
      sourceId: sourceId,
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

  group('TransactionsFilter extensions', () {
    test('isEmpty 仅当所有字段为 null/false 时为 true', () {
      expect(const TransactionsFilter().isEmpty, isTrue);
      expect(const TransactionsFilter(untagged: true).isEmpty, isFalse);
      expect(const TransactionsFilter(tagId: 't1').isEmpty, isFalse);
      expect(const TransactionsFilter(sourceId: 's2').isEmpty, isFalse);
      expect(
        const TransactionsFilter(
          dateStartIso: '2026-05-01',
          dateEndIso: '2026-05-31',
        ).isEmpty,
        isFalse,
      );
    });

    test('hasDateRange 需要两端都有值', () {
      expect(
        const TransactionsFilter(
          dateStartIso: '2026-05-01',
          dateEndIso: '2026-05-31',
        ).hasDateRange,
        isTrue,
      );
      expect(
        const TransactionsFilter(dateStartIso: '2026-05-01').hasDateRange,
        isFalse,
      );
      expect(const TransactionsFilter().hasDateRange, isFalse);
    });

    test('sourceId 按来源账户过滤', () {
      const f = TransactionsFilter(sourceId: 's2');
      expect(f.matches(_tx(id: 'a', sourceId: 's2')), isTrue);
      expect(f.matches(_tx(id: 'b', sourceId: 's1')), isFalse);
    });

    test('tagId 要求 tagIds 中包含该 id', () {
      const f = TransactionsFilter(tagId: 'tTravel');
      // tagIds 包含目标 tag → 通过
      expect(
        f.matches(_tx(id: 'a'), tagIds: {'tTravel', 'tFood'}),
        isTrue,
      );
      // tagIds 不含 → 不通过
      expect(
        f.matches(_tx(id: 'b'), tagIds: {'tFood'}),
        isFalse,
      );
      // tagIds 为 null → 不通过
      expect(f.matches(_tx(id: 'c')), isFalse);
    });

    test('untagged 仅匹配无标签行', () {
      const f = TransactionsFilter(untagged: true);
      // 无标签：tagIds 为 null 或空集
      expect(f.matches(_tx(id: 'a')), isTrue);
      expect(f.matches(_tx(id: 'b'), tagIds: {}), isTrue);
      // 有标签 → 不通过
      expect(f.matches(_tx(id: 'c'), tagIds: {'tFood'}), isFalse);
    });
  });
}
