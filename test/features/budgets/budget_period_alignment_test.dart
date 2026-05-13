import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/domain/enums/budget_period.dart';
import 'package:spend_harbor_app_local/features/budgets/application/budget_period_alignment.dart';

void main() {
  group('alignToPeriodStart', () {
    test('week → 当周周一', () {
      // 2026-05-13 是周三
      final d = DateTime(2026, 5, 13);
      expect(
        alignToPeriodStart(d, BudgetPeriod.week),
        DateTime(2026, 5, 11),
      );
    });
    test('week 边界：周一返回自己', () {
      final d = DateTime(2026, 5, 11);
      expect(
        alignToPeriodStart(d, BudgetPeriod.week),
        DateTime(2026, 5, 11),
      );
    });
    test('week 跨月：5/3 周日 → 4/27 周一', () {
      // 2026-05-03 是周日
      final d = DateTime(2026, 5, 3);
      expect(
        alignToPeriodStart(d, BudgetPeriod.week),
        DateTime(2026, 4, 27),
      );
    });
    test('month → 当月 1 日', () {
      final d = DateTime(2026, 5, 13);
      expect(
        alignToPeriodStart(d, BudgetPeriod.month),
        DateTime(2026, 5, 1),
      );
    });
    test('year → 当年 1/1', () {
      final d = DateTime(2026, 5, 13);
      expect(
        alignToPeriodStart(d, BudgetPeriod.year),
        DateTime(2026, 1, 1),
      );
    });
  });

  test('formatIsoDate', () {
    expect(formatIsoDate(DateTime(2026, 5, 3)), '2026-05-03');
    expect(formatIsoDate(DateTime(2026, 12, 31)), '2026-12-31');
  });
}
