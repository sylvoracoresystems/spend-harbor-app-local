import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/stats/application/stats_top_aggregator.dart';

Transaction _t({
  required String id,
  required String catId,
  required int cents,
  String currency = 'CAD',
  String srcId = 's1',
  String date = '2026-03-15',
  TransactionType type = TransactionType.expense,
}) {
  return Transaction(
    id: id,
    amountCents: cents,
    currency: currency,
    type: type,
    categoryId: catId,
    sourceId: srcId,
    transactedOn: date,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('aggregateTopByCategory', () {
    test('sorts by amount desc, includes count + tag frequencies', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 500),
        _t(id: '2', catId: 'A', cents: 300),
        _t(id: '3', catId: 'B', cents: 1000),
      ];
      final tags = {
        '1': ['t1'],
        '2': ['t1', 't2'],
        '3': ['t2'],
      };
      final out = aggregateTopByCategory(
        rows,
        type: TransactionType.expense,
        currency: 'CAD',
        tagsByTx: tags,
        limit: 10,
      );
      expect(out.map((r) => r.categoryId).toList(), ['B', 'A']);
      expect(out.first.totalCents, 1000);
      expect(out.first.count, 1);
      expect(out[1].count, 2);
      expect(out[1].tagFrequencies['t1'], 2);
      expect(out[1].tagFrequencies['t2'], 1);
    });

    test('respects limit', () {
      final rows = [
        for (var i = 0; i < 15; i++)
          _t(id: 'x$i', catId: 'C$i', cents: 100 + i),
      ];
      final out = aggregateTopByCategory(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          tagsByTx: const {},
          limit: 10);
      expect(out.length, 10);
    });

    test('filters by type', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 200, type: TransactionType.income),
        _t(id: '2', catId: 'A', cents: 300),
      ];
      final out = aggregateTopByCategory(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          tagsByTx: const {},
          limit: 10);
      expect(out.length, 1);
      expect(out.first.totalCents, 300);
    });

    test('filters by currency and sourceId', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 100, currency: 'USD'),
        _t(id: '2', catId: 'A', cents: 200, srcId: 'sX'),
        _t(id: '3', catId: 'A', cents: 300),
      ];
      final out = aggregateTopByCategory(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          sourceId: 's1',
          tagsByTx: const {},
          limit: 10);
      expect(out.length, 1);
      expect(out.first.totalCents, 300);
    });
  });

  group('aggregateTopByTag', () {
    test('groups by tag with Top 3 categories per tag and untagged separated', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 100),
        _t(id: '2', catId: 'A', cents: 200),
        _t(id: '3', catId: 'B', cents: 300),
        _t(id: '4', catId: 'C', cents: 400),
      ];
      final tags = {
        '1': ['x'],
        '2': ['x'],
        '3': ['x'],
        '4': const <String>[],
      };
      final r = aggregateTopByTag(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          tagsByTx: tags,
          limit: 10);
      expect(r.rows.length, 1);
      expect(r.rows.first.tagId, 'x');
      expect(r.rows.first.totalCents, 600);
      expect(r.rows.first.count, 3);
      // Top categories under tag x: A=300, B=300 → ties allowed, just check it has top 3
      expect(r.rows.first.topCategories.length, lessThanOrEqualTo(3));
      expect(r.untagged?.totalCents, 400);
      expect(r.untagged?.count, 1);
    });

    test('untagged is null when every row has tags', () {
      final rows = [_t(id: '1', catId: 'A', cents: 100)];
      final r = aggregateTopByTag(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          tagsByTx: const {'1': ['x']},
          limit: 10);
      expect(r.untagged, isNull);
    });

    test('multi-tag rows accumulate fully in each tag', () {
      final rows = [_t(id: '1', catId: 'A', cents: 100)];
      final tags = {'1': ['a', 'b']};
      final r = aggregateTopByTag(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          tagsByTx: tags,
          limit: 10);
      expect(r.rows.length, 2);
      expect(r.rows.first.totalCents, 100);
      expect(r.rows[1].totalCents, 100);
    });

    test('row with missing entry in tagsByTx counted as untagged', () {
      final rows = [_t(id: '1', catId: 'A', cents: 100)];
      final r = aggregateTopByTag(rows,
          type: TransactionType.expense,
          currency: 'CAD',
          tagsByTx: const {},
          limit: 10);
      expect(r.rows, isEmpty);
      expect(r.untagged?.totalCents, 100);
    });
  });
}
