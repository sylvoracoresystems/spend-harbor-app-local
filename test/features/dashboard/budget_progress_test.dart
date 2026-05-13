import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_period.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_scope.dart';
import 'package:spend_harbor_app_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_app_local/features/budgets/application/budget_period_alignment.dart';
import 'package:spend_harbor_app_local/features/dashboard/application/budget_progress_provider.dart';

Budget _budget({
  String id = 'b1',
  BudgetPeriod period = BudgetPeriod.month,
  BudgetScope scope = BudgetScope.total,
  String? categoryId,
  String currency = 'CAD',
  int amountCents = 50000,
}) =>
    Budget(
      id: id,
      period: period,
      scope: scope,
      categoryId: categoryId,
      amountCents: amountCents,
      currency: currency,
      startsOn: '2026-05-01',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

Transaction _tx({
  required String id,
  required int cents,
  TransactionType type = TransactionType.expense,
  String currency = 'CAD',
  String categoryId = 'cFood',
}) =>
    Transaction(
      id: id,
      amountCents: cents,
      currency: currency,
      type: type,
      categoryId: categoryId,
      sourceId: 's1',
      transactedOn: '2026-05-13',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  group('spentForBudget', () {
    test('scope=total：累加所有 expense（匹配币种）', () {
      final b = _budget(amountCents: 100000);
      final spent = spentForBudget(b, [
        _tx(id: 'a', cents: 3000),
        _tx(id: 'b', cents: 4000, currency: 'USD'), // 不同币种忽略
        _tx(id: 'c', cents: 2000, type: TransactionType.income), // 收入忽略
        _tx(id: 'd', cents: 1000),
      ]);
      expect(spent, 4000);
    });

    test('scope=category：仅累加同 categoryId', () {
      final b = _budget(
        scope: BudgetScope.category,
        categoryId: 'cFood',
        amountCents: 50000,
      );
      final spent = spentForBudget(b, [
        _tx(id: 'a', cents: 2000, categoryId: 'cFood'),
        _tx(id: 'b', cents: 9000, categoryId: 'cTransport'),
      ]);
      expect(spent, 2000);
    });
  });

  group('BudgetProgress', () {
    test('ratio + overBudget', () {
      final p = BudgetProgress(
        budget: _budget(amountCents: 10000),
        spentCents: 6000,
      );
      expect(p.ratio, 0.6);
      expect(p.overBudget, isFalse);

      final p2 = BudgetProgress(
        budget: _budget(amountCents: 10000),
        spentCents: 12000,
      );
      expect(p2.overBudget, isTrue);
      expect(p2.ratio, greaterThan(1));
    });
  });

  group('periodEndOn', () {
    test('week: 2026-05-13 (周三) → 周日 5/17', () {
      expect(
        periodEndOn(DateTime(2026, 5, 13), BudgetPeriod.week),
        DateTime(2026, 5, 17),
      );
    });
    test('month: 2026-05-13 → 5/31', () {
      expect(
        periodEndOn(DateTime(2026, 5, 13), BudgetPeriod.month),
        DateTime(2026, 5, 31),
      );
    });
    test('month: 2026-02-10 → 2/28（非闰年）', () {
      expect(
        periodEndOn(DateTime(2026, 2, 10), BudgetPeriod.month),
        DateTime(2026, 2, 28),
      );
    });
    test('year: 任意日期 → 12/31', () {
      expect(
        periodEndOn(DateTime(2026, 5, 13), BudgetPeriod.year),
        DateTime(2026, 12, 31),
      );
    });
  });
}
