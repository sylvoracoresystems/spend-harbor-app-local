import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/features/stats/application/stats_filter.dart';
import 'package:spend_harbor_app_local/features/stats/application/stats_filter_provider.dart';

void main() {
  test('initialFilter for today picks month period + month start', () {
    final f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14));
    expect(f.period, StatsPeriod.month);
    expect(f.selectedBucketStart, DateTime(2026, 5, 1));
    expect(f.rememberedMonthAnchor, DateTime(2026, 5, 1));
    expect(f.rememberedYearAnchor, DateTime(2026, 1, 1));
    expect(f.currency, 'CAD');
    expect(f.sourceId, isNull);
  });

  test('applySelectBucket in month mode updates rememberedMonthAnchor', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14));
    f = applySelectBucket(f, DateTime(2026, 2, 1));
    expect(f.selectedBucketStart, DateTime(2026, 2, 1));
    expect(f.rememberedMonthAnchor, DateTime(2026, 2, 1));
    expect(f.rememberedYearAnchor, DateTime(2026, 1, 1)); // unchanged
  });

  test('applySelectBucket in year mode updates rememberedYearAnchor', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(period: StatsPeriod.year, selectedBucketStart: DateTime(2026, 1, 1));
    f = applySelectBucket(f, DateTime(2024, 1, 1));
    expect(f.selectedBucketStart, DateTime(2024, 1, 1));
    expect(f.rememberedYearAnchor, DateTime(2024, 1, 1));
  });

  test('applySelectBucket in week mode does not touch month/year anchors', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(period: StatsPeriod.week, selectedBucketStart: DateTime(2026, 5, 11));
    f = applySelectBucket(f, DateTime(2026, 4, 6));
    expect(f.selectedBucketStart, DateTime(2026, 4, 6));
    expect(f.rememberedMonthAnchor, DateTime(2026, 5, 1));
    expect(f.rememberedYearAnchor, DateTime(2026, 1, 1));
  });

  test('applySetPeriod → week anchors at today\'s week regardless of memory', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(rememberedMonthAnchor: DateTime(2026, 2, 1));
    f = applySetPeriod(f, StatsPeriod.week, today: DateTime(2026, 5, 14));
    // 2026-05-14 是周四 → 当周一为 2026-05-11
    expect(f.period, StatsPeriod.week);
    expect(f.selectedBucketStart, DateTime(2026, 5, 11));
  });

  test('applySetPeriod → month uses today\'s month regardless of memory', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(rememberedYearAnchor: DateTime(2024, 1, 1));
    f = applySetPeriod(f, StatsPeriod.month, today: DateTime(2026, 5, 14));
    expect(f.period, StatsPeriod.month);
    expect(f.selectedBucketStart, DateTime(2026, 5, 1));
  });

  test('applySetPeriod week → year uses today year', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(period: StatsPeriod.week);
    f = applySetPeriod(f, StatsPeriod.year, today: DateTime(2026, 5, 14));
    expect(f.period, StatsPeriod.year);
    expect(f.selectedBucketStart, DateTime(2026, 1, 1));
  });

  test('applySetCurrency resets sourceId when source rejects new currency', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(sourceId: 's1');
    f = applySetCurrency(f, 'USD',
        sourceBelongsToCurrency: (id, ccy) => false);
    expect(f.currency, 'USD');
    expect(f.sourceId, isNull);
  });

  test('applySetCurrency keeps sourceId when source matches new currency', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(sourceId: 's1');
    f = applySetCurrency(f, 'USD',
        sourceBelongsToCurrency: (id, ccy) => true);
    expect(f.currency, 'USD');
    expect(f.sourceId, 's1');
  });

  test('applySetCurrency leaves null sourceId untouched', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14));
    f = applySetCurrency(f, 'USD',
        sourceBelongsToCurrency: (id, ccy) => fail('should not be called'));
    expect(f.currency, 'USD');
    expect(f.sourceId, isNull);
  });
}
