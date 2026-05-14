# Stats Page Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-month Stats page with a multi-granularity (Week/Month/Year) view with global Currency/Source filter, selectable trend buckets as the time anchor, dual Distribution cards (Category/Tag), and Top section (By Category / By Tag with multi-tag pills).

**Architecture:** New `application/` layer with `StatsFilter` + `StatsFilterController` driving bucket generation and derived `FutureProvider`s. Distribution and Top cards each carry local `useState<TxType>` for Expense/Income toggle. Click-through navigates to `/transactions` with new query params (`dateStart`/`dateEnd`/`tag`/`untagged`/`source`) backed by an extended `TransactionsFilter`.

**Tech Stack:** Flutter + Riverpod + drift + go_router + fl_chart (existing) + intl `DateFormat` for bucket labels.

**Spec:** [docs/superpowers/specs/2026-05-14-stats-page-overhaul-design.md](../specs/2026-05-14-stats-page-overhaul-design.md)

---

## Task list & files at a glance

| Task | Layer | Files |
|---|---|---|
| 1 | data | `lib/data/daos/transaction_dao.dart` + test |
| 2 | application | `lib/features/transactions/application/transactions_list_controller.dart` + test |
| 3 | router | `lib/shared/router/app_router.dart` + transactions page |
| 4 | application | `lib/features/stats/application/stats_filter.dart` |
| 5 | application | `lib/features/stats/application/stats_buckets.dart` + test |
| 6 | application | `lib/features/stats/application/stats_filter_provider.dart` + test |
| 7 | application | `lib/features/stats/application/stats_top_aggregator.dart` + test |
| 8 | application | `lib/features/stats/application/stats_controller.dart` (rewrite) |
| 9 | l10n | `lib/l10n/app_en.arb` + `app_zh.arb` |
| 10 | presentation shared | `lib/features/stats/presentation/widgets/tag_pill.dart` + `stats_donut.dart` |
| 11 | presentation | `lib/features/stats/presentation/widgets/stats_filter_bar.dart` |
| 12 | presentation | `lib/features/stats/presentation/widgets/stats_trend_card.dart` |
| 13 | presentation | `lib/features/stats/presentation/widgets/stats_distribution_card.dart` |
| 14 | presentation | `lib/features/stats/presentation/widgets/stats_top_card.dart` |
| 15 | presentation | `lib/features/stats/presentation/stats_page.dart` (rewrite) |
| 16 | docs | `docs/PROGRESS.md` + final verify |

Each task ends with a commit. Run `flutter analyze` after each task; `flutter test` after every task that adds tests.

---

## Task 1: DAO — `findByDateRange` (one-shot future)

**Files:**
- Modify: `lib/data/daos/transaction_dao.dart`
- Test: `test/data/daos/transaction_dao_test.dart` (append cases if exists; else create)

`watchBetween` already exists (returns `Stream`). Add a `Future` variant for Stats one-shot loads.

- [ ] **Step 1: Locate `watchBetween` (line ~25) and add `findByDateRange` next to it.**

Append after `watchBetween`:

```dart
/// 一次性按 [startIso] (含) ~ [endIso] (含) 取交易（未删除）。
Future<List<Transaction>> findByDateRange(String startIso, String endIso) {
  return (select(transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.transactedOn.isBiggerOrEqualValue(startIso) &
            t.transactedOn.isSmallerOrEqualValue(endIso))
        ..orderBy([
          (t) => OrderingTerm.desc(t.transactedOn),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .get();
}
```

- [ ] **Step 2: Write test in `test/data/daos/transaction_dao_test.dart`.**

If the file doesn't exist, scaffold using an existing DAO test as template (e.g. `test/data/daos/category_dao_test.dart`). Append a `group('findByDateRange', ...)` with:

```dart
test('returns rows within inclusive range, excludes soft-deleted', () async {
  await dao.insertTransaction(/* on 2026-03-01, expense, ... */);
  await dao.insertTransaction(/* on 2026-03-15, ... */);
  await dao.insertTransaction(/* on 2026-04-01, ... */);
  final id = await dao.insertTransaction(/* on 2026-03-05, ... */);
  await dao.softDelete(id);

  final rows = await dao.findByDateRange('2026-03-01', '2026-03-31');
  expect(rows.map((r) => r.transactedOn).toSet(),
      {'2026-03-15', '2026-03-01'});
});
```

- [ ] **Step 3: Run analyze + test.**

```
flutter analyze
flutter test test/data/daos/transaction_dao_test.dart
```

Expected: 0 issues + PASS.

- [ ] **Step 4: Commit.**

```
git add lib/data/daos/transaction_dao.dart test/data/daos/transaction_dao_test.dart
git commit -m "feat(data): findByDateRange one-shot query for stats"
```

---

## Task 2: Extend `TransactionsFilter` + `watchByDateRange` stream

**Files:**
- Modify: `lib/features/transactions/application/transactions_list_controller.dart`
- Modify: `lib/data/daos/transaction_dao.dart` (add stream variant)
- Test: `test/features/transactions/application/transactions_filter_test.dart` (existing)

- [ ] **Step 1: Add `watchByDateRange` to DAO.**

In `transaction_dao.dart` (alongside `watchBetween`):

```dart
Stream<List<Transaction>> watchByDateRange(String startIso, String endIso) {
  return (select(transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.transactedOn.isBiggerOrEqualValue(startIso) &
            t.transactedOn.isSmallerOrEqualValue(endIso))
        ..orderBy([
          (t) => OrderingTerm.desc(t.transactedOn),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch();
}
```

- [ ] **Step 2: Replace `TransactionsFilter` class body with extended version.**

In `transactions_list_controller.dart` lines ~65–77, replace the class:

```dart
class TransactionsFilter {
  const TransactionsFilter({
    this.dayIso,
    this.dateStartIso,
    this.dateEndIso,
    this.categoryId,
    this.tagId,
    this.untagged = false,
    this.sourceId,
  });
  final String? dayIso;
  final String? dateStartIso;
  final String? dateEndIso;
  final String? categoryId;
  final String? tagId;
  final bool untagged;
  final String? sourceId;

  bool get isEmpty =>
      dayIso == null &&
      dateStartIso == null &&
      dateEndIso == null &&
      categoryId == null &&
      tagId == null &&
      !untagged &&
      sourceId == null;

  bool get hasDateRange => dateStartIso != null && dateEndIso != null;

  bool matches(Transaction t, {Set<String>? tagIds}) {
    if (dayIso != null && t.transactedOn != dayIso) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (sourceId != null && t.sourceId != sourceId) return false;
    if (tagId != null && (tagIds == null || !tagIds.contains(tagId))) return false;
    if (untagged && (tagIds != null && tagIds.isNotEmpty)) return false;
    return true;
  }
}
```

Note: `matches` now optionally takes `tagIds` (for the row's tags). Date range is enforced at the query layer, not in `matches`.

- [ ] **Step 3: Adjust transactions list query to use date range when set.**

Replace `transactionsOfMonthProvider` and `filteredTransactionsProvider` to honour date range when filter has one:

```dart
final transactionsOfMonthProvider = StreamProvider<List<Transaction>>((ref) {
  final filter = ref.watch(transactionsFilterProvider);
  final dao = ref.watch(transactionDaoProvider);
  if (filter != null && filter.hasDateRange) {
    return dao.watchByDateRange(filter.dateStartIso!, filter.dateEndIso!);
  }
  final ym = ref.watch(currentMonthProvider);
  return dao.watchByMonth(ym.key);
});
```

And remove the auto-clear-on-month-change behaviour for date-range mode (still clear single-day/category, etc., when crossing months). Replace `_monthChangeListenerProvider`:

```dart
final _monthChangeListenerProvider = Provider<void>((ref) {
  ref.listen(currentMonthProvider, (_, __) {
    final cur = ref.read(transactionsFilterProvider);
    if (cur != null && cur.hasDateRange) return; // keep range mode
    ref.read(transactionsFilterProvider.notifier).state = null;
  });
});
```

Also update `filteredTransactionsProvider` to pre-fetch tag ids when filter has `tagId`/`untagged`:

```dart
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  ref.watch(_monthChangeListenerProvider);
  final filter = ref.watch(transactionsFilterProvider);
  final txAsync = ref.watch(transactionsOfMonthProvider);
  if (filter == null || filter.isEmpty) return txAsync;
  // tag-aware filtering needs the tagIds map; load it via separate provider.
  final tagsAsync = ref.watch(_tagsForCurrentListProvider);
  return txAsync.whenData((rows) {
    final tagsByTx = tagsAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <String, List<String>>{},
    );
    return rows
        .where((t) => filter.matches(t, tagIds: tagsByTx[t.id]?.toSet()))
        .toList();
  });
});

final _tagsForCurrentListProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  final rows = await ref.watch(transactionsOfMonthProvider.future);
  if (rows.isEmpty) return const {};
  return ref.watch(transactionDaoProvider).tagIdsForMany(rows.map((r) => r.id).toList());
});
```

- [ ] **Step 4: Write/extend filter tests.**

Append to `test/features/transactions/application/transactions_filter_test.dart`:

```dart
group('TransactionsFilter extensions', () {
  Transaction tx({
    String id = 't',
    String date = '2026-03-15',
    String catId = 'c1',
    String srcId = 's1',
  }) =>
      /* construct using existing test factory */;

  test('sourceId narrows match', () {
    expect(
      TransactionsFilter(sourceId: 's1').matches(tx(srcId: 's1')),
      isTrue,
    );
    expect(
      TransactionsFilter(sourceId: 's2').matches(tx(srcId: 's1')),
      isFalse,
    );
  });

  test('tagId requires tagIds to contain it', () {
    expect(
      TransactionsFilter(tagId: 'a').matches(tx(), tagIds: {'a', 'b'}),
      isTrue,
    );
    expect(
      TransactionsFilter(tagId: 'a').matches(tx(), tagIds: const {}),
      isFalse,
    );
  });

  test('untagged matches rows with no tags only', () {
    expect(
      TransactionsFilter(untagged: true).matches(tx(), tagIds: const {}),
      isTrue,
    );
    expect(
      TransactionsFilter(untagged: true).matches(tx(), tagIds: {'a'}),
      isFalse,
    );
  });

  test('isEmpty true only when every field is null/false', () {
    expect(const TransactionsFilter().isEmpty, isTrue);
    expect(const TransactionsFilter(untagged: true).isEmpty, isFalse);
  });
});
```

- [ ] **Step 5: Run analyze + tests.**

```
flutter analyze
flutter test
```

Expected: 0 issues + all green.

- [ ] **Step 6: Commit.**

```
git add lib/features/transactions/application/transactions_list_controller.dart lib/data/daos/transaction_dao.dart test/features/transactions/application/transactions_filter_test.dart
git commit -m "feat(transactions): extend filter with dateRange/tag/untagged/source"
```

---

## Task 3: Router — parse new query params on `/transactions`

**Files:**
- Modify: `lib/shared/router/app_router.dart`

Stats deep-links use query params; the page already exists at `/transactions`. Wrap navigation so query params populate `transactionsFilterProvider` + `currentMonthProvider` before render.

- [ ] **Step 1: Locate the `/transactions` route definition.**

Find the `GoRoute(path: '/transactions', ...)`. Add a `redirect` or wrap the `builder` so it parses `state.uri.queryParameters`.

- [ ] **Step 2: Implement param parsing in the route's `builder`.**

Replace the `/transactions` route `builder` with a small `_TransactionsRouteEntry` widget that runs the param-to-state mapping in `initState`:

```dart
class _TransactionsRouteEntry extends ConsumerStatefulWidget {
  const _TransactionsRouteEntry(this.qp);
  final Map<String, String> qp;
  @override
  ConsumerState<_TransactionsRouteEntry> createState() => _TransactionsRouteEntryState();
}

class _TransactionsRouteEntryState extends ConsumerState<_TransactionsRouteEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  void _apply() {
    final qp = widget.qp;
    final filter = TransactionsFilter(
      dayIso: qp['day'],
      dateStartIso: qp['dateStart'],
      dateEndIso: qp['dateEnd'],
      categoryId: qp['category'],
      tagId: qp['tag'],
      untagged: qp['untagged'] == '1',
      sourceId: qp['source'],
    );
    ref.read(transactionsFilterProvider.notifier).state =
        filter.isEmpty ? null : filter;
    final m = qp['month'];
    if (m != null) {
      ref.read(currentMonthProvider.notifier).set(YearMonth.parse(m));
    } else if (filter.hasDateRange) {
      // Anchor month to the start of the range so the month switcher reads sensibly.
      final dt = DateTime.parse(filter.dateStartIso!);
      ref.read(currentMonthProvider.notifier).set(YearMonth(dt.year, dt.month));
    }
  }

  @override
  Widget build(BuildContext context) => const TransactionsPage();
}
```

And hook it up:

```dart
GoRoute(
  path: '/transactions',
  builder: (_, state) =>
      _TransactionsRouteEntry(state.uri.queryParameters),
),
```

- [ ] **Step 3: Run analyze.**

```
flutter analyze
```

Expected: 0 issues. (No new tests for the route — covered by Task 15 manual QA.)

- [ ] **Step 4: Commit.**

```
git add lib/shared/router/app_router.dart
git commit -m "feat(router): parse transactions filter query params"
```

---

## Task 4: `StatsFilter` value object + `StatsPeriod` enum

**Files:**
- Create: `lib/features/stats/application/stats_filter.dart`

- [ ] **Step 1: Create the file with full content.**

```dart
import 'package:meta/meta.dart';

enum StatsPeriod { week, month, year }

@immutable
class StatsFilter {
  const StatsFilter({
    required this.currency,
    this.sourceId,
    required this.period,
    required this.selectedBucketStart,
    required this.rememberedMonthAnchor,
    required this.rememberedYearAnchor,
  });

  final String currency;
  final String? sourceId;
  final StatsPeriod period;

  /// 选中桶的起点（对齐到 period：周一 / 月一 / 1月1日）。
  final DateTime selectedBucketStart;

  /// 用户在 month 模式最近选中的月（默认当月）。
  final DateTime rememberedMonthAnchor;

  /// 用户在 year 模式最近选中的年（默认当年）。
  final DateTime rememberedYearAnchor;

  StatsFilter copyWith({
    String? currency,
    Object? sourceId = _unset,
    StatsPeriod? period,
    DateTime? selectedBucketStart,
    DateTime? rememberedMonthAnchor,
    DateTime? rememberedYearAnchor,
  }) {
    return StatsFilter(
      currency: currency ?? this.currency,
      sourceId: identical(sourceId, _unset) ? this.sourceId : sourceId as String?,
      period: period ?? this.period,
      selectedBucketStart: selectedBucketStart ?? this.selectedBucketStart,
      rememberedMonthAnchor:
          rememberedMonthAnchor ?? this.rememberedMonthAnchor,
      rememberedYearAnchor:
          rememberedYearAnchor ?? this.rememberedYearAnchor,
    );
  }
}

const _unset = Object();
```

- [ ] **Step 2: Run analyze.**

```
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 3: Commit.**

```
git add lib/features/stats/application/stats_filter.dart
git commit -m "feat(stats): StatsFilter value object + StatsPeriod enum"
```

---

## Task 5: `stats_buckets` pure functions + tests

**Files:**
- Create: `lib/features/stats/application/stats_buckets.dart`
- Create: `test/features/stats/application/stats_buckets_test.dart`

- [ ] **Step 1: Write the test file first (TDD).**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_local/features/stats/application/stats_buckets.dart';
import 'package:spend_harbor_local/features/stats/application/stats_filter.dart';

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
      final anchor = DateTime(2026, 3, 31); // Tuesday → Monday 2026-03-30
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
```

- [ ] **Step 2: Run test, confirm failure.**

```
flutter test test/features/stats/application/stats_buckets_test.dart
```

Expected: FAIL (file not found / functions missing).

- [ ] **Step 3: Implement `stats_buckets.dart`.**

```dart
import 'stats_filter.dart';

class TrendBucket {
  const TrendBucket({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

DateTime alignToPeriodStart(DateTime d, StatsPeriod p) {
  switch (p) {
    case StatsPeriod.week:
      final dow = d.weekday; // Mon=1..Sun=7
      return DateTime(d.year, d.month, d.day - (dow - 1));
    case StatsPeriod.month:
      return DateTime(d.year, d.month, 1);
    case StatsPeriod.year:
      return DateTime(d.year, 1, 1);
  }
}

int _bucketCount(StatsPeriod p) =>
    p == StatsPeriod.year ? 3 : 6;

DateTime _addPeriod(DateTime start, StatsPeriod p, int n) {
  switch (p) {
    case StatsPeriod.week:
      return DateTime(start.year, start.month, start.day + n * 7);
    case StatsPeriod.month:
      return DateTime(start.year, start.month + n, 1);
    case StatsPeriod.year:
      return DateTime(start.year + n, 1, 1);
  }
}

DateTime _endOfBucket(DateTime start, StatsPeriod p) {
  switch (p) {
    case StatsPeriod.week:
      return DateTime(start.year, start.month, start.day + 6);
    case StatsPeriod.month:
      final next = DateTime(start.year, start.month + 1, 1);
      return next.subtract(const Duration(days: 1));
    case StatsPeriod.year:
      return DateTime(start.year, 12, 31);
  }
}

List<TrendBucket> generateBuckets(StatsPeriod p, DateTime anchor) {
  final rightStart = alignToPeriodStart(anchor, p);
  final count = _bucketCount(p);
  final out = <TrendBucket>[];
  for (var i = count - 1; i >= 0; i--) {
    final start = _addPeriod(rightStart, p, -i);
    out.add(TrendBucket(start: start, end: _endOfBucket(start, p)));
  }
  return out;
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
```

- [ ] **Step 4: Re-run tests.**

```
flutter test test/features/stats/application/stats_buckets_test.dart
flutter analyze
```

Expected: PASS + 0 issues.

- [ ] **Step 5: Commit.**

```
git add lib/features/stats/application/stats_buckets.dart test/features/stats/application/stats_buckets_test.dart
git commit -m "feat(stats): bucket generator + alignment pure functions"
```

---

## Task 6: `StatsFilterController` + provider + tests

**Files:**
- Create: `lib/features/stats/application/stats_filter_provider.dart`
- Create: `test/features/stats/application/stats_filter_provider_test.dart`

- [ ] **Step 1: Write the test file.**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_local/features/stats/application/stats_filter.dart';
import 'package:spend_harbor_local/features/stats/application/stats_filter_provider.dart';

void main() {
  test('initialBucketFor month uses month start of today', () {
    final f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14));
    expect(f.period, StatsPeriod.month);
    expect(f.selectedBucketStart, DateTime(2026, 5, 1));
  });

  test('selectBucket in month mode updates rememberedMonthAnchor', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14));
    f = applySelectBucket(f, DateTime(2026, 2, 1));
    expect(f.rememberedMonthAnchor, DateTime(2026, 2, 1));
  });

  test('setPeriod month → week anchors on remembered month last week', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(rememberedMonthAnchor: DateTime(2026, 2, 1));
    f = applySetPeriod(f, StatsPeriod.week, today: DateTime(2026, 5, 14));
    // 2026-02-28 is a Saturday → Monday of that week is 2026-02-23
    expect(f.selectedBucketStart, DateTime(2026, 2, 23));
  });

  test('setPeriod year → month uses remembered year December', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(rememberedYearAnchor: DateTime(2024, 1, 1));
    f = applySetPeriod(f, StatsPeriod.month, today: DateTime(2026, 5, 14));
    expect(f.selectedBucketStart, DateTime(2024, 12, 1));
  });

  test('setCurrency resets sourceId when sources reject the new currency', () {
    var f = initialFilter(currency: 'CAD', today: DateTime(2026, 5, 14))
        .copyWith(sourceId: 's1');
    f = applySetCurrency(f, 'USD', sourceBelongsToCurrency: (id, ccy) => false);
    expect(f.sourceId, isNull);
    f = applySetCurrency(f.copyWith(sourceId: 's1'), 'USD',
        sourceBelongsToCurrency: (id, ccy) => true);
    expect(f.sourceId, 's1');
  });
}
```

- [ ] **Step 2: Run test, confirm fail.**

```
flutter test test/features/stats/application/stats_filter_provider_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement provider + pure functions in `stats_filter_provider.dart`.**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database_provider.dart';
import '../../../shared/providers/preferences_provider.dart';
import '../../settings/application/default_currency_provider.dart';
import 'stats_buckets.dart';
import 'stats_filter.dart';

const _kPrefsCurrencyKey = 'stats.lastCurrency';

StatsFilter initialFilter({
  required String currency,
  required DateTime today,
}) {
  final monthStart = alignToPeriodStart(today, StatsPeriod.month);
  return StatsFilter(
    currency: currency,
    period: StatsPeriod.month,
    selectedBucketStart: monthStart,
    rememberedMonthAnchor: monthStart,
    rememberedYearAnchor: alignToPeriodStart(today, StatsPeriod.year),
  );
}

StatsFilter applySelectBucket(StatsFilter f, DateTime start) {
  switch (f.period) {
    case StatsPeriod.month:
      return f.copyWith(
        selectedBucketStart: start,
        rememberedMonthAnchor: start,
      );
    case StatsPeriod.year:
      return f.copyWith(
        selectedBucketStart: start,
        rememberedYearAnchor: start,
      );
    case StatsPeriod.week:
      return f.copyWith(selectedBucketStart: start);
  }
}

StatsFilter applySetPeriod(
  StatsFilter f,
  StatsPeriod p, {
  required DateTime today,
}) {
  final DateTime anchor;
  switch (p) {
    case StatsPeriod.week:
      // 用记忆月份的月末日所在周
      final mo = f.rememberedMonthAnchor;
      final monthEnd = DateTime(mo.year, mo.month + 1, 0);
      anchor = alignToPeriodStart(monthEnd, StatsPeriod.week);
      break;
    case StatsPeriod.month:
      // 用记忆年份的 12 月
      final yr = f.rememberedYearAnchor;
      anchor = DateTime(yr.year, 12, 1);
      break;
    case StatsPeriod.year:
      anchor = alignToPeriodStart(today, StatsPeriod.year);
      break;
  }
  return f.copyWith(period: p, selectedBucketStart: anchor);
}

StatsFilter applySetCurrency(
  StatsFilter f,
  String currency, {
  required bool Function(String sourceId, String currency) sourceBelongsToCurrency,
}) {
  final sid = f.sourceId;
  final keep = sid != null && sourceBelongsToCurrency(sid, currency);
  return f.copyWith(
    currency: currency,
    sourceId: keep ? sid : null,
  );
}

class StatsFilterController extends StateNotifier<StatsFilter> {
  StatsFilterController(this._ref, StatsFilter seed) : super(seed);

  final Ref _ref;

  Future<void> setPeriod(StatsPeriod p) async {
    state = applySetPeriod(state, p, today: DateTime.now());
  }

  void selectBucket(DateTime start) {
    state = applySelectBucket(state, start);
  }

  Future<void> setCurrency(String c) async {
    state = applySetCurrency(
      state,
      c,
      sourceBelongsToCurrency: (id, ccy) {
        final src = _ref
            .read(allSourcesProvider)
            .valueOrNull
            ?.firstWhere((s) => s.id == id, orElse: () => null as dynamic);
        return src != null && src.currency == ccy;
      },
    );
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kPrefsCurrencyKey, c);
  }

  void setSourceId(String? id) {
    state = state.copyWith(sourceId: id);
  }
}

/// 异步初始化：读取 prefs / 计算 dominant currency / fallback default。
final statsFilterProvider =
    StateNotifierProvider<StatsFilterController, StatsFilter>((ref) {
  final defaultCcy = ref.read(defaultCurrencyProvider);
  final seed = initialFilter(currency: defaultCcy, today: DateTime.now());
  final ctrl = StatsFilterController(ref, seed);
  // 异步在 ProviderScope 启动后解析真正的 currency
  Future.microtask(() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final saved = prefs.getString(_kPrefsCurrencyKey);
    if (saved != null) {
      ctrl.state = ctrl.state.copyWith(currency: saved);
      return;
    }
    final dao = ref.read(transactionDaoProvider);
    final monthStart = ctrl.state.selectedBucketStart;
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final rows = await dao.findByDateRange(isoDate(monthStart), isoDate(monthEnd));
    if (rows.isEmpty) return;
    final counts = <String, int>{};
    for (final r in rows) {
      counts[r.currency] = (counts[r.currency] ?? 0) + 1;
    }
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    ctrl.state = ctrl.state.copyWith(currency: top.first.key);
  });
  return ctrl;
});
```

> Note: the test stubs `applySetCurrency` directly to avoid touching providers. If `allSourcesProvider` doesn't exist with that name, check `lib/features/sources/application/` for the correct provider name and adjust the import.

- [ ] **Step 4: Re-run.**

```
flutter test test/features/stats/application/stats_filter_provider_test.dart
flutter analyze
```

Expected: PASS + 0 issues.

- [ ] **Step 5: Commit.**

```
git add lib/features/stats/application/stats_filter_provider.dart test/features/stats/application/stats_filter_provider_test.dart
git commit -m "feat(stats): StatsFilterController with prefs+dominant-currency init"
```

---

## Task 7: `stats_top_aggregator` pure functions + tests

**Files:**
- Create: `lib/features/stats/application/stats_top_aggregator.dart`
- Create: `test/features/stats/application/stats_top_aggregator_test.dart`

- [ ] **Step 1: Test file (full cases).**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_local/data/database/app_database.dart';
import 'package:spend_harbor_local/domain/enums/transaction_type.dart';
import 'package:spend_harbor_local/features/stats/application/stats_top_aggregator.dart';

Transaction _t({
  required String id,
  required String catId,
  required int cents,
  String currency = 'CAD',
  String srcId = 's1',
  String date = '2026-03-15',
  TransactionType type = TransactionType.expense,
}) =>
    Transaction(/* id, type, amountCents: cents, currency, categoryId: catId,
                  sourceId: srcId, transactedOn: date, createdAt: 0,
                  updatedAt: 0, deletedAt: null, note: null */);

void main() {
  group('aggregateTopByCategory', () {
    test('sorts by amount desc, caps at 10, counts entries', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 500),
        _t(id: '2', catId: 'A', cents: 300),
        _t(id: '3', catId: 'B', cents: 1000),
      ];
      final tags = {'1': ['t1'], '2': ['t1','t2'], '3': ['t2']};
      final rows10 = aggregateTopByCategory(
        rows,
        type: TransactionType.expense,
        currency: 'CAD',
        tagsByTx: tags,
        limit: 10,
      );
      expect(rows10.map((r) => r.categoryId), ['B', 'A']);
      expect(rows10.first.totalCents, 1000);
      expect(rows10.first.count, 1);
      expect(rows10[1].count, 2);
      expect(rows10[1].tagFrequencies.keys, containsAll(['t1', 't2']));
      expect(rows10[1].tagFrequencies['t1'], 2);
      expect(rows10[1].tagFrequencies['t2'], 1);
    });

    test('filters by type and currency', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 100, currency: 'USD'),
        _t(id: '2', catId: 'A', cents: 200, currency: 'CAD',
            type: TransactionType.income),
        _t(id: '3', catId: 'A', cents: 300, currency: 'CAD'),
      ];
      final out = aggregateTopByCategory(rows,
          type: TransactionType.expense, currency: 'CAD',
          tagsByTx: const {}, limit: 10);
      expect(out.length, 1);
      expect(out.first.totalCents, 300);
    });
  });

  group('aggregateTopByTag', () {
    test('groups by tag, includes Top 3 categories with amounts, untagged separated', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 100),
        _t(id: '2', catId: 'A', cents: 200),
        _t(id: '3', catId: 'B', cents: 300),
        _t(id: '4', catId: 'C', cents: 400),
      ];
      final tags = {'1': ['x'], '2': ['x'], '3': ['x'], '4': const <String>[]};
      final result = aggregateTopByTag(rows,
          type: TransactionType.expense, currency: 'CAD',
          tagsByTx: tags, limit: 10);
      expect(result.rows.length, 1);
      expect(result.rows.first.tagId, 'x');
      expect(result.rows.first.totalCents, 600);
      expect(result.rows.first.count, 3);
      expect(result.rows.first.topCategories.first.categoryId, 'B');
      expect(result.untagged?.totalCents, 400);
      expect(result.untagged?.count, 1);
    });

    test('untagged is null when every row has tags', () {
      final rows = [_t(id: '1', catId: 'A', cents: 100)];
      final tags = {'1': ['x']};
      final r = aggregateTopByTag(rows,
          type: TransactionType.expense, currency: 'CAD',
          tagsByTx: tags, limit: 10);
      expect(r.untagged, isNull);
    });

    test('multi-tag rows accumulate fully in each tag', () {
      final rows = [
        _t(id: '1', catId: 'A', cents: 100),
      ];
      final tags = {'1': ['a', 'b']};
      final r = aggregateTopByTag(rows,
          type: TransactionType.expense, currency: 'CAD',
          tagsByTx: tags, limit: 10);
      expect(r.rows.length, 2);
      expect(r.rows.first.totalCents, 100);
      expect(r.rows[1].totalCents, 100);
    });
  });
}
```

> The `Transaction` constructor takes all the drift columns; replicate the field list from a working test (e.g. `transaction_dao_test.dart` if present, otherwise from drift's generated source). The exact constructor call may be `Transaction(...)` with positional/named params — check `lib/data/database/app_database.g.dart`.

- [ ] **Step 2: Run test, confirm fail.**

```
flutter test test/features/stats/application/stats_top_aggregator_test.dart
```

- [ ] **Step 3: Implement aggregator.**

```dart
import '../../../data/database/app_database.dart';
import '../../../domain/enums/transaction_type.dart';

class TopCategoryRow {
  TopCategoryRow({
    required this.categoryId,
    required this.totalCents,
    required this.count,
    required this.tagFrequencies,
  });
  final String categoryId;
  final int totalCents;
  final int count;
  final Map<String, int> tagFrequencies; // tagId -> occurrence count
}

class TopTagCategory {
  const TopTagCategory({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

class TopTagRow {
  TopTagRow({
    required this.tagId,
    required this.totalCents,
    required this.count,
    required this.topCategories,
  });
  final String tagId;
  final int totalCents;
  final int count;
  final List<TopTagCategory> topCategories; // up to 3, desc by amount
}

class UntaggedRow {
  const UntaggedRow({required this.totalCents, required this.count});
  final int totalCents;
  final int count;
}

class TopTagAggregate {
  const TopTagAggregate({required this.rows, required this.untagged});
  final List<TopTagRow> rows;
  final UntaggedRow? untagged;
}

bool _accept(Transaction t, TransactionType type, String currency, String? sourceId) {
  if (t.type != type) return false;
  if (t.currency != currency) return false;
  if (sourceId != null && t.sourceId != sourceId) return false;
  return true;
}

List<TopCategoryRow> aggregateTopByCategory(
  List<Transaction> rows, {
  required TransactionType type,
  required String currency,
  String? sourceId,
  required Map<String, List<String>> tagsByTx,
  required int limit,
}) {
  final totals = <String, int>{};
  final counts = <String, int>{};
  final tagFreq = <String, Map<String, int>>{};
  for (final t in rows) {
    if (!_accept(t, type, currency, sourceId)) continue;
    totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amountCents;
    counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
    final freq = tagFreq.putIfAbsent(t.categoryId, () => <String, int>{});
    for (final tag in tagsByTx[t.id] ?? const <String>[]) {
      freq[tag] = (freq[tag] ?? 0) + 1;
    }
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries.take(limit))
      TopCategoryRow(
        categoryId: e.key,
        totalCents: e.value,
        count: counts[e.key]!,
        tagFrequencies: tagFreq[e.key] ?? const {},
      ),
  ];
}

TopTagAggregate aggregateTopByTag(
  List<Transaction> rows, {
  required TransactionType type,
  required String currency,
  String? sourceId,
  required Map<String, List<String>> tagsByTx,
  required int limit,
}) {
  final totals = <String, int>{};
  final counts = <String, int>{};
  final catTotals = <String, Map<String, int>>{};
  int untaggedTotal = 0;
  int untaggedCount = 0;
  for (final t in rows) {
    if (!_accept(t, type, currency, sourceId)) continue;
    final tags = tagsByTx[t.id] ?? const <String>[];
    if (tags.isEmpty) {
      untaggedTotal += t.amountCents;
      untaggedCount += 1;
      continue;
    }
    for (final tag in tags) {
      totals[tag] = (totals[tag] ?? 0) + t.amountCents;
      counts[tag] = (counts[tag] ?? 0) + 1;
      final inner = catTotals.putIfAbsent(tag, () => <String, int>{});
      inner[t.categoryId] = (inner[t.categoryId] ?? 0) + t.amountCents;
    }
  }
  final tagEntries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final outRows = [
    for (final e in tagEntries.take(limit))
      TopTagRow(
        tagId: e.key,
        totalCents: e.value,
        count: counts[e.key]!,
        topCategories: (() {
          final inner = catTotals[e.key]!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return [
            for (final c in inner.take(3))
              TopTagCategory(categoryId: c.key, totalCents: c.value),
          ];
        })(),
      ),
  ];
  return TopTagAggregate(
    rows: outRows,
    untagged: untaggedCount > 0
        ? UntaggedRow(totalCents: untaggedTotal, count: untaggedCount)
        : null,
  );
}
```

- [ ] **Step 4: Re-run.**

```
flutter test test/features/stats/application/stats_top_aggregator_test.dart
flutter analyze
```

- [ ] **Step 5: Commit.**

```
git add lib/features/stats/application/stats_top_aggregator.dart test/features/stats/application/stats_top_aggregator_test.dart
git commit -m "feat(stats): top aggregator (by category + by tag + untagged)"
```

---

## Task 8: New `stats_controller.dart` (rewrite)

**Files:**
- Modify: `lib/features/stats/application/stats_controller.dart` (full rewrite)

The old controller is tied to `currentMonthProvider`. Rewrite around `statsFilterProvider`. Keep no backwards compatibility — old providers (`dailyExpenseBarsProvider`, `categorySlicesProvider`, etc.) are removed; the only consumer (old stats_page) will be replaced in Task 15.

- [ ] **Step 1: Replace file content.**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/transaction_type.dart';
import 'stats_buckets.dart';
import 'stats_filter.dart';
import 'stats_filter_provider.dart';
import 'stats_top_aggregator.dart';

/// 单桶在某币种下的双值（income / expense cents）。
class TrendBucketValues {
  const TrendBucketValues({
    required this.bucket,
    required this.incomeCents,
    required this.expenseCents,
  });
  final TrendBucket bucket;
  final int incomeCents;
  final int expenseCents;
}

/// Trend 数据：6/3 桶。
final trendBucketsProvider =
    FutureProvider<List<TrendBucketValues>>((ref) async {
  final f = ref.watch(statsFilterProvider);
  final buckets = generateBuckets(
    f.period,
    f.period == StatsPeriod.week
        ? f.rememberedMonthAnchor
        : (f.period == StatsPeriod.year
            ? DateTime.now()
            : DateTime.now()),
  );
  // Re-anchor: when in week mode, anchor on remembered month end so the
  // selected bucket lies within the visible window.
  final dao = ref.watch(transactionDaoProvider);
  final start = buckets.first.start;
  final end = buckets.last.end;
  final rows = await dao.findByDateRange(isoDate(start), isoDate(end));

  final out = <TrendBucketValues>[];
  for (final b in buckets) {
    int inc = 0, exp = 0;
    for (final r in rows) {
      if (r.currency != f.currency) continue;
      if (f.sourceId != null && r.sourceId != f.sourceId) continue;
      final d = DateTime.parse(r.transactedOn);
      if (d.isBefore(b.start) || d.isAfter(b.end)) continue;
      if (r.type == TransactionType.expense) {
        exp += r.amountCents;
      } else {
        inc += r.amountCents;
      }
    }
    out.add(TrendBucketValues(bucket: b, incomeCents: inc, expenseCents: exp));
  }
  return out;
});

/// 选中桶范围内 + currency/source 过滤后的原始 rows（给 Distribution / Top 复用）。
final bucketTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final f = ref.watch(statsFilterProvider);
  final start = f.selectedBucketStart;
  final DateTime end;
  switch (f.period) {
    case StatsPeriod.week:
      end = DateTime(start.year, start.month, start.day + 6);
      break;
    case StatsPeriod.month:
      end = DateTime(start.year, start.month + 1, 0);
      break;
    case StatsPeriod.year:
      end = DateTime(start.year, 12, 31);
      break;
  }
  final dao = ref.watch(transactionDaoProvider);
  final all = await dao.findByDateRange(isoDate(start), isoDate(end));
  return [
    for (final r in all)
      if (r.currency == f.currency &&
          (f.sourceId == null || r.sourceId == f.sourceId))
        r,
  ];
});

/// 选中桶内的 tagIdsByTx（一次查询，给 Tag Distribution + Top 复用）。
final bucketTagsByTxProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  if (rows.isEmpty) return const {};
  return ref.watch(transactionDaoProvider).tagIdsForMany(rows.map((r) => r.id).toList());
});

class CategorySlice {
  const CategorySlice({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

class TagSlice {
  const TagSlice({required this.tagId, required this.totalCents});
  final String tagId;
  final int totalCents;
}

class CategoryDistribution {
  const CategoryDistribution({required this.slices, required this.totalCents});
  final List<CategorySlice> slices;
  final int totalCents;
}

class TagDistribution {
  const TagDistribution({
    required this.slices,
    required this.totalCents,
    required this.untaggedCents,
  });
  final List<TagSlice> slices;
  final int totalCents;
  final int untaggedCents;
}

final categoryDistributionProvider =
    FutureProvider.family<CategoryDistribution, TransactionType>((ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final totals = <String, int>{};
  int sum = 0;
  for (final r in rows) {
    if (r.type != type) continue;
    totals[r.categoryId] = (totals[r.categoryId] ?? 0) + r.amountCents;
    sum += r.amountCents;
  }
  final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return CategoryDistribution(
    slices: [
      for (final e in entries)
        CategorySlice(categoryId: e.key, totalCents: e.value),
    ],
    totalCents: sum,
  );
});

final tagDistributionProvider =
    FutureProvider.family<TagDistribution, TransactionType>((ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final tagsByTx = await ref.watch(bucketTagsByTxProvider.future);
  final totals = <String, int>{};
  int sum = 0;
  int untagged = 0;
  for (final r in rows) {
    if (r.type != type) continue;
    sum += r.amountCents;
    final tags = tagsByTx[r.id] ?? const <String>[];
    if (tags.isEmpty) {
      untagged += r.amountCents;
      continue;
    }
    for (final tag in tags) {
      totals[tag] = (totals[tag] ?? 0) + r.amountCents;
    }
  }
  final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return TagDistribution(
    slices: [
      for (final e in entries) TagSlice(tagId: e.key, totalCents: e.value),
    ],
    totalCents: sum,
    untaggedCents: untagged,
  );
});

final topByCategoryProvider =
    FutureProvider.family<List<TopCategoryRow>, TransactionType>((ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final tags = await ref.watch(bucketTagsByTxProvider.future);
  final f = ref.read(statsFilterProvider);
  return aggregateTopByCategory(
    rows,
    type: type,
    currency: f.currency,
    sourceId: f.sourceId,
    tagsByTx: tags,
    limit: 10,
  );
});

final topByTagProvider =
    FutureProvider.family<TopTagAggregate, TransactionType>((ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final tags = await ref.watch(bucketTagsByTxProvider.future);
  final f = ref.read(statsFilterProvider);
  return aggregateTopByTag(
    rows,
    type: type,
    currency: f.currency,
    sourceId: f.sourceId,
    tagsByTx: tags,
    limit: 10,
  );
});
```

- [ ] **Step 2: Drop old tests referring to deleted providers.**

Delete or skip any tests that depend on `dailyExpenseBarsProvider` / `categorySlicesProvider` / `tagSlicesProvider` / `categoryCountsProvider` / `aggregateDailyExpenses` / `dominantCurrency`. Coverage is now via Tasks 5/6/7.

```
git rm test/features/stats/application/stats_controller_test.dart  # if it exists; otherwise edit out tests
```

- [ ] **Step 3: Run analyze + tests.**

```
flutter analyze
flutter test
```

`analyze` should be clean. `test` should be all-green; the old `stats_page.dart` will fail to compile because its providers are gone — that's expected; Task 15 fixes it. Until then, gate analyze by temporarily renaming `stats_page.dart` to `stats_page.dart.bak` so the rest of the app compiles. **Skip this step instead and combine analyze/run with Task 15.**

- [ ] **Step 4: Commit (compile may not pass yet; commit anyway as a checkpoint).**

```
git add lib/features/stats/application/stats_controller.dart
git rm test/features/stats/application/stats_controller_test.dart 2>/dev/null || true
git commit -m "feat(stats): rewrite controller around StatsFilter + buckets"
```

---

## Task 9: ARB keys (en + zh)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Add keys to en.**

Insert before existing `"statsTrendTitle"` block (replace `statsTrendTitle` value to "Trend" — old "Daily Expense" no longer accurate). Add:

```json
"statsFilterCurrency": "Currency",
"statsFilterSource": "Source",
"statsFilterAllSources": "All sources",
"statsPeriodWeek": "Week",
"statsPeriodMonth": "Month",
"statsPeriodYear": "Year",
"statsTrendTitle": "Trend",
"statsDistCategoryTitle": "Category Distribution",
"statsDistTagTitle": "Tag Distribution",
"statsTypeExpense": "Expense",
"statsTypeIncome": "Income",
"statsDistCenterExpense": "EXPENSE",
"statsDistCenterIncome": "INCOME",
"statsTopByCategory": "Category",
"statsTopByTag": "Tag",
"statsTopCountLabel": "Count: {count}",
"@statsTopCountLabel": { "placeholders": { "count": { "type": "int" } } },
"statsUntagged": "Untagged",
"statsTopMoreLink": "+ {n} more · View all in Tag Distribution →",
"@statsTopMoreLink": { "placeholders": { "n": { "type": "int" } } },
"statsTopMultiTagNote": "* A transaction may belong to multiple tags, so totals may exceed the actual sum.",
"statsNoData": "No data",
"statsNoTaggedData": "No tagged transactions",
"statsLoading": "Loading…",
"statsError": "Failed to load",
```

Remove obsolete keys that no longer have call-sites after Task 15: `statsEmpty`, `statsCurrencyHint`, `statsByCategory`, `statsByTag`, `statsNoTags`, `statsTopByAmount`, `statsTopByCount`, `statsCountUnit`. Keep `statsTopTitle` (re-purposed as "Top"). Update its value:

```json
"statsTopTitle": "Top",
```

- [ ] **Step 2: Mirror in zh.**

```json
"statsFilterCurrency": "货币",
"statsFilterSource": "来源",
"statsFilterAllSources": "全部来源",
"statsPeriodWeek": "周",
"statsPeriodMonth": "月",
"statsPeriodYear": "年",
"statsTrendTitle": "趋势",
"statsDistCategoryTitle": "分类分布",
"statsDistTagTitle": "标签分布",
"statsTypeExpense": "支出",
"statsTypeIncome": "收入",
"statsDistCenterExpense": "支出",
"statsDistCenterIncome": "收入",
"statsTopTitle": "排行",
"statsTopByCategory": "分类",
"statsTopByTag": "标签",
"statsTopCountLabel": "笔数：{count}",
"@statsTopCountLabel": { "placeholders": { "count": { "type": "int" } } },
"statsUntagged": "未打标签",
"statsTopMoreLink": "+ 还有 {n} 条 · 查看「标签分布」→",
"@statsTopMoreLink": { "placeholders": { "n": { "type": "int" } } },
"statsTopMultiTagNote": "* 同一交易可同时属于多个标签，金额合计可能大于实际总和。",
"statsNoData": "暂无数据",
"statsNoTaggedData": "本期无打标签交易",
"statsLoading": "加载中…",
"statsError": "加载失败",
```

Remove the obsolete keys in zh too. Keep the same set.

- [ ] **Step 3: Regenerate localizations + run ARB parity test.**

```
flutter gen-l10n
flutter analyze
flutter test test/l10n/   # ARB parity test exists from Phase 7.1
```

Expected: analyze 0 issues + ARB parity test passes (en/zh keys match exactly).

- [ ] **Step 4: Commit.**

```
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/generated/
git commit -m "feat(l10n): stats overhaul ARB keys (en+zh)"
```

---

## Task 10: Shared widgets — `tag_pill.dart` + `stats_donut.dart`

**Files:**
- Create: `lib/features/stats/presentation/widgets/tag_pill.dart`
- Create: `lib/features/stats/presentation/widgets/stats_donut.dart`

- [ ] **Step 1: `tag_pill.dart`.**

```dart
import 'package:flutter/material.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';

class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.italic = false,
  });
  final String label;
  final Color color;
  final bool compact;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: (compact ? AppTypography.xs : AppTypography.sm).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `stats_donut.dart`.**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

class DonutSlice {
  const DonutSlice({required this.color, required this.value});
  final Color color;
  final double value;
}

class StatsDonut extends StatelessWidget {
  const StatsDonut({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerAmount,
    required this.centerColor,
  });
  final List<DonutSlice> slices;
  final String centerLabel;
  final String centerAmount;
  final Color centerColor;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: 50,
              sections: slices.isEmpty
                  ? [
                      PieChartSectionData(
                        color: c.surfaceVariant,
                        value: 1,
                        radius: 30,
                        showTitle: false,
                      ),
                    ]
                  : [
                      for (final s in slices)
                        PieChartSectionData(
                          color: s.color,
                          value: s.value,
                          radius: 30,
                          showTitle: false,
                        ),
                    ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: AppTypography.xs.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                centerAmount,
                style: AppTypography.sm.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: centerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

> If `context.appColors` has no `surfaceVariant` / `textMuted` tokens, use the closest existing token (check `lib/theme/app_colors.dart`). Don't add new tokens unless strictly needed.

- [ ] **Step 3: Run analyze.**

```
flutter analyze
```

- [ ] **Step 4: Commit.**

```
git add lib/features/stats/presentation/widgets/tag_pill.dart lib/features/stats/presentation/widgets/stats_donut.dart
git commit -m "feat(stats): shared TagPill + StatsDonut widgets"
```

---

## Task 11: `stats_filter_bar.dart`

**Files:**
- Create: `lib/features/stats/presentation/widgets/stats_filter_bar.dart`

- [ ] **Step 1: Implement filter card.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/value_objects/currency.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../sources/application/sources_provider.dart'; // verify path
import '../../application/stats_filter.dart';
import '../../application/stats_filter_provider.dart';

class StatsFilterBar extends ConsumerWidget {
  const StatsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final f = ref.watch(statsFilterProvider);
    final sources = ref.watch(allSourcesProvider).valueOrNull ?? const [];
    final filteredSources =
        sources.where((s) => s.currency == f.currency).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _PillDropdown<String>(
                    value: f.currency,
                    label: l.statsFilterCurrency,
                    items: Currency.all
                        .map((c) =>
                            DropdownMenuItem(value: c.code, child: Text('${c.code} ${c.symbol}')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) ref.read(statsFilterProvider.notifier).setCurrency(v);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: _PillDropdown<String?>(
                    value: f.sourceId,
                    label: l.statsFilterSource,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.statsFilterAllSources)),
                      for (final s in filteredSources)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (v) =>
                        ref.read(statsFilterProvider.notifier).setSourceId(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            SegmentedButton<StatsPeriod>(
              segments: [
                ButtonSegment(value: StatsPeriod.week, label: Text(l.statsPeriodWeek)),
                ButtonSegment(value: StatsPeriod.month, label: Text(l.statsPeriodMonth)),
                ButtonSegment(value: StatsPeriod.year, label: Text(l.statsPeriodYear)),
              ],
              selected: {f.period},
              onSelectionChanged: (s) =>
                  ref.read(statsFilterProvider.notifier).setPeriod(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillDropdown<T> extends StatelessWidget {
  const _PillDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
```

> Verify the sources provider name in `lib/features/sources/application/`. If named differently (e.g. `sourcesStreamProvider`), adjust the import + reference.

- [ ] **Step 2: Run analyze.**

```
flutter analyze
```

If `_PillDropdown` pattern exists in dashboard (Phase 7.1), prefer importing that one and delete the local copy.

- [ ] **Step 3: Commit.**

```
git add lib/features/stats/presentation/widgets/stats_filter_bar.dart
git commit -m "feat(stats): filter bar (currency + source + period segmented)"
```

---

## Task 12: `stats_trend_card.dart`

**Files:**
- Create: `lib/features/stats/presentation/widgets/stats_trend_card.dart`

- [ ] **Step 1: Implement.**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../application/stats_buckets.dart';
import '../../application/stats_controller.dart';
import '../../application/stats_filter.dart';
import '../../application/stats_filter_provider.dart';

class StatsTrendCard extends ConsumerWidget {
  const StatsTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final dataAsync = ref.watch(trendBucketsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart, size: 18, color: c.textPrimary),
              const SizedBox(width: 6),
              Text(l.statsTrendTitle, style: AppTypography.md),
            ]),
            const SizedBox(height: 4),
            _RangeChip(filter: f, locale: locale),
            const SizedBox(height: AppSpacing.x3),
            SizedBox(
              height: 180,
              child: dataAsync.when(
                loading: () => Center(child: Text(l.statsLoading,
                    style: AppTypography.xs.copyWith(color: c.textMuted))),
                error: (e, _) => Center(child: Text(l.statsError,
                    style: AppTypography.xs.copyWith(color: c.danger))),
                data: (rows) => _Bars(
                  rows: rows,
                  selected: f.selectedBucketStart,
                  period: f.period,
                  locale: locale,
                  onTap: (start) =>
                      ref.read(statsFilterProvider.notifier).selectBucket(start),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.filter, required this.locale});
  final StatsFilter filter;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = filter.selectedBucketStart;
    String text;
    switch (filter.period) {
      case StatsPeriod.week:
        final end = DateTime(s.year, s.month, s.day + 6);
        text = '${DateFormat.MMMd(locale).format(s)} – ${DateFormat.MMMd(locale).format(end)}';
        break;
      case StatsPeriod.month:
        text = DateFormat.yMMMM(locale).format(s);
        break;
      case StatsPeriod.year:
        text = DateFormat.y(locale).format(s);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: AppTypography.xs.copyWith(color: c.primary)),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.rows,
    required this.selected,
    required this.period,
    required this.locale,
    required this.onTap,
  });
  final List<TrendBucketValues> rows;
  final DateTime selected;
  final StatsPeriod period;
  final String locale;
  final ValueChanged<DateTime> onTap;

  String _label(DateTime start) {
    switch (period) {
      case StatsPeriod.week:
        return DateFormat.MMMd(locale).format(start);
      case StatsPeriod.month:
        return DateFormat.MMM(locale).format(start);
      case StatsPeriod.year:
        return DateFormat.y(locale).format(start);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final maxY = rows
        .map((r) => r.incomeCents > r.expenseCents ? r.incomeCents : r.expenseCents)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_label(rows[i].bucket.start),
                      style: AppTypography.xs.copyWith(color: c.textMuted)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.transparent),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              final i = response!.spot!.touchedBarGroupIndex;
              onTap(rows[i].bucket.start);
            }
          },
        ),
        barGroups: [
          for (var i = 0; i < rows.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              showingTooltipIndicators:
                  rows[i].bucket.start == selected ? const [0, 1] : const [],
              barRods: [
                BarChartRodData(
                  toY: rows[i].incomeCents.toDouble(),
                  color: c.income,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: rows[i].expenseCents.toDouble(),
                  color: c.expense,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
```

> If `c.primary` / `c.primarySoft` / `c.income` / `c.expense` / `c.danger` don't match existing token names, substitute the actual names from `lib/theme/app_colors.dart`. Don't invent new tokens.

- [ ] **Step 2: Run analyze.**

```
flutter analyze
```

- [ ] **Step 3: Commit.**

```
git add lib/features/stats/presentation/widgets/stats_trend_card.dart
git commit -m "feat(stats): trend card with selectable buckets + range chip"
```

---

## Task 13: `stats_distribution_card.dart`

**Files:**
- Create: `lib/features/stats/presentation/widgets/stats_distribution_card.dart`

- [ ] **Step 1: Implement Category + Tag distribution cards as a generic widget.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../domain/enums/transaction_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../categories/application/categories_provider.dart'; // verify
import '../../../tags/application/tags_provider.dart';                // verify
import '../../application/stats_controller.dart';
import '../../application/stats_filter_provider.dart';
import 'stats_donut.dart';
import 'tag_pill.dart';
import '../stats_navigation.dart'; // navigateToTransactions helper (Task 15)

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SegmentedButton<TransactionType>(
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: TransactionType.expense, label: Text(l.statsTypeExpense)),
        ButtonSegment(value: TransactionType.income, label: Text(l.statsTypeIncome)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class CategoryDistributionCard extends ConsumerStatefulWidget {
  const CategoryDistributionCard({super.key});
  @override
  ConsumerState<CategoryDistributionCard> createState() => _CDState();
}

class _CDState extends ConsumerState<CategoryDistributionCard> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final async = ref.watch(categoryDistributionProvider(_type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    Category? findCat(String id) => cats.cast<Category?>().firstWhere(
        (x) => x?.id == id, orElse: () => null);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.donut_large, size: 18),
              const SizedBox(width: 6),
              Text(l.statsDistCategoryTitle, style: AppTypography.md),
              const Spacer(),
              _TypeToggle(value: _type, onChanged: (v) => setState(() => _type = v)),
            ]),
            const SizedBox(height: AppSpacing.x3),
            async.when(
              loading: () => Center(child: Text(l.statsLoading)),
              error: (_, __) => Center(child: Text(l.statsError)),
              data: (data) {
                final centerColor = _type == TransactionType.expense ? c.expense : c.income;
                final amount = _formatAmount(data.totalCents, f.currency, _type);
                if (data.slices.isEmpty) {
                  return _empty(context, l.statsNoData);
                }
                return Column(
                  children: [
                    StatsDonut(
                      slices: [
                        for (final s in data.slices)
                          DonutSlice(
                            color: _categoryColor(findCat(s.categoryId)),
                            value: s.totalCents.toDouble(),
                          ),
                      ],
                      centerLabel: _type == TransactionType.expense
                          ? l.statsDistCenterExpense
                          : l.statsDistCenterIncome,
                      centerAmount: amount,
                      centerColor: centerColor,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _list(
                      children: [
                        for (final s in data.slices)
                          InkWell(
                            onTap: () => navigateToTransactions(context, ref,
                                categoryId: s.categoryId),
                            child: _categoryRow(context, findCat(s.categoryId),
                                s.totalCents, f.currency, _type),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TagDistributionCard extends ConsumerStatefulWidget {
  const TagDistributionCard({super.key, required this.cardKey});
  final GlobalKey cardKey;
  @override
  ConsumerState<TagDistributionCard> createState() => _TDState();
}

class _TDState extends ConsumerState<TagDistributionCard> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    final async = ref.watch(tagDistributionProvider(_type));
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];
    Tag? findTag(String id) => tags.cast<Tag?>().firstWhere((x) => x?.id == id, orElse: () => null);

    return Card(
      key: widget.cardKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.label_outline, size: 18),
              const SizedBox(width: 6),
              Text(l.statsDistTagTitle, style: AppTypography.md),
              const Spacer(),
              _TypeToggle(value: _type, onChanged: (v) => setState(() => _type = v)),
            ]),
            const SizedBox(height: AppSpacing.x3),
            async.when(
              loading: () => Center(child: Text(l.statsLoading)),
              error: (_, __) => Center(child: Text(l.statsError)),
              data: (data) {
                if (data.slices.isEmpty && data.untaggedCents == 0) {
                  return _empty(context, l.statsNoTaggedData);
                }
                final centerColor = _type == TransactionType.expense ? c.expense : c.income;
                final amount = _formatAmount(data.totalCents, f.currency, _type);
                return Column(children: [
                  StatsDonut(
                    slices: [
                      for (final s in data.slices)
                        DonutSlice(
                          color: _tagColor(findTag(s.tagId)),
                          value: s.totalCents.toDouble(),
                        ),
                    ],
                    centerLabel: _type == TransactionType.expense
                        ? l.statsDistCenterExpense
                        : l.statsDistCenterIncome,
                    centerAmount: amount,
                    centerColor: centerColor,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _list(children: [
                    for (final s in data.slices)
                      InkWell(
                        onTap: () => navigateToTransactions(context, ref, tagId: s.tagId),
                        child: _tagRow(context, findTag(s.tagId), s.totalCents, f.currency, _type),
                      ),
                  ]),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// helpers used by both cards
Widget _empty(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: AppTypography.sm.copyWith(color: context.appColors.textMuted)),
      ),
    );

Widget _list({required List<Widget> children}) {
  if (children.length <= 10) return Column(children: children);
  return ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 400),
    child: ListView(shrinkWrap: true, children: children),
  );
}

Widget _categoryRow(BuildContext context, Category? cat, int cents, String currency, TransactionType type) {
  final c = context.appColors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: _categoryColor(cat), shape: BoxShape.circle),
        child: const Icon(Icons.circle, size: 0), // replace with icon registry lookup
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(cat?.displayName ?? '—', overflow: TextOverflow.ellipsis)),
      Text(_formatAmount(cents, currency, type),
          style: AppTypography.sm.copyWith(
            fontFamily: 'monospace',
            color: type == TransactionType.expense ? c.expense : c.income,
          )),
    ]),
  );
}

Widget _tagRow(BuildContext context, Tag? tag, int cents, String currency, TransactionType type) {
  final c = context.appColors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      TagPill(label: tag?.name ?? '—', color: _tagColor(tag), compact: true),
      const Spacer(),
      Text(_formatAmount(cents, currency, type),
          style: AppTypography.sm.copyWith(
            fontFamily: 'monospace',
            color: type == TransactionType.expense ? c.expense : c.income,
          )),
    ]),
  );
}

Color _categoryColor(Category? c) =>
    c == null ? const Color(0xFF999999) : Color(c.color);
Color _tagColor(Tag? t) =>
    t == null ? const Color(0xFF999999) : Color(t.color);

String _formatAmount(int cents, String currency, TransactionType type) {
  final abs = (cents.abs() / 100).toStringAsFixed(2);
  // Reuse currencySymbol helper if it exists; else inline:
  final sym = _symbolFor(currency);
  return type == TransactionType.expense ? '-$sym$abs' : '$sym$abs';
}

String _symbolFor(String code) {
  // TODO: reuse Currency.byCode(code)?.symbol ?? '$code '
  return code;
}
```

> Real `_symbolFor` should look up `Currency.all` by code (see `lib/domain/value_objects/currency.dart`). The displayed name for a `Category` likely needs `default_name_resolver.dart` (used in the old stats page); reuse it. Icon for category row: use `iconFor(cat.icon)` from `lib/shared/icons/icon_registry.dart`.

> The `_categoryRow` icon placeholder must be replaced with the real icon registry lookup before completing this task.

- [ ] **Step 2: Replace placeholders with real helpers.**

- Replace `_symbolFor` body with `Currency.all.firstWhere((c) => c.code == code, orElse: () => null)?.symbol ?? '$code '`.
- Replace the icon `Container` child with `Icon(iconFor(cat?.icon ?? 'tag'), size: 16, color: Colors.white)` (or whatever lucide_icons exports).
- Replace `cat?.displayName` with the resolver pattern used in `stats_page.dart` for `nameKey` → ARB.

- [ ] **Step 3: Run analyze.**

```
flutter analyze
```

- [ ] **Step 4: Commit.**

```
git add lib/features/stats/presentation/widgets/stats_distribution_card.dart
git commit -m "feat(stats): distribution cards (category + tag) with donut + list"
```

---

## Task 14: `stats_top_card.dart`

**Files:**
- Create: `lib/features/stats/presentation/widgets/stats_top_card.dart`

- [ ] **Step 1: Implement.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../domain/enums/transaction_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../categories/application/categories_provider.dart';
import '../../../tags/application/tags_provider.dart';
import '../../application/stats_controller.dart';
import '../../application/stats_filter_provider.dart';
import '../../application/stats_top_aggregator.dart';
import '../stats_navigation.dart';
import 'tag_pill.dart';

enum TopMode { category, tag }

class StatsTopCard extends ConsumerStatefulWidget {
  const StatsTopCard({super.key, required this.onJumpToTagDist});
  final VoidCallback onJumpToTagDist;
  @override
  ConsumerState<StatsTopCard> createState() => _Top();
}

class _Top extends ConsumerState<StatsTopCard> {
  TopMode _mode = TopMode.category;
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final f = ref.watch(statsFilterProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.emoji_events_outlined, size: 18),
            const SizedBox(width: 6),
            Text(l.statsTopTitle, style: AppTypography.md),
            const Spacer(),
            _TabBtn(label: l.statsTopByCategory, active: _mode == TopMode.category,
                onTap: () => setState(() => _mode = TopMode.category)),
            const SizedBox(width: 12),
            _TabBtn(label: l.statsTopByTag, active: _mode == TopMode.tag,
                onTap: () => setState(() => _mode = TopMode.tag)),
            const SizedBox(width: 12),
            SegmentedButton<TransactionType>(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: TransactionType.expense, label: Text(l.statsTypeExpense)),
                ButtonSegment(value: TransactionType.income, label: Text(l.statsTypeIncome)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ]),
          const SizedBox(height: AppSpacing.x3),
          if (_mode == TopMode.category)
            _ByCategoryBody(type: _type, currency: f.currency)
          else
            _ByTagBody(type: _type, currency: f.currency, onJumpToTagDist: widget.onJumpToTagDist),
        ]),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(label,
            style: AppTypography.sm.copyWith(
                color: active ? c.primary : c.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _ByCategoryBody extends ConsumerWidget {
  const _ByCategoryBody({required this.type, required this.currency});
  final TransactionType type;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(topByCategoryProvider(type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];
    Category? findCat(String id) => cats.cast<Category?>().firstWhere((x) => x?.id == id, orElse: () => null);
    Tag? findTag(String id) => tags.cast<Tag?>().firstWhere((x) => x?.id == id, orElse: () => null);

    return async.when(
      loading: () => Center(child: Text(l.statsLoading)),
      error: (_, __) => Center(child: Text(l.statsError)),
      data: (rows) {
        if (rows.isEmpty) return _empty(context, l.statsNoData);
        return Column(
          children: [
            for (final row in rows)
              InkWell(
                onTap: () => navigateToTransactions(context, ref, categoryId: row.categoryId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Color(findCat(row.categoryId)?.color ?? 0xFF999999),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(findCat(row.categoryId)?.name ?? '—',
                            overflow: TextOverflow.ellipsis)),
                        Text(_formatAmount(row.totalCents, currency, type),
                            style: AppTypography.md.copyWith(
                                fontFamily: 'monospace',
                                color: type == TransactionType.expense ? c.expense : c.income)),
                      ]),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: _tagPills(row.tagFrequencies, findTag),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 36, top: 4),
                        child: Text(l.statsTopCountLabel(row.count),
                            style: AppTypography.xs.copyWith(color: c.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tagPills(Map<String, int> freq, Tag? Function(String) findTag) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final extra = sorted.length - top.length;
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: [
        for (final e in top)
          TagPill(
            label: findTag(e.key)?.name ?? '—',
            color: Color(findTag(e.key)?.color ?? 0xFF999999),
            compact: true,
          ),
        if (extra > 0)
          TagPill(label: '+$extra', color: const Color(0xFFBBBBBB), compact: true),
      ],
    );
  }
}

class _ByTagBody extends ConsumerWidget {
  const _ByTagBody({required this.type, required this.currency, required this.onJumpToTagDist});
  final TransactionType type;
  final String currency;
  final VoidCallback onJumpToTagDist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(topByTagProvider(type));
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const [];
    Category? findCat(String id) => cats.cast<Category?>().firstWhere((x) => x?.id == id, orElse: () => null);
    Tag? findTag(String id) => tags.cast<Tag?>().firstWhere((x) => x?.id == id, orElse: () => null);

    return async.when(
      loading: () => Center(child: Text(l.statsLoading)),
      error: (_, __) => Center(child: Text(l.statsError)),
      data: (agg) {
        if (agg.rows.isEmpty && agg.untagged == null) {
          return _empty(context, l.statsNoTaggedData);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final row in agg.rows)
            InkWell(
              onTap: () => navigateToTransactions(context, ref, tagId: row.tagId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    TagPill(label: findTag(row.tagId)?.name ?? '—',
                        color: Color(findTag(row.tagId)?.color ?? 0xFF999999)),
                    const Spacer(),
                    Text(_formatAmount(row.totalCents, currency, type),
                        style: AppTypography.md.copyWith(
                            fontFamily: 'monospace',
                            color: type == TransactionType.expense ? c.expense : c.income)),
                  ]),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Wrap(
                      spacing: 8, runSpacing: 4,
                      children: [
                        for (final tc in row.topCategories)
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(findCat(tc.categoryId)?.color ?? 0xFFCCCCCC).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(findCat(tc.categoryId)?.name ?? '—',
                                  style: AppTypography.xs),
                            ),
                            Text(_formatAmount(tc.totalCents, currency, type),
                                style: AppTypography.xs.copyWith(
                                    fontFamily: 'monospace', color: c.textMuted)),
                          ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(l.statsTopCountLabel(row.count),
                        style: AppTypography.xs.copyWith(color: c.textMuted)),
                  ),
                ]),
              ),
            ),
          if (agg.untagged != null)
            InkWell(
              onTap: () => navigateToTransactions(context, ref, untagged: true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  TagPill(label: l.statsUntagged, color: const Color(0xFFAAAAAA), italic: true),
                  const Spacer(),
                  Text(_formatAmount(agg.untagged!.totalCents, currency, type),
                      style: AppTypography.md.copyWith(
                          fontFamily: 'monospace',
                          color: type == TransactionType.expense ? c.expense : c.income)),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.statsTopMultiTagNote,
                style: AppTypography.xs.copyWith(
                    fontStyle: FontStyle.italic, color: c.textMuted)),
          ),
        ]);
      },
    );
  }
}

Widget _empty(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text, style: AppTypography.sm.copyWith(color: context.appColors.textMuted))),
    );

String _formatAmount(int cents, String currency, TransactionType type) {
  final abs = (cents.abs() / 100).toStringAsFixed(2);
  // reuse a shared helper if one is created during this task
  return (type == TransactionType.expense ? '-' : '') + currency + ' ' + abs;
}
```

> Replace `_formatAmount` with the shared helper (extract during Task 13 or here — agree on one location like `lib/features/stats/presentation/stats_format.dart`).

> The "+N more · View all in Tag Distribution" footer link from the spec: implement at the end of `_ByTagBody` data branch when `agg.rows.length == 10` and there are more tags overall (the limit was 10; check whether full distribution count exceeds it via `tagDistributionProvider`). If too complex, keep just the multi-tag note in this task and skip the link — note in PROGRESS.

- [ ] **Step 2: Run analyze.**

```
flutter analyze
```

- [ ] **Step 3: Commit.**

```
git add lib/features/stats/presentation/widgets/stats_top_card.dart
git commit -m "feat(stats): top card (by category + by tag + untagged)"
```

---

## Task 15: Rewrite `stats_page.dart` + navigation helper

**Files:**
- Create: `lib/features/stats/presentation/stats_navigation.dart`
- Modify: `lib/features/stats/presentation/stats_page.dart` (full rewrite)

- [ ] **Step 1: Create `stats_navigation.dart`.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/stats_buckets.dart';
import '../application/stats_filter.dart';
import '../application/stats_filter_provider.dart';

void navigateToTransactions(
  BuildContext context,
  WidgetRef ref, {
  String? categoryId,
  String? tagId,
  bool untagged = false,
}) {
  final f = ref.read(statsFilterProvider);
  final qp = <String, String>{};
  switch (f.period) {
    case StatsPeriod.month:
      qp['month'] = '${f.selectedBucketStart.year.toString().padLeft(4, '0')}'
          '-${f.selectedBucketStart.month.toString().padLeft(2, '0')}';
      break;
    case StatsPeriod.week:
      final start = f.selectedBucketStart;
      final end = DateTime(start.year, start.month, start.day + 6);
      qp['dateStart'] = isoDate(start);
      qp['dateEnd'] = isoDate(end);
      break;
    case StatsPeriod.year:
      final y = f.selectedBucketStart.year.toString().padLeft(4, '0');
      qp['dateStart'] = '$y-01-01';
      qp['dateEnd'] = '$y-12-31';
      break;
  }
  if (f.sourceId != null) qp['source'] = f.sourceId!;
  if (categoryId != null) qp['category'] = categoryId;
  if (tagId != null) qp['tag'] = tagId;
  if (untagged) qp['untagged'] = '1';
  final uri = Uri(path: '/transactions', queryParameters: qp);
  context.go(uri.toString());
}
```

- [ ] **Step 2: Replace `stats_page.dart`.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_spacing.dart';
import 'widgets/stats_distribution_card.dart';
import 'widgets/stats_filter_bar.dart';
import 'widgets/stats_top_card.dart';
import 'widgets/stats_trend_card.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final _tagDistKey = GlobalKey();

  Future<void> _jumpToTagDist() async {
    final ctx = _tagDistKey.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 300), alignment: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tabStats)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: StatsFilterBar(),
          ),
          const SizedBox(height: AppSpacing.x3),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: StatsTrendCard(),
          ),
          const SizedBox(height: AppSpacing.x3),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: CategoryDistributionCard(),
          ),
          const SizedBox(height: AppSpacing.x3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: TagDistributionCard(cardKey: _tagDistKey),
          ),
          const SizedBox(height: AppSpacing.x3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: StatsTopCard(onJumpToTagDist: _jumpToTagDist),
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: Delete old stats_page widgets (`_TrendCard`, `_CategoryDonutCard`, `_TagDonutCard`, `_TopCategoriesCard`) and unused imports.** They were inline in `stats_page.dart` and are now gone with the rewrite.

- [ ] **Step 4: Run analyze + full test suite + manual app build.**

```
flutter analyze
flutter test
flutter run   # smoke test on a connected device or simulator
```

Expected: 0 issues + all tests green + app launches + Stats tab renders with the 4 sections.

- [ ] **Step 5: Commit.**

```
git add lib/features/stats/presentation/
git commit -m "feat(stats): rewrite page assembly + navigation helper"
```

---

## Task 16: Docs — update `PROGRESS.md`

**Files:**
- Modify: `docs/PROGRESS.md`

- [ ] **Step 1: Update header.**

Change "当前 Step" to `Phase 8 · Stats 视觉重构 ✅`. Update "最近更新" to today.

- [ ] **Step 2: Add Phase 8 section under "Phase 7 — 打磨与上架"** (place it before Phase 7 if Phase 7 is unfinished; otherwise after):

```markdown
## Phase 8 — Stats 视觉重构

- [x] 8.1 StatsFilter + Period / 桶生成纯函数 + 控制器（含 prefs + dominant currency init）
- [x] 8.2 TransactionsFilter 扩展（dateRange / tag / untagged / source）+ router query params
- [x] 8.3 Stats controller 重写（trend / distribution / top providers）
- [x] 8.4 Filter bar + Trend card + Distribution cards + Top card
- [x] 8.5 ARB 中英 keys + 一致性测试通过
- [ ] 实机交互验证（用户自己跑）
```

- [ ] **Step 3: Append decision log row.**

```markdown
| 2026-05-14 | 完成 Phase 8：Stats 视觉重构（Week/Month/Year + 选中桶时间锚点 + 双 Distribution + Top Cat/Tag）  | 新增 ~21 单测；spec 见 docs/superpowers/specs/2026-05-14-stats-page-overhaul-design.md |
```

- [ ] **Step 4: Final verification.**

```
flutter analyze
flutter test
```

Expected: 0 issues + all tests green.

- [ ] **Step 5: Commit.**

```
git add docs/PROGRESS.md
git commit -m "docs: mark Phase 8 stats page overhaul complete"
```

---

## Manual QA checklist (after all tasks complete)

Run in en + zh × light + dark:

1. **Initial load** — Stats tab opens; Trend shows 6 month buckets with current month rightmost; Distribution + Top render with current month data.
2. **Period switch** — Tap Week → 6 weekly buckets ending in current week; tap Year → 3 yearly buckets.
3. **Bucket click** — Tap an earlier month bar → range chip updates + Distribution + Top refresh; Trend itself unchanged.
4. **Context memory** — In Month mode tap Feb → switch to Week → expect 6 weeks ending in last week of Feb. Switch back to Month → still on Feb.
5. **Currency switch** — Change currency dropdown → Source dropdown collapses to that currency's sources; if previously selected source belongs to a different currency, it resets to "All sources".
6. **Tab independence** — Toggle Cat Distribution to Income while Tag Distribution stays on Expense; verify Top's toggle is also independent.
7. **Click-through** — Donut row / Top row / Untagged row → `/transactions` opens with the right query params + filter chip visible.
8. **Empty bucket** — Navigate to a bucket with no data → "No data" placeholders in Distribution and Top; Trend still shows 6 (empty) bars.
9. **+ N more link / multi-tag note** — Visible in By Tag mode at the bottom of Top.

If anything fails, fix and re-commit before declaring Phase 8 done.

---

## Self-review notes

- Spec §1–§10 each have a covering task: §1→Task 4, §2/§3→4–8, §4→5, §5.2→11, §5.3→12, §5.4→13, §5.5→14, §6→2–3+15, §7→9, §8→1/2/5/6/7 + manual.
- TransactionsFilter changes are localised to one file with one extension test group; no other consumers (besides router parse) need updating.
- All provider/method names match across tasks (`statsFilterProvider`, `trendBucketsProvider`, `bucketTransactionsProvider`, `categoryDistributionProvider.family`, `tagDistributionProvider.family`, `topByCategoryProvider.family`, `topByTagProvider.family`, `aggregateTopByCategory`, `aggregateTopByTag`).
- Color/Token names (`c.income`, `c.expense`, `c.primary`, `c.primarySoft`, `c.textMuted`, `c.danger`) are placeholders that may need substitution from the actual `lib/theme/app_colors.dart` — Task 10/12/13/14 each call this out.
- The `+ N more` footer link in Top By Tag is described in §5.5 but reduced to a fallback note in Task 14 — flagged for the implementer to add if total tag count > 10 is detectable cheaply via `tagDistributionProvider`.
