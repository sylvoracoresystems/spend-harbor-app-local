import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/features/stats/application/stats_buckets.dart';
import 'package:spend_harbor_app_local/features/stats/application/stats_filter.dart';

void main() {
  group('alignToPeriodStart', () {
    test('week aligns to Monday', () {
      // 2026-03-15 is a Sunday → Monday is 2026-03-09
      expect(
        alignToPeriodStart(DateTime(2026, 3, 15), StatsPeriod.week),
        DateTime(2026, 3, 9),
      );
    });
    test('month aligns to 1st', () {
      expect(
        alignToPeriodStart(DateTime(2026, 3, 15), StatsPeriod.month),
        DateTime(2026, 3, 1),
      );
    });
    test('year aligns to Jan 1', () {
      expect(
        alignToPeriodStart(DateTime(2026, 3, 15), StatsPeriod.year),
        DateTime(2026, 1, 1),
      );
    });
  });

  group('generateBuckets', () {
    test('week: 6 buckets ending at anchor week (crosses month)', () {
      // 2026-03-31 is a Tuesday → its Monday is 2026-03-30
      final anchor = DateTime(2026, 3, 31);
      final buckets = generateBuckets(StatsPeriod.week, anchor);
      expect(buckets.length, 6);
      expect(buckets.last.start, DateTime(2026, 3, 30));
      expect(buckets.last.end, DateTime(2026, 4, 5));
      expect(buckets.first.start, DateTime(2026, 2, 23));
    });

    test('month: 6 buckets including anchor month', () {
      final buckets = generateBuckets(StatsPeriod.month, DateTime(2026, 5, 14));
      expect(buckets.length, 6);
      expect(buckets.last.start, DateTime(2026, 5, 1));
      expect(buckets.first.start, DateTime(2025, 12, 1));
    });

    test('year: 3 buckets', () {
      final buckets = generateBuckets(StatsPeriod.year, DateTime(2026, 5, 14));
      expect(buckets.length, 3);
      expect(buckets.last.start, DateTime(2026, 1, 1));
      expect(buckets.last.end, DateTime(2026, 12, 31));
      expect(buckets.first.start, DateTime(2024, 1, 1));
    });
  });

  group('isoDate', () {
    test('zero-pads month + day', () {
      expect(isoDate(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });
}
