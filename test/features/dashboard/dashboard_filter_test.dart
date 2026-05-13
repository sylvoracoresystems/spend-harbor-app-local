import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/dashboard/application/dashboard_filter_provider.dart';
import 'package:spend_harbor_app_local/features/dashboard/application/dashboard_summary_controller.dart';

Transaction _tx({
  required String id,
  required int cents,
  required TransactionType type,
  String currency = 'CAD',
  String sourceId = 's1',
}) => Transaction(
  id: id,
  amountCents: cents,
  currency: currency,
  type: type,
  categoryId: 'c1',
  sourceId: sourceId,
  transactedOn: '2026-05-13',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

void main() {
  group('applyDashboardFilter', () {
    final rows = [
      _tx(id: 'a', cents: 100, type: TransactionType.income, currency: 'CAD',
          sourceId: 's1'),
      _tx(id: 'b', cents: 200, type: TransactionType.expense, currency: 'USD',
          sourceId: 's2'),
      _tx(id: 'c', cents: 300, type: TransactionType.expense, currency: 'CAD',
          sourceId: 's2'),
    ];

    test('filter 全空 → 全部通过', () {
      final r = applyDashboardFilter(rows, const DashboardFilter());
      expect(r.length, 3);
    });

    test('按货币过滤', () {
      final r = applyDashboardFilter(
        rows,
        const DashboardFilter(currency: 'CAD'),
      );
      expect(r.map((t) => t.id), ['a', 'c']);
    });

    test('按来源过滤', () {
      final r = applyDashboardFilter(
        rows,
        const DashboardFilter(sourceId: 's2'),
      );
      expect(r.map((t) => t.id), ['b', 'c']);
    });

    test('货币 + 来源 同时过滤（交集）', () {
      final r = applyDashboardFilter(
        rows,
        const DashboardFilter(currency: 'CAD', sourceId: 's2'),
      );
      expect(r.map((t) => t.id), ['c']);
    });

    test('交集为空 → 空列表', () {
      final r = applyDashboardFilter(
        rows,
        const DashboardFilter(currency: 'EUR'),
      );
      expect(r, isEmpty);
    });
  });

  group('DashboardFilter.copyWith', () {
    test('保留未指定字段', () {
      const f = DashboardFilter(currency: 'CAD', sourceId: 's1');
      final n = f.copyWith(currency: 'USD');
      expect(n.currency, 'USD');
      expect(n.sourceId, 's1');
    });

    test('显式传 null 可清空', () {
      const f = DashboardFilter(currency: 'CAD', sourceId: 's1');
      final n = f.copyWith(currency: null);
      expect(n.currency, isNull);
      expect(n.sourceId, 's1');
    });
  });

  group('toMetrics', () {
    test('空 summary → dominantCurrency=null, isEmpty=true', () {
      final s = aggregateSummary(const <Transaction>[]);
      final m = toMetrics(s);
      expect(m.dominantCurrency, isNull);
      expect(m.isEmpty, isTrue);
      expect(m.otherCurrencyCount, 0);
    });

    test('单币种：dominant = 唯一币种，otherCount=0', () {
      final s = aggregateSummary([
        _tx(id: 'a', cents: 100, type: TransactionType.income),
        _tx(id: 'b', cents: 50, type: TransactionType.expense),
      ]);
      final m = toMetrics(s);
      expect(m.dominantCurrency, 'CAD');
      expect(m.incomeCents, 100);
      expect(m.expenseCents, 50);
      expect(m.netCents, 50);
      expect(m.otherCurrencyCount, 0);
      expect(m.transactionCount, 2);
    });

    test('多币种：dominant = 笔数最多的币种，otherCount=其它币种种类数', () {
      final s = aggregateSummary([
        // CAD: 1 笔；USD: 3 笔 → dominant = USD
        _tx(id: 'a', cents: 100, type: TransactionType.income, currency: 'CAD'),
        _tx(id: 'b', cents: 100, type: TransactionType.income, currency: 'USD'),
        _tx(id: 'c', cents: 100, type: TransactionType.expense, currency: 'USD'),
        _tx(id: 'd', cents: 100, type: TransactionType.expense, currency: 'USD'),
      ]);
      final m = toMetrics(s);
      expect(m.dominantCurrency, 'USD');
      expect(m.incomeCents, 100);
      expect(m.expenseCents, 200);
      expect(m.otherCurrencyCount, 1);
      expect(m.transactionCount, 4);
    });

    test('多币种平票：CAD 优先（落到 aggregateSummary 的默认排序）', () {
      final s = aggregateSummary([
        _tx(id: 'a', cents: 100, type: TransactionType.income, currency: 'USD'),
        _tx(id: 'b', cents: 100, type: TransactionType.income, currency: 'CAD'),
      ]);
      final m = toMetrics(s);
      expect(m.dominantCurrency, 'CAD'); // 平票时 CAD 优先
      expect(m.otherCurrencyCount, 1);
    });
  });
}
